import 'package:flutter/material.dart';

class QueueHeader extends StatelessWidget {
  final VoidCallback onScrollToActive;
  final VoidCallback onToggleSearch;
  final bool isSearching;

  const QueueHeader({
    required this.onScrollToActive,
    required this.onToggleSearch,
    required this.isSearching,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Fila de reproducción',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: onScrollToActive,
                tooltip: 'Ir a la canción actual',
              ),
              IconButton(
                icon: Icon(
                  isSearching ? Icons.close : Icons.search,
                  color: isSearching
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: onToggleSearch,
                tooltip: isSearching ? 'Cerrar búsqueda' : 'Buscar en cola',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
