// Reçu et bon de commande PDF, comptes de dépôt du paiement hors ligne.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maketlakay/core/utils/document_commande.dart';
import 'package:maketlakay/models/commande.dart';
import 'package:maketlakay/shared/widgets/compte_depot.dart';

import 'design/donnees.dart';
import 'design/harness.dart';

Commande _commande({
  String statut = 'en_attente',
  String paiement = 'non_paye',
  String methode = 'cash',
}) =>
    Commande(
      numeroCommande: 'CMD-1',
      total: '1000.00',
      statut: statut,
      statutLabel: statut,
      statutPaiement: paiement,
      methodePaiement: methode,
    );

DioException _erreur(int? code, Object? corps) {
  final options = RequestOptions(path: '/recu/');
  return DioException(
    requestOptions: options,
    response: code == null
        ? null
        : Response(requestOptions: options, statusCode: code, data: corps),
  );
}

const _compte = {
  'id': 1, 'type': 'banque', 'type_label': 'Banque', 'nom': 'Sogebank',
  'numero_compte': '123-456', 'nom_titulaire': 'MaketLakay', 'devise': 'HTG',
  'instructions': 'Indiquez le numéro de commande', 'logo': null,
};

Map<String, dynamic> Function(String) _api(
  Map<String, dynamic> Function(String) base, {
  Map<String, dynamic>? commande,
  List<Map<String, dynamic>> comptes = const [],
}) =>
    (path) {
      if (path == '/api/payments/instructions/') {
        return {'success': true, 'data': comptes};
      }
      if (commande != null && path == '/api/auth/commandes/CMD-1/') {
        return {'success': true, 'data': commande};
      }
      return base(path);
    };

void main() {
  setUpAll(chargerPolices);

  group('document disponible', () {
    test('commande payée : le reçu, quelle que soit la méthode', () {
      expect(DocumentCommande.disponible(_commande(paiement: 'paye', methode: 'moncash')),
          DocumentCommande.recu);
      expect(DocumentCommande.disponible(_commande(paiement: 'paye')),
          DocumentCommande.recu);
    });

    test('non payée en espèces, virement ou hors ligne : le bon de commande', () {
      for (final m in ['cash', 'virement', 'hors_ligne']) {
        expect(DocumentCommande.disponible(_commande(methode: m)),
            DocumentCommande.bonDeCommande);
      }
    });

    test('rien pour une commande annulée ou un paiement en ligne en attente', () {
      expect(DocumentCommande.disponible(_commande(statut: 'annulee')), isNull);
      expect(DocumentCommande.disponible(_commande(methode: 'moncash')), isNull);
    });
  });

  group('téléchargement', () {
    test('nom tiré de Content-Disposition', () {
      expect(
          DocumentCommande.recu.nomFichier(
              'attachment; filename="Recu-REC-2026-000012.pdf"', 'CMD-1'),
          'Recu-REC-2026-000012.pdf');
    });

    test("nom de secours, et jamais de chemin venu de l'en-tête", () {
      expect(DocumentCommande.bonDeCommande.nomFichier(null, 'CMD-1'),
          'BonDeCommande-CMD-1.pdf');
      expect(DocumentCommande.recu.nomFichier('filename="../../x.pdf"', 'CMD-1'),
          'x.pdf');
    });

    test('404 : le champ error du JSON, reçu en octets', () {
      final corps = utf8.encode(jsonEncode(
          {'success': false, 'error': 'Le reçu sera disponible une fois payée.'}));
      expect(DocumentCommande.messageErreur(_erreur(404, corps)),
          'Le reçu sera disponible une fois payée.');
    });

    test('erreur serveur ou réseau : un message lisible', () {
      expect(DocumentCommande.messageErreur(_erreur(500, utf8.encode('<html>'))),
          'Document indisponible pour le moment.');
      expect(DocumentCommande.messageErreur(_erreur(null, null)),
          'Vérifiez votre connexion et réessayez.');
    });
  });

  group('détail de commande', () {
    Map<String, dynamic> detail(Map<String, dynamic> champs) => {
          ...commandes.first,
          'numero_commande': 'CMD-1',
          'total': '1000.00',
          ...champs,
        };

    testWidgets('payée : bouton du reçu, pas de reste à payer', (tester) async {
      await monterApp(tester,
          chemin: '/acheteur/commande/CMD-1',
          utilisateur: utilisateurMembre,
          repondre: _api((p) => reponseFactice(p, utilisateurMembre),
              commande: detail({'montant_wallet_utilise': '200.00'})));
      expect(find.text('Télécharger le reçu (PDF)'), findsOneWidget);
      expect(find.text('Télécharger le bon de commande (PDF)'), findsNothing);
      expect(find.text('Payé par portefeuille'), findsOneWidget);
      expect(find.text('Reste à payer'), findsNothing);
    });

    testWidgets('espèces non payées : bon de commande et reste dû', (tester) async {
      await monterApp(tester,
          chemin: '/acheteur/commande/CMD-1',
          utilisateur: utilisateurMembre,
          repondre: _api((p) => reponseFactice(p, utilisateurMembre),
              commande: detail({
                'statut_paiement': 'non_paye',
                'methode_paiement': 'cash',
                'montant_wallet_utilise': '200.00',
              })));
      await tester.scrollUntilVisible(
          find.text('Télécharger le bon de commande (PDF)'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Télécharger le bon de commande (PDF)'), findsOneWidget);
      expect(find.text('Télécharger le reçu (PDF)'), findsNothing);
      expect(find.text('Reste à payer'), findsOneWidget);
      expect(find.textContaining('800'), findsOneWidget);
    });
  });

  group('paiement hors ligne', () {
    Future<void> ouvrirCheckout(WidgetTester tester, List<Map<String, dynamic>> comptes) async {
      await monterApp(tester,
          chemin: '/acheteur/checkout',
          utilisateur: utilisateurMembre,
          repondre: _api((p) => reponseFactice(p, utilisateurMembre), comptes: comptes));
      await tester.tap(find.text('Hors ligne'));
      await laisserCharger(tester);
    }

    testWidgets('montant, cartes de comptes, puis preuve', (tester) async {
      await ouvrirCheckout(tester, [_compte]);
      expect(find.text('Montant à payer'), findsOneWidget);
      expect(find.byType(CompteDepotCarte), findsOneWidget);
      expect(find.text('123-456'), findsOneWidget);
      expect(find.text('Galerie'), findsOneWidget);
    });

    testWidgets("sans compte configuré : le texte d'explication seul", (tester) async {
      await ouvrirCheckout(tester, const []);
      expect(find.byType(CompteDepotCarte), findsNothing);
      expect(find.textContaining('Effectuez le virement'), findsOneWidget);
    });

    testWidgets('commande refusée sans preuve', (tester) async {
      await ouvrirCheckout(tester, [_compte]);
      final bouton = find.text('Confirmer la commande');
      await tester.scrollUntilVisible(bouton, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(bouton);
      await tester.pump();
      expect(find.text('Joignez la preuve de votre virement ou dépôt'), findsOneWidget);
    });

    testWidgets('« Compte bancaire » reste désactivé, marqué Bientôt', (tester) async {
      await ouvrirCheckout(tester, const []);
      expect(find.text('Compte bancaire (En ligne)'), findsOneWidget);
      expect(find.text('Bientôt'), findsOneWidget);
      final tuile = tester.widget<RadioListTile<String>>(find.ancestor(
          of: find.text('Compte bancaire (En ligne)'),
          matching: find.byType(RadioListTile<String>)));
      expect(tuile.enabled, isFalse);
    });
  });

  testWidgets('recharge : les comptes passent avant les anciens numéros', (tester) async {
    await monterApp(tester,
        chemin: '/acheteur/wallet/recharge',
        utilisateur: utilisateurMembre,
        repondre: (path) {
          if (path == '/api/wallet/') {
            return {
              'success': true,
              'data': {
                'solde': '10.00',
                'is_active': true,
                'depot_hors_ligne': {
                  'moyens': [_compte],
                  'numero_moncash': '3700-0000',
                  'numero_natcash': '',
                },
              },
            };
          }
          return reponseFactice(path, utilisateurMembre);
        });
    await tester.tap(find.text('Hors ligne'));
    await tester.pump(const Duration(seconds: 1));
    await laisserCharger(tester);
    expect(find.byType(CompteDepotCarte), findsOneWidget);
    expect(find.textContaining('3700-0000'), findsNothing);
  });
}
