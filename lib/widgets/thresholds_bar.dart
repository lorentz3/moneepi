import 'package:flutter/material.dart';
import 'package:myfinance2/dto/group_summary_dto.dart';
import 'package:myfinance2/utils/color_identity.dart';

class ThresholdBar extends StatefulWidget {
  final double spent;
  final double threshold;
  final String? icon;
  final String name;
  final Color? nameColor;
  final String currencySymbol;
  final bool showTodayBar;
  final List<GroupCategorySummaryDto>? categories;

  const ThresholdBar({super.key, 
    required this.spent, 
    required this.threshold, 
    this.icon, 
    required this.name, 
    this.nameColor, 
    required this.currencySymbol,
    required this.showTodayBar,
    this.categories,
  });
  
  @override
  State<ThresholdBar> createState() => _ThresholdBarState();
}

class _ThresholdBarState extends State<ThresholdBar> {
  final GlobalKey _barKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showTooltip() {
    if (widget.categories == null || widget.categories!.isEmpty) {
      return;
    }
    debugPrint("showing tooltip");
    final renderBox = _barKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + (screenWidth / 10),
        top: offset.dy + size.height + 4, // appena sotto la barra
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            width: screenWidth - (screenWidth / 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.categories?.map((cat) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text('${cat.icon ?? ''} ${cat.name}')),
                    Text('${cat.totalExpense?.toStringAsFixed(2) ?? '0.00'} ${widget.currencySymbol}'),
                  ],
                );
              }).toList() ?? [Text("Nessuna categoria")],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideTooltip() {
    debugPrint("hiding tooltip");
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {

    DateTime now = DateTime.now();
    int currentDay = now.day;
    int totalDays = DateUtils.getDaysInMonth(now.year, now.month);
    double dayProgress = (100 * currentDay / totalDays).clamp(0.0, 100.0);

    double spentPercent = (widget.threshold > 0)
        ? (100 * widget.spent / widget.threshold).clamp(0.0, 999.0)
        : (widget.spent > 0 ? 999.0 : 0.0);

    Color progressColor;
    if (widget.showTodayBar) {
      if (spentPercent < dayProgress) {
        progressColor = Colors.green[300]!;
      } else if (spentPercent <= 100) {
        progressColor = Colors.orange[200]!;
      } else {
        progressColor = Colors.red[300]!;
      }
    } else {
      progressColor = Colors.green[300]!;
    }
    String barTitle = widget.icon != null ? "${widget.icon} ${widget.name}" : widget.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onLongPress: _showTooltip,
        onLongPressUp: _hideTooltip,
        child: Stack(
          key: _barKey, // <- chiave spostata qui
          children: [
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (widget.showTodayBar) FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: dayProgress / 100,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: (100 - spentPercent).clamp(0.0, 100.0) / 100,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(4), left: Radius.circular(4)),
                  ),
                ),
              ),
            ),
            if (widget.showTodayBar) FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: dayProgress / 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 2,
                  height: 20,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        barTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${(widget.threshold - widget.spent).toStringAsFixed(2)} ${widget.currencySymbol}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: spentPercent > 100 ? red() : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 3),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '/${widget.threshold.toStringAsFixed(2)} ${widget.currencySymbol}',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(spentPercent).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: spentPercent > 100 ? red() : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}