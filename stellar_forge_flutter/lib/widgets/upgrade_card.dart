import 'package:flutter/material.dart';
import 'package:galactic/game_models.dart';
import 'package:galactic/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:galactic/language_provider.dart';

class UpgradeCard extends StatelessWidget {
  final Upgrade upgrade;
  final Resource resource;
  final bool unlocked;
  final bool canBuy;
  final int countToBuy;
  final double totalCost;
  final double outputGain;
  final VoidCallback onTap;
  final String Function(double) formatNumber;

  const UpgradeCard({
    super.key,
    required this.upgrade,
    required this.resource,
    required this.unlocked,
    required this.canBuy,
    required this.countToBuy,
    required this.totalCost,
    required this.outputGain,
    required this.onTap,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Access LanguageProvider to trigger rebuilds on locale change
    Provider.of<LanguageProvider>(context);
    if (!unlocked) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Text(l10n.restrictedTech,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const Spacer(),
            Text('REQ: ${formatNumber(upgrade.unlockedAt)} ${resource.symbol}',
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: canBuy
              ? Colors.blue.withOpacity(0.05)
              : Colors.black.withOpacity(0.2),
          border: Border.all(
              color: canBuy ? Colors.blue.withOpacity(0.3) : Colors.white10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(upgrade.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${l10n.level}.${upgrade.level}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(upgrade.description,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.cost,
                        style:
                            const TextStyle(fontSize: 8, color: Colors.grey)),
                    Text('${formatNumber(totalCost)} ${resource.symbol}',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                canBuy ? Colors.greenAccent : Colors.redAccent,
                            fontFamily: 'monospace')),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.output,
                        style:
                            const TextStyle(fontSize: 8, color: Colors.grey)),
                    Text('+${formatNumber(outputGain)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
