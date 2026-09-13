import 'package:flutter/material.dart';
import 'hint_service.dart';

/// The single hint surface in the app. Rendered once, in the same place,
/// visible to whoever is looking at the phone — not tied to a camera
/// angle, not per-player, not delayed or coded.
class HintBar extends StatelessWidget {
  final HintResult? hint;
  final bool isThinking;
  final HintTier tier;
  final ValueChanged<HintTier> onTierChanged;
  final VoidCallback onRequestHint;
  final VoidCallback? onClearHint;

  const HintBar({
    super.key,
    required this.hint,
    required this.isThinking,
    required this.tier,
    required this.onTierChanged,
    required this.onRequestHint,
    this.onClearHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isThinking
                      ? 'Thinking...'
                      : (hint?.displayText ?? 'No hint requested yet.'),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              if (hint != null && !isThinking)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: onClearHint,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isThinking ? null : onRequestHint,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Refresh Hint'),
              ),
              const SizedBox(width: 12),
              DropdownButton<HintTier>(
                value: tier,
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: HintTier.simple, child: Text('Simple (e2 → e4)')),
                  DropdownMenuItem(value: HintTier.beginner, child: Text('Beginner (named piece)')),
                  DropdownMenuItem(value: HintTier.explained, child: Text('Explained (with reason)')),
                ],
                onChanged: (v) {
                  if (v != null) onTierChanged(v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
