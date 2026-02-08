import 'package:flutter/material.dart';
import 'package:galactic/game_models.dart';
import 'package:galactic/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:galactic/language_provider.dart';

class GalaxyMapDialog extends StatelessWidget {
  final GameState state;
  final Function(String) onWorldSelected;
  final String Function(double) formatNumber;

  const GalaxyMapDialog({
    super.key,
    required this.state,
    required this.onWorldSelected,
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
        constraints: const BoxConstraints(maxWidth: 900),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.multiverseConduit,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: worlds.map((world) {
                    bool unlocked = state.unlockedWorlds.contains(world.id);
                    bool active = state.currentWorld == world.id;
                    final res = state.resources[world.unlockResource];
                    bool canUnlock = (res?.amount ?? 0) >= world.unlockAmount;

                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.black.withOpacity(0.2),
                        border: Border.all(
                            color: active
                                ? Colors.blue.withOpacity(0.5)
                                : Colors.white10),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(world.name.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900)),
                              if (active)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Text('ACTIVE',
                                      style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(world.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 24),
                          if (unlocked)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: active
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.blue,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: active
                                  ? null
                                  : () => onWorldSelected(world.id),
                              child: Text(
                                  active
                                      ? l10n.currentLocation
                                      : l10n.initializeWarp,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canUnlock
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.black26,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: canUnlock
                                  ? () => onWorldSelected(world.id)
                                  : null,
                              child: Text(
                                  canUnlock
                                      ? 'UNLOCK REALM'
                                      : 'LOCKED: ${formatNumber(world.unlockAmount)} ${world.unlockResource}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: canUnlock
                                          ? Colors.greenAccent
                                          : Colors.grey)),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
