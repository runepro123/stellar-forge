import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../update_service.dart';

class UpdateProgressBar extends StatelessWidget {
  const UpdateProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, child) {
        if (!updateService.isDownloading && !updateService.updateReady) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: const Border(
              bottom: BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      updateService.updateReady 
                        ? 'Update Ready (v${updateService.newVersion})'
                        : 'Downloading Update v${updateService.newVersion}... ${(updateService.downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (updateService.isDownloading)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: updateService.downloadProgress,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          minHeight: 8,
                        ),
                      ),
                    if (updateService.updateReady)
                      const Text(
                        'Click to restart and apply update',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                  ],
                ),
              ),
              if (updateService.updateReady)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ElevatedButton(
                    onPressed: () => updateService.applyUpdateAndRestart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('RESTART'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
