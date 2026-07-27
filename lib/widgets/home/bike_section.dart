import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/bike_provider.dart';
import '../painters/curved_arrows_painter.dart';
import '../painters/fallback_bike_painter.dart';
import 'category_card.dart';
import 'fuel_card.dart';
import 'icon_bubble.dart';

class BikeSection extends StatelessWidget {
  final Map<ExpenseCategory, double> totals;
  const BikeSection({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;

        const containerH = 540.0;
        const bikeTop = 110.0;
        const bikeH = 270.0;
        const cardW = 138.0;
        const cardH = 72.0;
        const iconR = 26.0;

        const modCardL = 10.0;
        const modCardT = 60.0;
        const modIconCx = modCardL + cardW / 2;
        const modIconCy = modCardT - iconR - 6;

        final fuelCardL = w - cardW - 10;
        const fuelCardT = 60.0;
        final fuelIconCx = fuelCardL + cardW / 2;
        const fuelIconCy = fuelCardT - iconR - 6;

        const maintCardL = 10.0;
        const maintCardT = bikeTop + bikeH + 56;
        const maintIconCx = maintCardL + cardW / 2;
        const maintIconCy = bikeTop + bikeH + 16;

        final serviceCardL = w - cardW - 10;
        const serviceCardT = bikeTop + bikeH + 56;
        final serviceIconCx = serviceCardL + cardW / 2;
        const serviceIconCy = bikeTop + bikeH + 16;

        final modCardCenter = Offset(
          modCardL + cardW / 2,
          modCardT + cardH / 2,
        );
        final fuelCardCenter = Offset(
          fuelCardL + cardW / 2,
          fuelCardT + cardH / 2,
        );
        final maintCardCenter = Offset(
          maintCardL + cardW / 2,
          maintCardT + cardH / 2,
        );
        final serviceCardCenter = Offset(
          serviceCardL + cardW / 2,
          serviceCardT + cardH / 2,
        );

        final modBikePt = Offset(w * 0.36, bikeTop + bikeH * 0.28);
        final fuelBikePt = Offset(w * 0.50, bikeTop + bikeH * 0.20);
        final maintBikePt = Offset(w * 0.34, bikeTop + bikeH * 0.55);
        final serviceBikePt = Offset(w * 0.49, bikeTop + bikeH * 0.72);
        final bikeProvider = context.watch<BikeProvider>();

        return SizedBox(
          height: containerH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: bikeTop,
                left: 0,
                right: 0,
                height: bikeH,
                child: Image.asset(
                  bikeProvider.selectedBike?.imageUrl ?? 'asset/ns.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      CustomPaint(painter: FallbackBikePainter()),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: CurvedArrowsPainter(
                    arrows: [
                      ArrowData(modCardCenter, modBikePt, curveDir: -2),
                      ArrowData(fuelCardCenter, fuelBikePt, curveDir: 2),
                      ArrowData(maintCardCenter, maintBikePt, curveDir: -1),
                      ArrowData(
                        serviceCardCenter,
                        serviceBikePt,
                        curveDir: -2,
                      ),
                    ],
                  ),
                ),
              ),
              IconBubble(
                cx: modIconCx,
                cy: modIconCy,
                icon: ExpenseCategory.modifications.iconData,
              ),
              CategoryCard(
                left: modCardL,
                top: modCardT,
                w: cardW,
                h: cardH,
                category: ExpenseCategory.modifications,
                amount: totals[ExpenseCategory.modifications] ?? 0,
              ),
              IconBubble(
                cx: fuelIconCx,
                cy: fuelIconCy,
                icon: ExpenseCategory.fuel.iconData,
              ),
              FuelCard(
                left: fuelCardL,
                top: fuelCardT,
                w: cardW,
                h: cardH,
                category: ExpenseCategory.fuel,
                amount: totals[ExpenseCategory.fuel] ?? 0,
              ),
              IconBubble(
                cx: maintIconCx,
                cy: maintIconCy,
                icon: ExpenseCategory.accessories.iconData,
              ),
              CategoryCard(
                left: maintCardL,
                top: maintCardT,
                w: cardW,
                h: cardH,
                category: ExpenseCategory.accessories,
                amount: totals[ExpenseCategory.accessories] ?? 0,
              ),
              IconBubble(
                cx: serviceIconCx,
                cy: serviceIconCy,
                icon: ExpenseCategory.service.iconData,
              ),
              CategoryCard(
                left: serviceCardL,
                top: serviceCardT,
                w: cardW,
                h: cardH,
                category: ExpenseCategory.service,
                amount: totals[ExpenseCategory.service] ?? 0,
              ),
            ],
          ),
        );
      },
    );
  }
}
