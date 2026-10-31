// Espace entreprise : chaque navigation du code mène à une route, et les
// parcours commande et produit vont jusqu'au bout.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maketlakay/features/producteur/screens/produit_form_screen.dart';
import 'package:maketlakay/router/app_router.dart';

import 'design/donnees.dart';
import 'design/harness.dart';

Map<String, dynamic> _commande(String statut, List<String> actions) => {
      ...commandes.first,
      'numero_commande': 'CMD-1',
      'statut': statut,
      'acheteur_nom': 'Sophie Étienne',
      'paiement_label': 'Payé',
      'methode_paiement_label': 'MonCash',
      'actions_possibles': actions,
      'details': [
        {'produit': 'Carotte', 'quantite': 2, 'unite_vente': 'kg', 'sous_total': '120.00'},
      ],
    };

Map<String, dynamic> Function(String) _api(Map<String, dynamic> commande) => (path) {
      if (path == '/api/auth/producteur/commandes/CMD-1/') {
        return {'success': true, 'data': commande};
      }
      if (path == '/api/products/mes-produits/produit-1/') {
        return {
          'success': true,
          'data': {
            'nom': 'Tomates fraîches', 'description': 'Du jardin', 'prix_unitaire': '125.00',
            'stock_disponible': 40, 'seuil_alerte': 5, 'origine': 'Kenscoff',
            'unite_vente_id': 12, 'categorie': {'id': 1, 'nom': 'Légumes'},
            'image_principale': null,
          },
        };
      }
      if (path == '/api/products/unites-mesure/') {
        return {
          'success': true,
          'data': [
            {'id': 12, 'code': 'kg', 'nom': 'Kilogramme', 'is_active': true, 'ordre': 1},
          ],
        };
      }
      return reponseFactice(path, utilisateurMembre);
    };

void main() {
  setUpAll(chargerPolices);

  testWidgets('toutes les navigations du code ont une route', (tester) async {
    final c = await monterApp(tester,
        chemin: '/producteur/dashboard',
        utilisateur: utilisateurMembre,
        entrepriseActive: 7);
    final config = c.read(routerProvider).configuration;

    final motif = RegExp(r"""\.(?:go|push)\(\s*'(/[^']*)'""");
    final inconnues = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('docs')) continue;
      for (final m in motif.allMatches(f.readAsStringSync())) {
        final chemin = m.group(1)!.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), 'x');
        if (config.findMatch(Uri.parse(chemin)).isError) inconnues.add(chemin);
      }
    }
    expect(inconnues, isEmpty);
  });

  for (final (statut, actions, bouton) in [
    ('en_attente', ['confirmer', 'annuler'], 'Confirmer la commande'),
    ('confirmee', ['preparer', 'annuler'], 'Passer en préparation'),
    ('en_preparation', ['prete', 'annuler'], 'Marquer prête'),
  ]) {
    testWidgets('détail d’une commande $statut : $bouton', (tester) async {
      await monterApp(tester,
          chemin: '/producteur/commande/CMD-1',
          utilisateur: utilisateurMembre,
          entrepriseActive: 7,
          repondre: _api(_commande(statut, actions)));
      expect(find.text('Sophie Étienne'), findsOneWidget);
      await tester.scrollUntilVisible(find.text(bouton), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(bouton), findsOneWidget);
      expect(find.text('Annuler la commande'), findsOneWidget);
      expect(find.text('Carotte'), findsOneWidget);
    });
  }

  testWidgets('commande prête : plus aucune action', (tester) async {
    await monterApp(tester,
        chemin: '/producteur/commande/CMD-1',
        utilisateur: utilisateurMembre,
        entrepriseActive: 7,
        repondre: _api(_commande('prete', const [])));
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('annuler demande un motif, et Retour ne quitte pas l’écran', (tester) async {
    await monterApp(tester,
        chemin: '/producteur/commande/CMD-1',
        utilisateur: utilisateurMembre,
        entrepriseActive: 7,
        repondre: _api(_commande('confirmee', ['preparer', 'annuler'])));
    final annuler = find.text('Annuler la commande');
    await tester.scrollUntilVisible(annuler, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(annuler);
    await laisserCharger(tester);
    expect(find.text('Motif (requis)'), findsOneWidget);
    await tester.tap(find.text('Retour'));
    await laisserCharger(tester);
    expect(find.text('Motif (requis)'), findsNothing);
    expect(find.text('Sophie Étienne'), findsOneWidget);
  });

  testWidgets('nouveau produit : la catégorie est obligatoire', (tester) async {
    await monterApp(tester,
        chemin: '/producteur/produit/nouveau',
        utilisateur: utilisateurMembre,
        entrepriseActive: 7,
        repondre: _api(_commande('prete', const [])));
    expect(find.byType(ProduitFormScreen), findsOneWidget);
    expect(find.text('Catégorie *'), findsOneWidget);
    final creer = find.text('Créer le produit');
    await tester.scrollUntilVisible(creer, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(creer);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Catégorie *'), -300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Requis'), findsWidgets);
  });

  testWidgets('modifier : le formulaire reprend la fiche du produit', (tester) async {
    await monterApp(tester,
        chemin: '/producteur/produit/produit-1/modifier',
        utilisateur: utilisateurMembre,
        entrepriseActive: 7,
        repondre: _api(_commande('prete', const [])));
    expect(find.text('Tomates fraîches'), findsOneWidget);
    expect(find.text('125.00'), findsOneWidget);
    expect(find.text('Légumes'), findsOneWidget);
    expect(find.text('Enregistrer les modifications'), findsOneWidget);
  });
}
