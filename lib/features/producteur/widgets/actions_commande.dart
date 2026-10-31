import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../shared/ui/ui.dart';
import '../providers/commandes_producteur_provider.dart';
import '../providers/dashboard_provider.dart';

/// Applique une action du backend (confirmer, preparer, prete, annuler) sur
/// une commande reçue, puis rafraîchit la liste, le détail et le tableau de
/// bord. Annuler demande d'abord un motif, exigé par le serveur.
Future<void> appliquerActionCommande(
  BuildContext context,
  WidgetRef ref,
  String numero,
  String action,
) async {
  var motif = '';
  if (action == 'annuler') {
    final saisi = await _demanderMotif(context);
    if (saisi == null) return;
    motif = saisi;
  }

  final result = await ref
      .read(commandesProducteurProvider('').notifier)
      .changerStatut(numero, action, motif: motif);
  final ok = result?['success'] == true;
  if (ok) {
    ref.invalidate(commandesProducteurProvider);
    ref.invalidate(commandeProducteurDetailProvider(numero));
    ref.invalidate(dashboardProvider);
  }
  if (context.mounted) {
    afficherMessage(
      context,
      ok
          ? _messages[action] ?? 'Commande mise à jour'
          : extraireMessageErreur(
              result?['error'], 'La commande n’a pas pu être mise à jour.'),
      succes: ok,
    );
  }
}

const _messages = {
  'confirmer': 'Commande confirmée',
  'preparer':  'Commande en préparation',
  'prete':     'Commande prête',
  'annuler':   'Commande annulée',
};

Future<String?> _demanderMotif(BuildContext context) => showDialog<String>(
      context: context,
      builder: (_) => const _DialogueMotif(),
    );

class _DialogueMotif extends StatefulWidget {
  const _DialogueMotif();

  @override
  State<_DialogueMotif> createState() => _DialogueMotifState();
}

class _DialogueMotifState extends State<_DialogueMotif> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motif = _ctrl.text.trim();
    return AlertDialog(
      title: const Text('Annuler la commande ?'),
      content: TextField(
        controller: _ctrl,
        autofocus:  true,
        onChanged:  (_) => setState(() {}),
        decoration: const InputDecoration(labelText: 'Motif (requis)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour'),
        ),
        FilledButton(
          onPressed: motif.isEmpty ? null : () => Navigator.pop(context, motif),
          style: FilledButton.styleFrom(backgroundColor: AppColors.rouge),
          child: const Text('Annuler la commande'),
        ),
      ],
    );
  }
}

/// Boutons du détail d'une commande, selon `actions_possibles` du backend.
class ActionsCommande extends ConsumerStatefulWidget {
  final String numero;
  final List<String> actions;
  const ActionsCommande({required this.numero, required this.actions, super.key});

  @override
  ConsumerState<ActionsCommande> createState() => _ActionsCommandeState();
}

class _ActionsCommandeState extends ConsumerState<ActionsCommande> {
  static const _principales = {
    'confirmer': ('Confirmer la commande', Icons.check_circle_outline_rounded),
    'preparer':  ('Passer en préparation', Icons.inventory_outlined),
    'prete':     ('Marquer prête', Icons.task_alt_rounded),
  };

  bool _enCours = false;

  Future<void> _lancer(String action) async {
    setState(() => _enCours = true);
    await appliquerActionCommande(context, ref, widget.numero, action);
    if (mounted) setState(() => _enCours = false);
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions;
    final principale = actions.where(_principales.containsKey).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (principale != null)
          FilledButton.icon(
            onPressed: _enCours ? null : () => _lancer(principale),
            icon:  Icon(_principales[principale]!.$2),
            label: Text(_principales[principale]!.$1),
          ),
        if (actions.contains('annuler')) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _enCours ? null : () => _lancer('annuler'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.rouge),
            child: const Text('Annuler la commande'),
          ),
        ],
      ],
    );
  }
}
