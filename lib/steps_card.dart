import 'package:flutter/material.dart';

import 'steps_progress_icon.dart';

class StepsCard extends StatelessWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Container(
      height: 270,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.35), width: 1.1),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 254, 242, 242),
            Color.fromARGB(255, 254, 191, 191),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double maxW = constraints.maxWidth;
                      double numberFont = 32;
                      double labelFont = 16;
                      if (maxW < 320) {
                        numberFont = 22;
                        labelFont = 12;
                      } else if (maxW < 400) {
                        numberFont = 26;
                        labelFont = 14;
                      } else if (maxW < 500) {
                        numberFont = 28;
                        labelFont = 15;
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "8,450",
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: numberFont,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Steps",
                              style: textTheme.titleSmall?.copyWith(
                                color: Colors.red,
                                fontSize: labelFont,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Out of 10,000",
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Center(child: StepsProgressIcon()),
          ],
        ),
      ),
    );
  }
}
