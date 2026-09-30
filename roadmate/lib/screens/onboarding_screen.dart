import 'package:flutter/material.dart';
import '../widgets/roadside_illustration.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const navy = Color(0xFF0A2A66);
  static const orange = Color(0xFFFF8A1E);
  static const greyText = Color(0xFF7A8599);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top bar with Skip
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 20),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: greyText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Illustration card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth;
                    // Keep card compact so whole screen fits without scroll on phones
                    final cardHeight = cardWidth > 340 ? 340.0 : cardWidth * 1.02;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A2A66)
                                .withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFEDF1F7),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: cardHeight,
                        width: double.infinity,
                        child: const RoadsideIllustration(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

            // Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Road',
                        style: TextStyle(color: navy),
                      ),
                      TextSpan(
                        text: 'Mate',
                        style: TextStyle(color: orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Help on the road, always with you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2340),
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                '24/7 fast roadside dispatch across the island. Flat tire, towing, or battery jump start in minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: greyText,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 8,
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 6),
                _dot(),
                const SizedBox(width: 6),
                _dot(),
              ],
            ),

            const SizedBox(height: 22),

            // Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Get Started'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Sign in
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 13.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Home indicator
            Container(
              width: 134,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2340),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFD9DEE8),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
