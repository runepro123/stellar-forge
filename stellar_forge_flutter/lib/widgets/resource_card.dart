import 'package:flutter/material.dart';
import 'package:galactic/game_models.dart';
import 'package:galactic/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:galactic/language_provider.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final double rate;
  final String formattedAmount;
  final String formattedRate;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.rate,
    required this.formattedAmount,
    required this.formattedRate,
  });

  String _getLocalizedName(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'energy':
        return l10n.energy;
      case 'matter':
        return l10n.matter;
      case 'data':
        return l10n.data;
      case 'stardust':
        return l10n.stardust;
      case 'quarks':
        return l10n.quarks;
      case 'time':
        return l10n.time;
      case 'mana':
        return l10n.mana;
      case 'void_shards':
        return l10n.voidShards;
      case 'chronos_dust':
        return l10n.chronosDust;
      case 'solar_flares':
        return l10n.solarFlares;
      case 'bits':
        return l10n.bits;
      default:
        return resource.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access LanguageProvider to trigger rebuilds on locale change
    Provider.of<LanguageProvider>(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(minWidth: 120),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(resource.symbol, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(_getLocalizedName(context, resource.id).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text(formattedAmount,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'monospace')),
          Text('+$formattedRate/s',
              style: TextStyle(
                  fontSize: 10,
                  color: rate > 0 ? Colors.greenAccent : Colors.grey,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
