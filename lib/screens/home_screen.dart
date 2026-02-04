import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../widgets/glass_style_button.dart';

/// Spinning 3D astronaut model only — no container/widget around it.
class AstronautHero extends StatelessWidget {
  const AstronautHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        child: Align(
          alignment: const Alignment(-0.2, 0),
          child: ModelViewer(
            src: 'assets/astronaut_sapling.glb',
            backgroundColor: Colors.transparent,
            autoRotate: true,
            autoRotateDelay: 0,
            rotationPerSecond: '240deg',
            cameraControls: false,
            disableZoom: true,
            environmentImage: 'neutral',
            exposure: 2.7,
            shadowIntensity: 1.0,
            shadowSoftness: 0.8,
            relatedCss: 'model-viewer { outline: none !important; filter: saturate(0.3); } '
                'body { outline: none !important; }',
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 157, 157, 157),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 185, 185, 185),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Pollution Station',
          style: TextStyle(
            fontFamily: 'Garamond',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 28, right: 28, top: 8, bottom: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to the Station',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Garamond',
                      fontSize: 28,
                      color: Color.fromARGB(255, 197, 201, 187),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GlassStyleButton(
                          onPressed: () => context.go('/connection'),
                          label: 'Connection & indicators',
                          subtitle: 'Connect device and choose indicators',
                          icon: Icons.bluetooth_searching,
                        ),
                      ),
                      const SizedBox(width: 26),
                      Expanded(
                        child: GlassStyleButton(
                          onPressed: () => context.go('/dashboard'),
                          label: 'Dashboard',
                          subtitle: 'View live and historical data',
                          icon: Icons.dashboard,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  const AstronautHero(),
                  const SizedBox(height: 38),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GlassStyleButton(
                          onPressed: () => context.go('/supplements'),
                          label: 'Supplements & reminders',
                          subtitle: 'Manage intake and set notifications',
                          icon: Icons.medication,
                        ),
                      ),
                      const SizedBox(width: 46),
                      Expanded(
                        child: GlassStyleButton(
                          onPressed: () => context.go('/physical-test'),
                          label: 'Physical tests',
                          subtitle: 'Hair, urine, blood testing links',
                          icon: Icons.science,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}