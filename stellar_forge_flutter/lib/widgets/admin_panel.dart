import 'package:flutter/material.dart';
import '../game_models.dart';

class AdminPanel extends StatelessWidget {
  final GameState state;
  final VoidCallback onStateChanged;

  const AdminPanel({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF0F172A),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '🚀 DEV ADMIN PANEL',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildSectionTitle('Quick Actions'),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            state.resources.forEach((k, v) => v.amount += 1000000);
                            onStateChanged();
                          },
                          child: const Text('+1M All'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            state.prestigeCount += 1;
                            onStateChanged();
                          },
                          child: const Text('+1 Prestige'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Resources'),
                    ...state.resources.entries.map((e) => ListTile(
                          title: Text(e.value.name, style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () {
                                  e.value.amount = (e.value.amount - 1000).clamp(0, double.infinity);
                                  onStateChanged();
                                },
                              ),
                              Text(e.value.amount.toInt().toString(), style: const TextStyle(fontSize: 10)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () {
                                  e.value.amount += 1000;
                                  e.value.totalEarned += 1000;
                                  onStateChanged();
                                },
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Upgrades (Set Level)'),
                    ...state.upgrades.map((u) => ListTile(
                          dense: true,
                          title: Text(u.name, style: const TextStyle(fontSize: 10)),
                          subtitle: Text('LV: ${u.level}', style: const TextStyle(fontSize: 9)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_downward, size: 16),
                                onPressed: () {
                                  u.level = (u.level - 1).clamp(0, 9999);
                                  onStateChanged();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 16),
                                onPressed: () {
                                  u.level += 1;
                                  onStateChanged();
                                },
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
