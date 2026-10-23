import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/widgets/logo_anime.dart';

/// Vrai tant que l'intro du tout premier lancement est à l'écran : le
/// router garde alors /splash, au lieu d'en partir dès que l'état de
/// connexion est connu.
final introEnCoursProvider = StateProvider<bool>(
    (ref) => !ref.read(localStorageProvider).getBool(AppConstants.keyIntroVue));

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final bool _intro = ref.read(introEnCoursProvider);
  late final _halo = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  Timer? _fin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduit = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduit && !_halo.isAnimating) _halo.forward();
  }

  // Le nom est apparu : on le laisse lire un instant, puis on entre
  void _apparu() {
    if (!_intro) return;
    _fin ??= Timer(const Duration(milliseconds: 1100), _terminer);
  }

  Future<void> _terminer() async {
    _fin?.cancel();
    if (!mounted || !ref.read(introEnCoursProvider)) return;
    await ref.read(localStorageProvider).setBool(AppConstants.keyIntroVue, true);
    ref.read(introEnCoursProvider.notifier).state = false;
  }

  @override
  void dispose() {
    _fin?.cancel();
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // go_router gère la redirection automatiquement
    return Scaffold(
      backgroundColor: AppColors.vertFonce,
      body: GestureDetector(
        // Toucher l'écran passe l'intro
        behavior: HitTestBehavior.opaque,
        onTap: _intro ? _terminer : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Halo de lumière qui s'ouvre derrière le logo
            AnimatedBuilder(
              animation: _halo,
              builder: (_, __) => CustomPaint(
                painter: _PeintreHalo(
                    Curves.easeOutCubic.transform(_halo.value)),
              ),
            ),
            Center(
              child: MarqueAnimee(
                taille: _intro ? 112 : 100,
                tailleTexte: 36,
                sombre: true,
                vertical: true,
                // Lancements suivants : écran de transit très bref
                apparition: _intro,
                sousTitre: 'Sòti nan jaden, rive lakay ou',
                onApparu: _apparu,
              ),
            ),
            if (_intro)
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: SafeArea(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                        parent: _halo, curve: const Interval(0.6, 1)),
                    child: Text(
                      'Le marché local, livré chez vous',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.2,
                        color: AppColors.blanc.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cercles de lumière concentriques, qui s'élargissent depuis le centre.
class _PeintreHalo extends CustomPainter {
  final double t;
  _PeintreHalo(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final centre = size.center(Offset.zero).translate(0, -30);
    final rayonMax = math.max(size.width, size.height) * 0.75;
    for (var i = 0; i < 3; i++) {
      final r = rayonMax * (0.35 + 0.22 * i) * t;
      canvas.drawCircle(
        centre,
        r,
        Paint()..color = AppColors.blanc.withValues(alpha: 0.05 * (3 - i) / 3 * t),
      );
    }
  }

  @override
  bool shouldRepaint(_PeintreHalo old) => old.t != t;
}
