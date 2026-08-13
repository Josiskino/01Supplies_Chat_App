import 'package:flutter/material.dart';

class SectionAppBarTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const SectionAppBarTitle({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final textColor =
        color ?? Theme.of(context).appBarTheme.titleTextStyle?.color;

    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}
