// ═══════════════════════════════════════════════════════════
//  MOTO LOGG — main.dart  (updated for auth)
//  Changes vs original:
//    • FirestoreService now accepts a uid → per-user collection
//      path: users/{uid}/expenses
//    • AuthWrapper listens to FirebaseAuth.authStateChanges()
//      and shows LoginScreen or the main app automatically
//    • Settings screen has a real Sign Out button
// ═══════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'expanse_provider.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

// ──────────────────────────────────────────────────────────
// MAIN
// ──────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
    ),
  );

  runApp(const MotoLedgerApp());
}

// ──────────────────────────────────────────────────────────
// THEME CONSTANTS
// ──────────────────────────────────────────────────────────

const _bg            = Color(0xFF0D0D0D);
const _cardBg        = Color(0xFF1A1A1A);
const _iconBg        = Color(0xFF222222);
const _textPrimary   = Colors.white;
const _textSecondary = Color(0xFFAAAAAA);
const _textDim       = Color(0xFF666666);
const _border        = Color(0xFF2A2A2A);

// ──────────────────────────────────────────────────────────
// MODELS
// ──────────────────────────────────────────────────────────

enum ExpenseCategory { fuel, service, maintenance, modifications }

extension CatX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.fuel:          return 'Fuel';
      case ExpenseCategory.service:       return 'Service';
      case ExpenseCategory.maintenance:   return 'Maintenance';
      case ExpenseCategory.modifications: return 'Modifications';
    }
  }

  IconData get iconData {
    switch (this) {
      case ExpenseCategory.fuel:          return Icons.local_gas_station_rounded;
      case ExpenseCategory.service:       return Icons.build_circle_rounded;
      case ExpenseCategory.maintenance:   return Icons.settings_rounded;
      case ExpenseCategory.modifications: return Icons.construction_rounded;
    }
  }

  String get firestoreKey => name;
}

class Expense {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? notes;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      category: ExpenseCategory.values.firstWhere(
            (e) => e.firestoreKey == (d['category'] as String),
        orElse: () => ExpenseCategory.fuel,
      ),
      amount: (d['amount'] as num).toDouble(),
      date: (d['date'] as Timestamp).toDate(),
      notes: d['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'category': category.firestoreKey,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}

// ──────────────────────────────────────────────────────────
// FIRESTORE SERVICE  — user-scoped path
// ──────────────────────────────────────────────────────────

class FirestoreService {
  final String uid;
  FirestoreService({required this.uid});

  // Per-user collection: users/{uid}/expenses
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses');

  Stream<List<Expense>> stream() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Expense.fromFirestore).toList());

  Future<void> add(Expense e) => _col.add(e.toMap());
  Future<void> delete(String id) => _col.doc(id).delete();
}

// ──────────────────────────────────────────────────────────
// APP
// ──────────────────────────────────────────────────────────

class MotoLedgerApp extends StatelessWidget {
  const MotoLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOTO LOGG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _textPrimary,
          surface: _cardBg,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// ──────────────────────────────────────────────────────────
// AUTH WRAPPER — listens to auth state, no flicker
// ──────────────────────────────────────────────────────────

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still resolving auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _textDim,
              ),
            ),
          );
        }

        // Not logged in → show Login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Logged in → provide ExpenseProvider scoped to this user
        return ChangeNotifierProvider(
          create: (_) => ExpenseProvider(),
          child: const _Root(),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// ROOT — holds bottom nav
// ──────────────────────────────────────────────────────────

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    const pages = [
      HomeScreen(),
      ExpenseListScreen(),
      ReportsScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: _textPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.miniCenterDocked,
      body: pages[provider.tabIndex],
      bottomNavigationBar: _BottomNav(current: provider.tabIndex),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExpenseProvider>(),
        child: const AddExpenseSheet(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// BOTTOM NAV
// ──────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  const _BottomNav({required this.current});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.receipt_long_rounded, 'Expenses'),
      (Icons.bar_chart_rounded, 'Reports'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == current;
              return GestureDetector(
                onTap: () => context.read<ExpenseProvider>().setTab(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].$1,
                          size: 22,
                          color: active ? _textPrimary : _textDim),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: active ? _textPrimary : _textDim,
                          fontSize: 10,
                          fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      active
                          ? Container(
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: _textPrimary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      )
                          : const SizedBox(height: 2),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// HOME SCREEN
// ──────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch so filter changes trigger rebuild
    final provider = context.watch<ExpenseProvider>();

    return StreamBuilder<List<Expense>>(
      stream: provider.allExpenses,
      builder: (ctx, snap) {
        final all      = snap.data ?? [];
        final filtered = provider.applyFilter(all);
        final totals   = provider.totals(filtered);
        final grand    = provider.grand(filtered);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  _TotalCard(grand: grand),
                  _BikeSection(totals: totals),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// HEADER
// ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Show first part of email as name
    final user  = FirebaseAuth.instance.currentUser;
    final name  = user?.email?.split('@').first ?? 'Rider';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hello, $name ',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text('🤘', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Track your NS 200 expenses',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: _textPrimary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// TOTAL CARD
// ──────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final double grand;
  const _TotalCard({required this.grand});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: _textPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Expenses',
                      style: TextStyle(color: _textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_fmt(grand)}',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // ── Filter pill ──────────────────────────────
            GestureDetector(
              onTap: () => _showFilterSheet(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.filterLabel,
                      style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _FilterSheet(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// FILTER BOTTOM SHEET
// ──────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 2020 + 1, (i) => 2020 + i)
        .reversed
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter by',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // ── Mode selector row ─────────────────────────
          Row(
            children: ['All Time', 'Month', 'Year'].map((mode) {
              final active = provider.filterMode == mode;
              return GestureDetector(
                onTap: () {
                  provider.setFilterMode(mode);
                  if (mode == 'All Time') Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? _textPrimary : _iconBg,
                    borderRadius: BorderRadius.circular(24),
                    border:
                    Border.all(color: active ? _textPrimary : _border),
                  ),
                  child: Text(
                    mode,
                    style: TextStyle(
                      color: active ? Colors.black : _textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // ── Month chips ───────────────────────────────
          if (provider.filterMode == 'Month') ...[
            const SizedBox(height: 20),
            const Text('Month',
                style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (i) {
                final m = i + 1;
                final sel = provider.selectedMonth == m;
                return GestureDetector(
                  onTap: () {
                    provider.setSelectedMonth(m);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _textPrimary : _iconBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _textPrimary : _border,
                          width: 0.8),
                    ),
                    child: Text(
                      _months[i],
                      style: TextStyle(
                        color: sel ? Colors.black : _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Year sub-selector when in Month mode
            const Text('Year',
                style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: years.map((y) {
                final sel = provider.selectedYear == y;
                return GestureDetector(
                  onTap: () => provider.setSelectedYear(y),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _textPrimary : _iconBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _textPrimary : _border,
                          width: 0.8),
                    ),
                    child: Text(
                      '$y',
                      style: TextStyle(
                        color: sel ? Colors.black : _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ── Year chips ────────────────────────────────
          if (provider.filterMode == 'Year') ...[
            const SizedBox(height: 20),
            const Text('Year',
                style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: years.map((y) {
                final sel = provider.selectedYear == y;
                return GestureDetector(
                  onTap: () {
                    provider.setSelectedYear(y);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _textPrimary : _iconBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _textPrimary : _border,
                          width: 0.8),
                    ),
                    child: Text(
                      '$y',
                      style: TextStyle(
                        color: sel ? Colors.black : _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// BIKE SECTION  (unchanged layout)
// ──────────────────────────────────────────────────────────

class _BikeSection extends StatelessWidget {
  final Map<ExpenseCategory, double> totals;
  const _BikeSection({required this.totals});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;

      const containerH = 540.0;
      const bikeTop    = 110.0;
      const bikeH      = 270.0;
      const cardW      = 138.0;
      const cardH      = 72.0;
      const iconR      = 26.0;

      const modCardL  = 10.0;
      const modCardT  = 60.0;
      const modIconCx = modCardL + cardW / 2;
      const modIconCy = modCardT - iconR - 6;

      final fuelCardL  = w - cardW - 10;
      const fuelCardT  = 60.0;
      final fuelIconCx = fuelCardL + cardW / 2;
      const fuelIconCy = fuelCardT - iconR - 6;

      const maintCardL  = 10.0;
      const maintCardT  = bikeTop + bikeH + 56;
      const maintIconCx = maintCardL + cardW / 2;
      const maintIconCy = bikeTop + bikeH + 16;

      final serviceCardL  = w - cardW - 10;
      const serviceCardT  = bikeTop + bikeH + 56;
      final serviceIconCx = serviceCardL + cardW / 2;
      const serviceIconCy = bikeTop + bikeH + 16;

      final modCardCenter     = Offset(modCardL     + cardW / 2, modCardT     + cardH / 2);
      final fuelCardCenter    = Offset(fuelCardL    + cardW / 2, fuelCardT    + cardH / 2);
      final maintCardCenter   = Offset(maintCardL   + cardW / 2, maintCardT   + cardH / 2);
      final serviceCardCenter = Offset(serviceCardL + cardW / 2, serviceCardT + cardH / 2);

      final modBikePt     = Offset(w * 0.36, bikeTop + bikeH * 0.28);
      final fuelBikePt    = Offset(w * 0.50, bikeTop + bikeH * 0.20);
      final maintBikePt   = Offset(w * 0.34, bikeTop + bikeH * 0.55);
      final serviceBikePt = Offset(w * 0.49, bikeTop + bikeH * 0.72);

      return SizedBox(
        height: containerH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: bikeTop, left: 0, right: 0, height: bikeH,
              child: Image.asset(
                'asset/ns.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    CustomPaint(painter: FallbackBikePainter()),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CurvedArrowsPainter(arrows: [
                  _ArrowData(modCardCenter,     modBikePt,     curveDir: -2),
                  _ArrowData(fuelCardCenter,    fuelBikePt,    curveDir:  2),
                  _ArrowData(maintCardCenter,   maintBikePt,   curveDir: -1),
                  _ArrowData(serviceCardCenter, serviceBikePt, curveDir: -2),
                ]),
              ),
            ),
            _IconBubble(cx: modIconCx,     cy: modIconCy,     icon: ExpenseCategory.modifications.iconData),
            _CategoryCard(left: modCardL,     top: modCardT,     w: cardW, h: cardH, category: ExpenseCategory.modifications, amount: totals[ExpenseCategory.modifications] ?? 0),
            _IconBubble(cx: fuelIconCx,    cy: fuelIconCy,    icon: ExpenseCategory.fuel.iconData),
            _CategoryCard(left: fuelCardL,    top: fuelCardT,    w: cardW, h: cardH, category: ExpenseCategory.fuel,          amount: totals[ExpenseCategory.fuel]          ?? 0),
            _IconBubble(cx: maintIconCx,   cy: maintIconCy,   icon: ExpenseCategory.maintenance.iconData),
            _CategoryCard(left: maintCardL,   top: maintCardT,   w: cardW, h: cardH, category: ExpenseCategory.maintenance,   amount: totals[ExpenseCategory.maintenance]   ?? 0),
            _IconBubble(cx: serviceIconCx, cy: serviceIconCy, icon: ExpenseCategory.service.iconData),
            _CategoryCard(left: serviceCardL, top: serviceCardT, w: cardW, h: cardH, category: ExpenseCategory.service,       amount: totals[ExpenseCategory.service]       ?? 0),
          ],
        ),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────
// ICON BUBBLE
// ──────────────────────────────────────────────────────────

class _IconBubble extends StatelessWidget {
  final double cx, cy;
  final IconData icon;
  const _IconBubble({required this.cx, required this.cy, required this.icon});

  @override
  Widget build(BuildContext context) {
    const r = 26.0;
    return Positioned(
      left: cx - r, top: cy - r,
      child: Container(
        width: r * 2, height: r * 2,
        decoration: const BoxDecoration(color: _iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: _textPrimary, size: 20),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// CATEGORY CARD
// ──────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final double left, top, w, h;
  final ExpenseCategory category;
  final double amount;

  const _CategoryCard({
    required this.left, required this.top,
    required this.w,    required this.h,
    required this.category, required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left, top: top,
      child: Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.label,
                style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('₹${_fmt(amount)}',
                style: const TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// CURVED ARROWS PAINTER
// ──────────────────────────────────────────────────────────

class _ArrowData {
  final Offset from, to;
  final double curveDir;
  const _ArrowData(this.from, this.to, {this.curveDir = 1});
}

class _CurvedArrowsPainter extends CustomPainter {
  final List<_ArrowData> arrows;
  const _CurvedArrowsPainter({required this.arrows});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final a in arrows) {
      final from = a.from, to = a.to;
      final mid  = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final perp = Offset(
        -(to.dy - from.dy) * 0.25 * a.curveDir,
        (to.dx - from.dx) * 0.25 * a.curveDir,
      );
      final ctrl = mid + perp;

      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy),
        p,
      );

      final tangent = to - ctrl;
      final angle = math.atan2(tangent.dy, tangent.dx);
      const aLen = 9.0, aAng = 0.45;
      canvas.drawLine(to,
          Offset(to.dx - aLen * math.cos(angle - aAng), to.dy - aLen * math.sin(angle - aAng)), p);
      canvas.drawLine(to,
          Offset(to.dx - aLen * math.cos(angle + aAng), to.dy - aLen * math.sin(angle + aAng)), p);
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowsPainter old) => false;
}

// ──────────────────────────────────────────────────────────
// FALLBACK BIKE PAINTER
// ──────────────────────────────────────────────────────────

class FallbackBikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF606060)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    final w = size.width, h = size.height;

    void wheel(Offset c) {
      final r = w * 0.14;
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, p);
      canvas.drawCircle(c, r * 0.55, p..strokeWidth = 1);
      canvas.drawCircle(c, r * 0.12, p);
      for (int i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(
          c + Offset(math.cos(a) * r * 0.12, math.sin(a) * r * 0.12),
          c + Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55),
          p..strokeWidth = 0.8,
        );
      }
      p.strokeWidth = 2;
    }

    wheel(Offset(w * 0.23, h * 0.76));
    wheel(Offset(w * 0.77, h * 0.76));

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.23, h * 0.60) ..lineTo(w * 0.40, h * 0.32)
        ..lineTo(w * 0.60, h * 0.36) ..lineTo(w * 0.65, h * 0.60)
        ..lineTo(w * 0.23, h * 0.60)
        ..moveTo(w * 0.40, h * 0.32) ..lineTo(w * 0.52, h * 0.24)
        ..lineTo(w * 0.60, h * 0.36)
        ..moveTo(w * 0.60, h * 0.36) ..lineTo(w * 0.77, h * 0.60),
      p,
    );

    final tank = Path()
      ..moveTo(w * 0.40, h * 0.32)
      ..quadraticBezierTo(w * 0.44, h * 0.18, w * 0.58, h * 0.22)
      ..lineTo(w * 0.60, h * 0.36)
      ..lineTo(w * 0.40, h * 0.36)
      ..close();
    canvas.drawPath(tank, fill);
    canvas.drawPath(tank, p);

    final seat = Path()
      ..moveTo(w * 0.26, h * 0.34)
      ..quadraticBezierTo(w * 0.32, h * 0.25, w * 0.42, h * 0.28)
      ..lineTo(w * 0.40, h * 0.36)
      ..quadraticBezierTo(w * 0.30, h * 0.38, w * 0.24, h * 0.42)
      ..close();
    canvas.drawPath(seat, fill);
    canvas.drawPath(seat, p);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.40, h * 0.50, w * 0.20, h * 0.12), const Radius.circular(3)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.40, h * 0.50, w * 0.20, h * 0.12), const Radius.circular(3)),
      p,
    );
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(w * 0.40, h * 0.50 + i * h * 0.04),
        Offset(w * 0.60, h * 0.50 + i * h * 0.04),
        p..strokeWidth = 0.8,
      );
    }
    p.strokeWidth = 2;

    canvas.drawPath(
      Path()..moveTo(w * 0.40, h * 0.59)..quadraticBezierTo(w * 0.30, h * 0.65, w * 0.16, h * 0.60),
      p..strokeWidth = 2.5,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.82, h * 0.34), width: 18, height: 14), fill);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.82, h * 0.34), width: 18, height: 14), p..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ──────────────────────────────────────────────────────────
// ADD EXPENSE BOTTOM SHEET
// ──────────────────────────────────────────────────────────

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});
  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  ExpenseCategory _cat = ExpenseCategory.fuel;
  final _amtCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date  = DateTime.now();
  bool _loading   = false;
  String? _err;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _textPrimary, onPrimary: Colors.black, surface: _cardBg),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amtCtrl.text.trim());
    if (amt == null || amt <= 0) { setState(() => _err = 'Enter a valid amount'); return; }
    setState(() { _loading = true; _err = null; });
    try {
      await context.read<ExpenseProvider>().add(
        category: _cat, amount: amt, date: _date, notes: _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _err = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, inset + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Add Expense',
              style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          const _SheetLabel('CATEGORY'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ExpenseCategory.values.map((c) {
              final sel = c == _cat;
              return GestureDetector(
                onTap: () => setState(() => _cat = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? _textPrimary : _iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? _textPrimary : _border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(c.iconData, size: 14, color: sel ? Colors.black : _textSecondary),
                    const SizedBox(width: 6),
                    Text(c.label,
                        style: TextStyle(color: sel ? Colors.black : _textSecondary,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const _SheetLabel('AMOUNT (₹)'),
          const SizedBox(height: 8),
          _SheetField(controller: _amtCtrl, hint: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 14),
          const _SheetLabel('DATE'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: _textSecondary, size: 16),
                const SizedBox(width: 10),
                Text(
                  '${_date.day.toString().padLeft(2, '0')} / '
                      '${_date.month.toString().padLeft(2, '0')} / '
                      '${_date.year}',
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          const _SheetLabel('NOTES (OPTIONAL)'),
          const SizedBox(height: 8),
          _SheetField(controller: _noteCtrl, hint: 'e.g. Petrol at HP station', maxLines: 2),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(_err!, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              width: double.infinity, height: 54,
              decoration: BoxDecoration(color: _textPrimary, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Save Expense',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: _textDim, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5));
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SheetField({required this.controller, required this.hint,
    this.keyboardType, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textDim),
        filled: true, fillColor: _iconBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF555555), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// EXPENSE LIST SCREEN
// ──────────────────────────────────────────────────────────

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('All Expenses',
                style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: provider.allExpenses,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: _textDim));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: _textDim, fontSize: 12)));
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('No expenses yet.',
                      style: TextStyle(color: _textDim, fontSize: 13)));
                }

                final grouped = <String, List<Expense>>{};
                for (final e in list) {
                  final k = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
                  grouped.putIfAbsent(k, () => []).add(e);
                }
                final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: keys.length,
                  itemBuilder: (_, i) {
                    final k     = keys[i];
                    final items = grouped[k]!;
                    final total = items.fold<double>(0, (s, e) => s + e.amount);
                    final parts = k.split('-');
                    final label = '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            Text('₹${_fmt(total)}', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...items.map((e) => _ExpenseTile(expense: e, onDelete: () => provider.delete(e.id))),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  const _ExpenseTile({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline_rounded, color: _textDim, size: 20),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.8)),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(expense.category.iconData, color: _textPrimary, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.category.label,
                  style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              if (expense.notes != null && expense.notes!.isNotEmpty)
                Text(expense.notes!, style: const TextStyle(color: _textDim, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${_fmt(expense.amount)}',
                style: const TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(
              '${expense.date.day.toString().padLeft(2, '0')}/'
                  '${expense.date.month.toString().padLeft(2, '0')}/'
                  '${expense.date.year}',
              style: const TextStyle(color: _textDim, fontSize: 10),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// REPORTS SCREEN
// ──────────────────────────────────────────────────────────

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    return SafeArea(
      child: StreamBuilder<List<Expense>>(
        stream: provider.allExpenses,
        builder: (ctx, snap) {
          final all    = snap.data ?? [];
          final totals = provider.totals(all);
          final grand  = provider.grand(all);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reports',
                    style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                ...ExpenseCategory.values.map((cat) {
                  final amt = totals[cat] ?? 0;
                  final pct = grand > 0 ? amt / grand : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          Icon(cat.iconData, size: 16, color: _textSecondary),
                          const SizedBox(width: 8),
                          Text(cat.label, style: const TextStyle(color: _textPrimary, fontSize: 13)),
                        ]),
                        Text('₹${_fmt(amt)}',
                            style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct, minHeight: 6,
                          backgroundColor: _iconBg,
                          valueColor: const AlwaysStoppedAnimation(_textPrimary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${(pct * 100).toStringAsFixed(1)}% of total',
                          style: const TextStyle(color: _textDim, fontSize: 10)),
                    ]),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border, width: 0.8)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Grand Total', style: TextStyle(color: _textSecondary, fontSize: 13)),
                    Text('₹${_fmt(grand)}',
                        style: const TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// SETTINGS SCREEN  — with Sign Out
// ──────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
                style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),

            // Logged-in user info card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border, width: 0.8),
              ),
              child: Row(children: [
                Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: _textPrimary, size: 18)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Signed in as', style: TextStyle(color: _textDim, fontSize: 10)),
                    Text(user?.email ?? '—',
                        style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),

            const _SettingsTile(icon: Icons.directions_bike_rounded, title: 'Bike Name', subtitle: 'Bajaj Pulsar NS 200'),
            const _SettingsTile(icon: Icons.notifications_rounded, title: 'Notifications', subtitle: 'Enabled'),
            const _SettingsTile(icon: Icons.delete_sweep_rounded, title: 'Clear All Data', subtitle: 'Permanently remove all expenses'),
            const _SettingsTile(icon: Icons.info_outline_rounded, title: 'About', subtitle: 'MOTO LOGG v1.0.0'),

            const SizedBox(height: 8),

            // Sign Out button
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // AuthWrapper will automatically show LoginScreen
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border, width: 0.8),
                ),
                child: const Row(children: [
                  SizedBox(width: 40, height: 40,
                      child: Icon(Icons.logout_rounded, color: Color(0xFF888888), size: 18)),
                  SizedBox(width: 14),
                  Text('Sign Out',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 0.8)),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _textPrimary, size: 18)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            Text(subtitle, style: const TextStyle(color: _textDim, fontSize: 11)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: _textDim, size: 18),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────────────────

String _fmt(double v) {
  final s = v.toStringAsFixed(0);
  if (s.length > 3) return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  return s;
}