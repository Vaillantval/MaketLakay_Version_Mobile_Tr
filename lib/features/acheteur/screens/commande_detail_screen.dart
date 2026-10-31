import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/document_commande.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/commande.dart';
import '../../../shared/ui/ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/commande_provider.dart';
import '../widgets/commande_statut_badge.dart';
import '../../../shared/widgets/loading_widget.dart';

class _BoutonDocument extends ConsumerStatefulWidget {
  final Commande commande;
  final DocumentCommande document;
  const _BoutonDocument(this.commande, this.document);

  @override
  ConsumerState<_BoutonDocument> createState() => _BoutonDocumentState();
}

class _BoutonDocumentState extends ConsumerState<_BoutonDocument> {
  bool _enCours = false;

  Future<void> _telecharger() async {
    setState(() => _enCours = true);
    final erreur = await widget.document.ouvrir(
        ref.read(apiClientProvider), widget.commande.numeroCommande);
    if (!mounted) return;
    setState(() => _enCours = false);
    if (erreur != null) afficherMessage(context, erreur, succes: false);
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: _enCours ? null : _telecharger,
        icon: _enCours
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.picture_as_pdf_outlined, size: 20),
        label: Text(widget.document.libelleBouton),
      );
}

class CommandeDetailScreen extends ConsumerWidget {
  final String numero;
  const CommandeDetailScreen({required this.numero, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandeAsync = ref.watch(commandeDetailProvider(numero));

    return Scaffold(
      appBar: AppBar(
        title: Text(numero),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/acheteur/commandes'),
        ),
      ),
      body: commandeAsync.when(
        loading: () => const LoadingWidget(message: 'Chargement…'),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (commande) {
          if (commande == null) {
            return EmptyState(
              icone: Icons.receipt_long_outlined,
              titre: 'Commande introuvable',
              boutonLabel: 'Mes commandes',
              onBouton: () => context.go('/acheteur/commandes'),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              // ── Résumé ──────────────────────────────────────────
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            FormatUtils.date(commande.createdAt ?? ''),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grisTexte),
                          ),
                        ),
                        CommandeStatutBadge(commande.statut),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.grisTexte)),
                    Text(FormatUtils.htg(commande.total),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 17, color: AppColors.grisTexte),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(commande.producteur,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Articles ────────────────────────────────────────
              if (commande.details.isNotEmpty) ...[
                Surtitre('Articles (${commande.details.length})'),
                GroupeLignes([
                  for (final item in commande.details)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const TuileIcone(Icons.inventory_2_outlined,
                              couleur: AppColors.grisTexte, taille: 38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nom']?.toString() ?? 'Produit',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                Text(
                                  // quantite_choisie/unite_choisie : ce que
                                  // l'acheteur a sélectionné (ex. « 1 sac 50 kg ») ;
                                  // quantite est dans l'unité de base du produit.
                                  '× ${item['quantite_choisie'] ?? item['quantite'] ?? 0}'
                                  '${item['unite_choisie'] != null ? ' ${item['unite_choisie']}' : ''}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.grisTexte),
                                ),
                              ],
                            ),
                          ),
                          Text(FormatUtils.htg(item['sous_total'] ?? 0),
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ]),
              ],

              // ── Livraison & paiement ────────────────────────────
              const Surtitre('Livraison et paiement'),
              Surface(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    LigneInfo(Icons.place_outlined, 'Adresse',
                        commande.adresseLivraison ?? 'Non spécifiée'),
                    LigneInfo(Icons.local_shipping_outlined, 'Mode',
                        commande.modeLivraison ?? '—'),
                    LigneInfo(Icons.payments_outlined, 'Paiement',
                        commande.statutPaiement),
                    if (commande.montantWalletUtilise > 0) ...[
                      LigneInfo(Icons.account_balance_wallet_outlined,
                          'Payé par portefeuille',
                          FormatUtils.htg(commande.montantWalletUtilise)),
                      if (commande.statutPaiement != 'paye')
                        LigneInfo(Icons.pending_outlined, 'Reste à payer',
                            FormatUtils.htg(
                                (double.tryParse(commande.total) ?? 0) -
                                    commande.montantWalletUtilise)),
                    ],
                  ],
                ),
              ),

              // ── Reçu ou bon de commande ─────────────────────────
              if (DocumentCommande.disponible(commande) case final document?)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _BoutonDocument(commande, document),
                ),
            ],
          );
        },
      ),
    );
  }
}
