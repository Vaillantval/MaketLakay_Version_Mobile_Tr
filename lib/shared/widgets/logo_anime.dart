import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Logo « ML » dessiné en vecteur, avec la feuille qui se balance
/// doucement en continu, comme dans la brise. Immobile si le téléphone
/// demande moins d'animations.
class LogoAnime extends StatefulWidget {
  final double taille;
  final double rayon;
  final BoxBorder? bordure;
  const LogoAnime({this.taille = 34, this.rayon = 10, this.bordure, super.key});

  @override
  State<LogoAnime> createState() => _LogoAnimeState();
}

class _LogoAnimeState extends State<LogoAnime>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800));
  late final _vent = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduit = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduit) {
      _ctrl.stop();
      _ctrl.value = 0.5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MaketLakay',
      image: true,
      child: _Tuile(
        taille: widget.taille,
        rayon: widget.rayon,
        bordure: widget.bordure,
        peintre: _PeintreLogo(vent: _vent),
      ),
    );
  }
}

/// Logo + « Maket Lakay », plus expressif : à l'apparition, le M glisse,
/// le L tombe, la feuille pousse et les lettres du nom montent une à une ;
/// ensuite la feuille se balance plus franchement et un reflet traverse le
/// nom de temps en temps. Toucher le logo rejoue l'apparition.
/// [sombre] : sur fond foncé (« Maket » en blanc).
class MarqueAnimee extends StatefulWidget {
  final double taille;
  final double tailleTexte;
  final bool sombre;
  final String? sousTitre;
  final bool vertical;
  /// Faux : affiché d'emblée (sans apparition), seul le balancement reste
  final bool apparition;
  final VoidCallback? onApparu;
  const MarqueAnimee({
    this.taille = 46,
    this.tailleTexte = 22,
    this.sombre = false,
    this.sousTitre,
    this.vertical = false,
    this.apparition = true,
    this.onApparu,
    super.key,
  });

  @override
  State<MarqueAnimee> createState() => _MarqueAnimeeState();
}

class _MarqueAnimeeState extends State<MarqueAnimee>
    with TickerProviderStateMixin {
  late final _entree = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  late final _ventCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));
  late final _vent =
      CurvedAnimation(parent: _ventCtrl, curve: Curves.easeInOutSine);
  late final _reflet = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200));
  bool _reduit = false;
  bool _demarre = false;

  @override
  void initState() {
    super.initState();
    _entree.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onApparu?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduit = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduit) {
      _entree.value = 1;
      _ventCtrl
        ..stop()
        ..value = 0.5;
      _reflet.stop();
      if (!_demarre) {
        _demarre = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onApparu?.call();
        });
      }
    } else if (!_demarre) {
      _demarre = true;
      if (widget.apparition) {
        _entree.forward(from: 0);
      } else {
        _entree.value = 1;
      }
      _ventCtrl.repeat(reverse: true);
      _reflet.repeat();
    }
  }

  void _rejouer() {
    if (_reduit) return;
    _entree.forward(from: 0);
  }

  @override
  void dispose() {
    _entree.dispose();
    _ventCtrl.dispose();
    _reflet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // La tuile arrive avec un léger rebond
    final tuile = AnimatedBuilder(
      animation: _entree,
      builder: (_, child) {
        final t = Curves.easeOutBack
            .transform(const Interval(0, 0.35).transform(_entree.value));
        return Opacity(
          opacity: const Interval(0, 0.2).transform(_entree.value),
          child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
        );
      },
      child: GestureDetector(
        onTap: _rejouer,
        child: _Tuile(
          taille: widget.taille,
          rayon: widget.taille * 0.3,
          ombre: true,
          peintre: _PeintreLogo(
            vent: _vent,
            entree: _entree,
            amplitude: 6 * math.pi / 180,
            ouvertureMin: 0.88,
          ),
        ),
      ),
    );

    final nom = _NomAnime(
      entree: _entree,
      reflet: _reflet,
      taille: widget.tailleTexte,
      sombre: widget.sombre,
    );

    final sousTitre = widget.sousTitre == null
        ? null
        : FadeTransition(
            opacity: CurvedAnimation(
                parent: _entree, curve: const Interval(0.7, 1)),
            child: Text(widget.sousTitre!,
                style: TextStyle(
                  fontSize: widget.tailleTexte * 0.42,
                  fontStyle: FontStyle.italic,
                  color: widget.sombre
                      ? AppColors.blanc.withValues(alpha: 0.75)
                      : AppColors.grisTexte,
                )),
          );

    return Semantics(
      label: 'MaketLakay',
      child: ExcludeSemantics(
        child: widget.vertical
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                tuile,
                SizedBox(height: widget.taille * 0.22),
                nom,
                if (sousTitre != null) ...[
                  const SizedBox(height: 8),
                  sousTitre,
                ],
              ])
            : Row(mainAxisSize: MainAxisSize.min, children: [
                tuile,
                SizedBox(width: widget.taille * 0.26),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [nom, if (sousTitre != null) sousTitre],
                ),
              ]),
      ),
    );
  }
}

/// « Maket Lakay » : les lettres montent une à une, puis un reflet
/// lumineux traverse le nom à chaque tour de [reflet].
class _NomAnime extends StatelessWidget {
  final Animation<double> entree;
  final Animation<double> reflet;
  final double taille;
  final bool sombre;
  const _NomAnime({
    required this.entree,
    required this.reflet,
    required this.taille,
    required this.sombre,
  });

  static const _mots = ['Maket', 'Lakay'];

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: taille,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    );
    final lettres = <Widget>[];
    final total = _mots.join().length;
    var i = 0;
    for (var m = 0; m < _mots.length; m++) {
      if (m > 0) lettres.add(SizedBox(width: taille * 0.28));
      final couleur = m == 0
          ? (sombre ? AppColors.blanc : AppColors.vertFonce)
          : AppColors.jaune;
      for (final c in _mots[m].split('')) {
        // Décalage de 45 % à 95 % de l'apparition, lettre après lettre
        final debut = 0.45 + 0.4 * i / total;
        final intervalle = Interval(debut, math.min(1, debut + 0.22),
            curve: Curves.easeOutBack);
        lettres.add(AnimatedBuilder(
          animation: entree,
          builder: (_, child) {
            final t = intervalle.transform(entree.value);
            return Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(
                  offset: Offset(0, (1 - t) * taille * 0.7), child: child),
            );
          },
          child: Text(c, style: style.copyWith(color: couleur)),
        ));
        i++;
      }
    }

    return AnimatedBuilder(
      animation: reflet,
      builder: (_, child) {
        // Le reflet passe pendant le premier tiers du tour, puis repos
        final p = (reflet.value / 0.35).clamp(0.0, 1.0);
        if (p <= 0 || p >= 1) return child!;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0x00FFFFFF),
              Color.fromRGBO(255, 255, 255, sombre ? 0.55 : 0.7),
              const Color(0x00FFFFFF),
            ],
            stops: [p - 0.18, p, p + 0.18].map((s) => s.clamp(0.0, 1.0)).toList(),
          ).createShader(r),
          child: child,
        );
      },
      child: Row(mainAxisSize: MainAxisSize.min, children: lettres),
    );
  }
}

class _Tuile extends StatelessWidget {
  final double taille;
  final double rayon;
  final BoxBorder? bordure;
  final bool ombre;
  final CustomPainter peintre;
  const _Tuile({
    required this.taille,
    required this.rayon,
    required this.peintre,
    this.bordure,
    this.ombre = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          color: AppColors.blanc,
          borderRadius: BorderRadius.circular(rayon),
          border: bordure,
          boxShadow: ombre
              ? const [
                  BoxShadow(
                      color: Color(0x1F0B4A24),
                      blurRadius: 14,
                      offset: Offset(0, 5)),
                ]
              : null,
        ),
        child: RepaintBoundary(child: CustomPaint(painter: peintre)),
      );
}

/// Tracé repris du logo (image carrée de 1254 px), mis à l'échelle.
/// [entree] (facultatif, 0 → 1) : le M glisse depuis la gauche, le L
/// tombe d'en haut, puis la feuille pousse depuis son pied.
class _PeintreLogo extends CustomPainter {
  final Animation<double> vent;
  final Animation<double>? entree;
  final double amplitude;
  final double ouvertureMin;
  _PeintreLogo({
    required this.vent,
    this.entree,
    this.amplitude = 3 * math.pi / 180,
    this.ouvertureMin = 0.95,
  }) : super(repaint: entree == null ? vent : Listenable.merge([vent, entree]));

  static const _cote = 1254.0;
  static final _lisere = Paint()
    ..color = AppColors.blanc
    ..style = PaintingStyle.stroke
    ..strokeWidth = 30
    ..strokeJoin = StrokeJoin.round;

  static final _m = Path()
    ..moveTo(221, 258)
    ..lineTo(497, 525)
    ..lineTo(749, 277)
    ..lineTo(749, 403)
    ..lineTo(490, 692)
    ..lineTo(351, 555)
    ..lineTo(351, 893)
    ..lineTo(221, 893)
    ..close();

  static final _l = Path()
    ..moveTo(787, 275)
    ..lineTo(898, 275)
    ..lineTo(898, 757)
    ..lineTo(1087, 757)
    ..lineTo(1087, 893)
    ..lineTo(677, 893)
    ..cubicTo(760, 810, 787, 740, 787, 640)
    ..close();

  // Feuille fendue par sa nervure
  static final _feuille = Path()
    ..moveTo(747, 463)
    ..cubicTo(640, 570, 560, 660, 572, 760)
    ..cubicTo(578, 810, 592, 835, 607, 855)
    ..cubicTo(600, 760, 630, 680, 692, 600)
    ..cubicTo(660, 680, 630, 780, 632, 885)
    ..cubicTo(700, 820, 747, 760, 747, 640)
    ..close();

  // Pied de la feuille : point de rotation
  static const _pied = Offset(620, 880);

  static double _phase(double t, double debut, double fin, Curve courbe) =>
      courbe.transform(Interval(debut, fin).transform(t));

  @override
  void paint(Canvas canvas, Size size) {
    final t = entree?.value ?? 1;
    final pm = _phase(t, 0.08, 0.42, Curves.easeOutCubic);
    final pl = _phase(t, 0.18, 0.52, Curves.easeOutBack);
    final pf = _phase(t, 0.4, 0.85, Curves.elasticOut);

    final e = size.shortestSide / _cote;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - _cote * e) / 2, (size.height - _cote * e) / 2);
    canvas.scale(e);

    if (pf > 0) {
      canvas.save();
      canvas.translate(_pied.dx, _pied.dy);
      // Penchée vers le L, elle s'ouvre ; vers le M, elle se replie un peu
      canvas.rotate((vent.value - 0.5) * 2 * amplitude);
      final ouverture =
          (ouvertureMin + (1 - ouvertureMin) * vent.value) * pf;
      canvas.scale(ouverture, ouverture);
      canvas.translate(-_pied.dx, -_pied.dy);
      canvas.drawPath(_feuille, Paint()..color = AppColors.vertFonce);
      canvas.restore();
    }

    // Les lettres par-dessus, cernées de blanc : la feuille ne les touche
    // jamais, même penchée
    if (pm > 0) {
      canvas.save();
      canvas.translate((pm - 1) * 700, 0);
      canvas.drawPath(_m, _lisere);
      canvas.drawPath(_m,
          Paint()..color = AppColors.vertFonce.withValues(alpha: pm.clamp(0, 1)));
      canvas.restore();
    }
    if (pl > 0) {
      canvas.save();
      canvas.translate(0, (pl - 1) * 900);
      canvas.drawPath(_l, _lisere);
      canvas.drawPath(_l,
          Paint()..color = AppColors.jaune.withValues(alpha: pl.clamp(0, 1)));
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreLogo old) =>
      old.vent != vent || old.entree != entree || old.amplitude != amplitude;
}
