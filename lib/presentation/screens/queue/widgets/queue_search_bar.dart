import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/search_provider.dart';

class QueueSearchBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const QueueSearchBar({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  @override
  ConsumerState<QueueSearchBar> createState() => _QueueSearchBarState();
}

class _QueueSearchBarState extends ConsumerState<QueueSearchBar> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: widget.controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Filtrar cola...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                widget.onChanged(value);
              });
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                ref
                    .read(searchHistoryServiceProvider)
                    .addEntry(value)
                    .then((_) => ref.refresh(searchHistoryProvider));
              }
            },
          ),
          if (widget.controller.text.isEmpty)
            Consumer(
              builder: (context, ref, child) {
                final historyAsync = ref.watch(searchHistoryProvider);
                return historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) return const SizedBox.shrink();
                    return Container(
                      height: 40,
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: history.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final term = history[index];
                          return ActionChip(
                            label: Text(term),
                            onPressed: () {
                              widget.controller.text = term;
                              widget.onChanged(term);
                              ref
                                  .read(searchHistoryServiceProvider)
                                  .addEntry(term)
                                  .then(
                                    (_) => ref.refresh(searchHistoryProvider),
                                  );
                            },
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                );
              },
            ),
        ],
      ),
    );
  }
}
