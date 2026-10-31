// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/utils/json_converters.dart';

part 'commande.freezed.dart';
part 'commande.g.dart';

const libellesModeLivraison = {
  'domicile': 'Livraison à domicile',
  'retrait':  'Retrait chez le producteur',
  'collecte': 'Point de collecte',
};

const _libellesPaiement = {
  'non_paye':       'Non payé',
  'preuve_soumise': 'Preuve soumise',
  'verifie':        'Vérifié',
  'paye':           'Payé',
  'rembourse':      'Remboursé',
  'echoue':         'Échoué',
};

/// Libellé de l'état du paiement : celui du serveur s'il le donne.
extension EtatPaiement on Commande {
  String get libellePaiement =>
      paiementLabel ?? _libellesPaiement[statutPaiement] ?? statutPaiement;
}

@freezed
class Commande with _$Commande {
  const factory Commande({
    @JsonKey(name: 'numero_commande')  required String numeroCommande,
    // Le backend expose 'producteur_nom' (pas d'objet 'producteur') sur
    // les listes acheteur/producteur (CommandeProducteurSerializer).
    @JsonKey(name: 'producteur_nom')   @Default('') String producteur,
    required String total,
    // Part déjà réglée par le portefeuille (reste dû = total - cette part)
    @JsonKey(name: 'montant_wallet_utilise', fromJson: jsonToDouble)
    @Default(0) double montantWalletUtilise,
    required String statut,
    @JsonKey(name: 'statut_label')     required String statutLabel,
    @JsonKey(name: 'statut_paiement')  required String statutPaiement,
    @JsonKey(name: 'paiement_label')   String? paiementLabel,
    @JsonKey(name: 'methode_paiement') @Default('') String methodePaiement,
    @JsonKey(name: 'methode_paiement_label') String? methodePaiementLabel,
    @JsonKey(name: 'mode_livraison')   String? modeLivraison,
    @JsonKey(name: 'adresse_livraison') String? adresseLivraison,
    @JsonKey(name: 'notes_acheteur')   String? notesAcheteur,
    @JsonKey(name: 'created_at')       String? createdAt,
    // Vue entreprise (CommandeProducteurSerializer)
    @JsonKey(name: 'acheteur_nom')     String? acheteurNom,
    @JsonKey(name: 'acheteur_tel')     String? acheteurTel,
    @JsonKey(name: 'actions_possibles') @Default([]) List<String> actionsPossibles,
    @Default([]) List<Map<String, dynamic>> details,
  }) = _Commande;

  factory Commande.fromJson(Map<String, dynamic> json) =>
      _$CommandeFromJson(json);
}
