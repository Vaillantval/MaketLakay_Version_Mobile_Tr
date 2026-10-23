// Logo animé : la feuille se balance en continu, sauf en animations réduites.
// Intro du premier lancement et marque animée de l'écran Vente du POS.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maketlakay/core/constants/app_constants.dart';
import 'package:maketlakay/core/storage/local_storage.dart';
import 'package:maketlakay/router/app_router.dart';
import 'package:maketlakay/shared/widgets/logo_anime.dart';

import 'design/donnees.dart';
import 'design/harness.dart';

String _lieu(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUpAll(chargerPolices);

  testWidgets('la feuille bouge en continu', (tester) async {
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: LogoAnime(taille: 100))));
    await tester.pump(const Duration(seconds: 10));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('immobile si le téléphone demande moins d\'animations', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: LogoAnime(taille: 100))),
    ));
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('intro du premier lancement', () {
    testWidgets("reste à l'écran le temps de l'animation, puis l'accueil", (tester) async {
      final c = await monterApp(tester,
          chemin: '/splash',
          visiteur: true,
          prefsEnPlus: {AppConstants.keyIntroVue: false});
      expect(_lieu(c), '/splash');
      expect(find.byType(MarqueAnimee), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await laisserCharger(tester);
      expect(_lieu(c), '/acheteur/accueil');
      // Vue une fois pour toutes
      expect(c.read(localStorageProvider).getBool(AppConstants.keyIntroVue), isTrue);
    });

    testWidgets("un toucher passe l'intro", (tester) async {
      final c = await monterApp(tester,
          chemin: '/splash',
          visiteur: true,
          prefsEnPlus: {AppConstants.keyIntroVue: false});
      await tester.tapAt(const Offset(195, 120));
      await laisserCharger(tester);
      expect(_lieu(c), '/acheteur/accueil');
    });
  });

  testWidgets("l'écran Vente du POS porte la marque animée", (tester) async {
    await monterApp(tester, chemin: '/pos/vente', utilisateur: utilisateurCaissier);
    expect(find.byType(MarqueAnimee), findsOneWidget);
    expect(find.text('Vente'), findsWidgets);
    // Toutes les lettres de « Maket Lakay » une fois l'apparition finie
    await tester.pump(const Duration(seconds: 2));
    for (final l in 'MaketLakay'.split('').toSet()) {
      expect(find.text(l), findsWidgets);
    }
  });
}
