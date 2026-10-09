import 'package:flutter/material.dart';

import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';

/// Placeholder for profile entries that are not built yet
/// (Services Offered, Documents, Change Password).
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    this.icon = Icons.construction_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RoadMateTopBar(),
            RoadMatePageTitle(
              title: title,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: StateMessage(
                icon: icon,
                title: 'Coming soon',
                message: '$title is not available yet. '
                    'We are working on it.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
