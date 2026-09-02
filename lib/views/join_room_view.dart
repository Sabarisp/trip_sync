import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trip_sync/controllers/auth_controller.dart';
import 'package:trip_sync/controllers/room_controller.dart';
import 'package:trip_sync/theme/app_theme.dart';
import 'package:trip_sync/utils/validators.dart';
import 'package:trip_sync/views/map_view.dart';
import 'package:trip_sync/widgets/app_text_field.dart';
import 'package:trip_sync/widgets/gradient_button.dart';

class JoinRoomView extends StatefulWidget {
  const JoinRoomView({super.key});

  @override
  State<JoinRoomView> createState() => _JoinRoomViewState();
}

class _JoinRoomViewState extends State<JoinRoomView> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final RoomController _room = Get.put(RoomController());

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Get.find<AuthController>();
    final uid = auth.uid;
    if (uid == null) return;

    final ok = await _room.joinRoom(roomId: _code.text, userId: uid);
    if (ok) {
      Get.offAll(() => MapView(roomId: _code.text.trim().toUpperCase()));
    } else if (_room.errorMessage.value.isNotEmpty) {
      Get.snackbar('Could not join', _room.errorMessage.value,
          backgroundColor: AppColors.surfaceElevated, colorText: AppColors.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a trip')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the trip code your friend shared',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              AppTextField(
                controller: _code,
                label: '6-character code',
                prefixIcon: Icons.confirmation_number_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: Validators.roomCode,
              ),
              const SizedBox(height: 24),
              Obx(() => GradientButton(
                    label: 'Join trip',
                    loading: _room.isLoading.value,
                    onPressed: _join,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
