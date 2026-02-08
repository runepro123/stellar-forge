import 'package:flutter/material.dart';
import 'package:galactic/game_models.dart';
import 'package:galactic/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:galactic/language_provider.dart';

class AscensionDialog extends StatelessWidget {
  final int prestigeCount;
  final int potentialGain;
  final VoidCallback onAscend;
  final String Function(double) formatNumber;

  const AscensionDialog({
    super.key,
    required this.prestigeCount,
    required this.potentialGain,
    required this.onAscend,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Access LanguageProvider to trigger rebuilds on locale change
    Provider.of<LanguageProvider>(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(l10n.ascensionProtocol,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text('${l10n.currentBonus}: +${(prestigeCount * 10)}%',
                      style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(l10n.potentialGain,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('+$potentialGain LEVELS',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: potentialGain > 0 ? onAscend : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                        potentialGain > 0
                            ? l10n.initiateRebirth
                            : l10n.moreEnergyRequired,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(24),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(l10n.cancelSequence,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
