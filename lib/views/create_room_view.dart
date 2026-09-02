import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:trip_sync/controllers/auth_controller.dart';
import 'package:trip_sync/controllers/room_controller.dart';
import 'package:trip_sync/theme/app_theme.dart';
import 'package:trip_sync/utils/validators.dart';
import 'package:trip_sync/views/map_view.dart';
import 'package:trip_sync/widgets/app_text_field.dart';
import 'package:trip_sync/widgets/gradient_button.dart';

class CreateRoomView extends StatefulWidget {
  const CreateRoomView({super.key});

  @override
  State<CreateRoomView> createState() => _CreateRoomViewState();
}

class _CreateRoomViewState extends State<CreateRoomView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final RoomController _room = Get.put(RoomController());
  String? _createdRoomId;

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Get.find<AuthController>();
    final uid = auth.uid;
    if (uid == null) return;

    final roomId = await _room.createRoom(roomName: _name.text, createdBy: uid);
    if (roomId != null) {
      setState(() => _createdRoomId = roomId);
    } else if (_room.errorMessage.value.isNotEmpty) {
      Get.snackbar('Could not create trip', _room.errorMessage.value,
          backgroundColor: AppColors.surfaceElevated, colorText: AppColors.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a trip')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _createdRoomId == null ? _formStep() : _codeStep(_createdRoomId!),
      ),
    );
  }

  Widget _formStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Name your trip', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          AppTextField(
            controller: _name,
            label: 'e.g. Weekend in the mountains',
            prefixIcon: Icons.map_outlined,
            textCapitalization: TextCapitalization.sentences,
            validator: Validators.roomName,
          ),
          const SizedBox(height: 24),
          Obx(() => GradientButton(
                label: 'Generate trip code',
                loading: _room.isLoading.value,
                onPressed: _create,
              )),
        ],
      ),
    );
  }

  Widget _codeStep(String roomId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("You're all set!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 6),
        const Text('Share this code with your group so they can join',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                roomId,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: roomId));
                  Get.snackbar('Copied', 'Trip code copied to clipboard',
                      backgroundColor: AppColors.surfaceElevated,
                      colorText: AppColors.textPrimary);
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy code'),
              ),
            ],
          ),
        ),
        const Spacer(),
        GradientButton(
          label: 'Enter trip',
          icon: Icons.arrow_forward,
          onPressed: () => Get.offAll(() => MapView(roomId: roomId)),
        ),
      ],
    );
  }
}
