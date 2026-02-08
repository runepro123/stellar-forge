import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:galactic/l10n/generated/app_localizations.dart';
import 'package:galactic/language_provider.dart';

class CloudSettingsDialog extends StatelessWidget {
  final bool isCloudSignedIn;
  final VoidCallback onConnect;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onWipe;

  const CloudSettingsDialog({
    super.key,
    required this.isCloudSignedIn,
    required this.onConnect,
    required this.onSave,
    required this.onLoad,
    required this.onWipe,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.systemParameters,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Text(l10n.language,
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: languageProvider.locale,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    items: languageProvider.supportedLocales.map((locale) {
                      return DropdownMenuItem(
                        value: locale,
                        child: Text(languageProvider.getLanguageName(locale)),
                      );
                    }).toList(),
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        languageProvider.setLocale(newLocale);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(l10n.progressSync,
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (kIsWeb)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.cloudSaveActive,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                  ],
                )
              else if (!isCloudSignedIn)
                Column(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(l10n.connectGooglePlay),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        side: const BorderSide(color: Colors.greenAccent),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: onConnect,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        side: const BorderSide(color: Colors.grey),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.playOffline,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ],
                )
              else ...[
                const Text('CONNECTED TO GOOGLE PLAY',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: Text(l10n.manualCloudSave),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    side: const BorderSide(color: Colors.blueAccent),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: onSave,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_download, size: 18),
                  label: Text(l10n.manualCloudLoad),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.2),
                    side: const BorderSide(color: Colors.amberAccent),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: onLoad,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.06),
                    side: const BorderSide(color: Colors.white10),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.backToGame,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
              const SizedBox(height: 32),
              Text(l10n.dangerZone,
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: const Text('WIPE ALL DATA?'),
                      content: const Text(
                          'This will permanently delete all progress. This cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onWipe();
                            Navigator.pop(context);
                          },
                          child: Text(l10n.wipeCoreMemory,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(l10n.wipeCoreMemory,
                    style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
