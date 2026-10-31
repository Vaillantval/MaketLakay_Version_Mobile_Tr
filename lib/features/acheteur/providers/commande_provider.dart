import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/image_utils.dart';
import '../../../models/commande.dart';
import '../../../providers/auth_provider.dart';

final commandesProvider =
    StateNotifierProvider<CommandeNotifier, AsyncValue<List<Commande>>>((ref) {
  ref.watch(sessionUtilisateurProvider); // recharger au changement de compte
  return CommandeNotifier(ref.read(apiClientProvider));
});

class CommandeNotifier
    extends StateNotifier<AsyncValue<List<Commande>>> {
  final ApiClient _api;

  CommandeNotifier(this._api) : super(const AsyncValue.loading()) {
    charger();
  }

  Future<void> charger() async {
    state = const AsyncValue.loading();
    try {
      final res  = await _api.get(AppEndpoints.mesCommandes);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((e) => Commande.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(list);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>?> passer({
    required String methodePaiement,
    required String modeLivraison,
    int?    adresseId,
    String  adresseTexte = '',
    String  ville        = '',
    String  departement  = '',
    String  notes        = '',
    XFile?  preuve,
  }) async {
    try {
      final body = <String, dynamic>{
        'methode_paiement': methodePaiement,
        'mode_livraison':   modeLivraison,
        'notes':            notes,
      };
      if (adresseId != null) {
        body['adresse_livraison_id'] = adresseId;
      } else {
        body['adresse_livraison_text'] = adresseTexte;
        body['ville_livraison']        = ville;
        body['departement_livraison']  = departement;
      }

      final res = preuve != null
          ? await _api.postMultipart(
              AppEndpoints.commander,
              FormData.fromMap({
                ...body,
                'preuve_paiement': await MultipartFile.fromFile(
                    preuve.path, filename: nomImageEnvoi(preuve)),
              }),
            )
          : await _api.post(AppEndpoints.commander, data: body);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        await charger(); // Rafraîchir la liste
      }
      return data;
    } catch (e) {
      return {
        'success': false,
        'error': messageErreurApi(e, 'La commande n’a pas pu être envoyée. Réessayez.'),
      };
    }
  }
}

/// Comptes de virement / dépôt pour payer une commande hors ligne
/// (GET /api/payments/instructions/, public). Liste vide : rien de configuré.
final moyensDepotProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final res  = await api.get(AppEndpoints.instructionsPaiement);
    final data = res.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] is List) {
      return List<Map<String, dynamic>>.from(
          (data['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    }
  } catch (_) {}
  return const [];
});

// Détail d'une commande
final commandeDetailProvider =
    FutureProvider.family<Commande?, String>((ref, numero) async {
  ref.watch(sessionUtilisateurProvider); // recharger au changement de compte
  final api = ref.read(apiClientProvider);
  try {
    final res  = await api.get(AppEndpoints.maCommande(numero));
    final data = res.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return Commande.fromJson(data['data'] as Map<String, dynamic>);
    }
  } catch (_) {}
  return null;
});
