import 'package:flutter/material.dart';

/// Wraps a page's [PageHeader] so it collapses out of view when the user
/// scrolls down and reappears when they scroll up. [between] (search fields,
/// banners, action rows) stays pinned and never collapses.
class CollapsingHeaderPage extends StatefulWidget {
  const CollapsingHeaderPage({
    super.key,
    required this.header,
    required this.child,
    this.between,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 24),
    this.betweenSpacing = 16.0,
  });

  final Widget header;
  final Widget? between;
  final Widget child;
  final EdgeInsets padding;
  final double betweenSpacing;

  @override
  State<CollapsingHeaderPage> createState() => _CollapsingHeaderPageState();
}

class _CollapsingHeaderPageState extends State<CollapsingHeaderPage> {
  bool _headerVisible = true;

  bool _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 3 && _headerVisible) {
        setState(() => _headerVisible = false);
      } else if (delta < -3 && !_headerVisible) {
        setState(() => _headerVisible = true);
      }
    }
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels <= 0 &&
        !_headerVisible) {
      setState(() => _headerVisible = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOut,
              firstCurve: const Interval(0, 0.6, curve: Curves.easeIn),
              secondCurve: const Interval(0.4, 1, curve: Curves.easeOut),
              alignment: AlignmentDirectional.topStart,
              crossFadeState: _headerVisible
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: widget.header,
              ),
              secondChild: const SizedBox.shrink(),
            ),
            if (widget.between != null) ...<Widget>[
              widget.between!,
              SizedBox(height: widget.betweenSpacing),
            ],
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
