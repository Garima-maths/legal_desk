import 'package:flutter/material.dart';
import 'chapters_screen.dart';

/// Legacy entry point — redirects to ChaptersScreen which is the current
/// production replacement. Not reachable from any active navigation path.
class ActDetailScreen extends StatelessWidget {
  final String actTitle;
  final String actId;

  const ActDetailScreen({
    super.key,
    required this.actTitle,
    required this.actId,
  });

  @override
  Widget build(BuildContext context) {
    return ChaptersScreen(actId: actId, actTitle: actTitle);
  }
}
