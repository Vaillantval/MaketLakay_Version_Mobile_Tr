import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/commande.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// PDF d'une commande, téléchargé avec le jeton puis ouvert sur le téléphone.
enum DocumentCommande {
  recu('Télécharger le reçu (PDF)', 'Recu'),
  bonDeCommande('Télécharger le bon de commande (PDF)', 'BonDeCommande');

  final String libelleBouton;
  final String prefixeFichier;
  const DocumentCommande(this.libelleBouton, this.prefixeFichier);

  static const _methodesAvecBon = {'cash', 'virement', 'hors_ligne'};

  /// Le reçu remplace le bon de commande une fois la commande payée.
  static DocumentCommande? disponible(Commande commande) {
    if (commande.statutPaiement == 'paye') return recu;
    if (_methodesAvecBon.contains(commande.methodePaiement) &&
        commande.statut != 'annulee') {
      return bonDeCommande;
    }
    return null;
  }

  String _chemin(String numero) => switch (this) {
        recu          => AppEndpoints.recuCommande(numero),
        bonDeCommande => AppEndpoints.bonDeCommande(numero),
      };

  /// Télécharge et ouvre le PDF ; sans lecteur PDF, propose le partage.
  /// Retourne le message d'erreur à afficher, null si tout s'est bien passé.
  Future<String?> ouvrir(ApiClient api, String numero) async {
    try {
      final res  = await api.telecharger(_chemin(numero));
      final nom  = nomFichier(res.headers.value('content-disposition'), numero);
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$nom');
      await file.writeAsBytes(res.data ?? const [], flush: true);

      final ouvert = await OpenFilex.open(file.path, type: 'application/pdf');
      if (ouvert.type != ResultType.done) {
        await Share.shareXFiles(
            [XFile(file.path, mimeType: 'application/pdf')]);
      }
      return null;
    } on DioException catch (e) {
      return messageErreur(e);
    } catch (_) {
      return "Impossible d'ouvrir le document.";
    }
  }

  /// Nom tiré de Content-Disposition, réduit à un simple nom de fichier.
  String nomFichier(String? contentDisposition, String numero) {
    final trouve = RegExp(r'filename="?([^";]+)"?')
        .firstMatch(contentDisposition ?? '')
        ?.group(1)
        ?.split(RegExp(r'[/\\]'))
        .last
        .trim();
    return trouve == null || trouve.isEmpty
        ? '$prefixeFichier-$numero.pdf'
        : trouve;
  }

  /// Le corps d'une erreur arrive en octets : le champ `error` du JSON s'il
  /// y en a un, sinon un message général.
  static String messageErreur(DioException e) {
    final corps = e.response?.data;
    if (e.response == null) return 'Vérifiez votre connexion et réessayez.';
    if (corps is List<int>) {
      try {
        final json = jsonDecode(utf8.decode(corps));
        if (json is Map && json['error'] != null) return '${json['error']}';
      } catch (_) {}
    }
    return 'Document indisponible pour le moment.';
  }
}
