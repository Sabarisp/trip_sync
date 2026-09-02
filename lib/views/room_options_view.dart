import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trip_sync/controllers/auth_controller.dart';
import 'package:trip_sync/theme/app_theme.dart';
import 'package:trip_sync/views/create_room_view.dart';
import 'package:trip_sync/views/join_room_view.dart';
import 'package:trip_sync/views/login_view.dart';

class RoomOptionsView extends StatelessWidget {
  const RoomOptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Get.offAll(() => const LoginView());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final name = auth.firebaseUser.value?.displayName ?? '';
              return Text(
                name.isNotEmpty ? 'Hey, $name 👋' : 'Welcome back 👋',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              );
            }),
            const SizedBox(height: 4),
            const Text('Start a new trip or hop into one your friends made',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _OptionCard(
              icon: Icons.add_location_alt_outlined,
              title: 'Create a trip',
              subtitle: 'Get a shareable code for your group',
              color: AppColors.primary,
              onTap: () => Get.to(() => const CreateRoomView()),
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.group_add_outlined,
              title: 'Join a trip',
              subtitle: 'Enter a 6-character code from a friend',
              color: AppColors.accent,
              onTap: () => Get.to(() => const JoinRoomView()),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
