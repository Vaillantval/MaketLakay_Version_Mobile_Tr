// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commande.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommandeImpl _$$CommandeImplFromJson(Map<String, dynamic> json) =>
    _$CommandeImpl(
      numeroCommande: json['numero_commande'] as String,
      producteur: json['producteur_nom'] as String? ?? '',
      total: json['total'] as String,
      montantWalletUtilise: json['montant_wallet_utilise'] == null
          ? 0
          : jsonToDouble(json['montant_wallet_utilise']),
      statut: json['statut'] as String,
      statutLabel: json['statut_label'] as String,
      statutPaiement: json['statut_paiement'] as String,
      paiementLabel: json['paiement_label'] as String?,
      methodePaiement: json['methode_paiement'] as String? ?? '',
      methodePaiementLabel: json['methode_paiement_label'] as String?,
      modeLivraison: json['mode_livraison'] as String?,
      adresseLivraison: json['adresse_livraison'] as String?,
      notesAcheteur: json['notes_acheteur'] as String?,
      createdAt: json['created_at'] as String?,
      acheteurNom: json['acheteur_nom'] as String?,
      acheteurTel: json['acheteur_tel'] as String?,
      actionsPossibles: (json['actions_possibles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CommandeImplToJson(_$CommandeImpl instance) =>
    <String, dynamic>{
      'numero_commande': instance.numeroCommande,
      'producteur_nom': instance.producteur,
      'total': instance.total,
      'montant_wallet_utilise': instance.montantWalletUtilise,
      'statut': instance.statut,
      'statut_label': instance.statutLabel,
      'statut_paiement': instance.statutPaiement,
      'paiement_label': instance.paiementLabel,
      'methode_paiement': instance.methodePaiement,
      'methode_paiement_label': instance.methodePaiementLabel,
      'mode_livraison': instance.modeLivraison,
      'adresse_livraison': instance.adresseLivraison,
      'notes_acheteur': instance.notesAcheteur,
      'created_at': instance.createdAt,
      'acheteur_nom': instance.acheteurNom,
      'acheteur_tel': instance.acheteurTel,
      'actions_possibles': instance.actionsPossibles,
      'details': instance.details,
    };
