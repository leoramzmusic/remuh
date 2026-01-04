import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/track.dart';
import '../providers/audio_player_provider.dart';
import '../../services/permission_service.dart';

class NotificationTestButton extends ConsumerWidget {
  const NotificationTestButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      heroTag: 'notification_test_btn',
      onPressed: () async {
        final repo = ref.read(audioRepositoryProvider);
        final permissionService = PermissionService();

        // CRITICAL: Request notification permission first
        await permissionService.requestNotificationPermission();

        // Define a test track with a reliable online URL
        final testTrack = Track(
          id: 'test_notification_1',
          title: 'Notification Test',
          artist: 'REMUH Debugger',
          album: 'Debug Album',
          duration: const Duration(minutes: 2), // Fake duration
          fileUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          filePath: '',
          artworkPath:
              'https://via.placeholder.com/300/09f/fff.png?text=Test+Art',
        );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading test track... Check notifications!'),
          ),
        );

        try {
          await repo.loadTrack(testTrack);
          await repo.play();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      },
      label: const Text('Test Notification'),
      icon: const Icon(Icons.notifications_active),
      backgroundColor: Colors.orange,
    );
  }
}
