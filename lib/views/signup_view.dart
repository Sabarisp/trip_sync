import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trip_sync/controllers/auth_controller.dart';
import 'package:trip_sync/theme/app_theme.dart';
import 'package:trip_sync/utils/validators.dart';
import 'package:trip_sync/views/room_options_view.dart';
import 'package:trip_sync/widgets/app_text_field.dart';
import 'package:trip_sync/widgets/gradient_button.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  final AuthController _auth = Get.find();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.signUp(
      email: _email.text,
      password: _password.text,
      displayName: _name.text,
    );
    if (ok) {
      Get.offAll(() => const RoomOptionsView());
    } else if (_auth.errorMessage.value.isNotEmpty) {
      Get.snackbar('Sign up failed', _auth.errorMessage.value,
          backgroundColor: AppColors.surfaceElevated, colorText: AppColors.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text('Create your account',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('A few details and you are ready to roll',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _name,
                  label: 'Display name',
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.displayName,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => GradientButton(
                      label: 'Create Account',
                      loading: _auth.isLoading.value,
                      onPressed: _submit,
                    )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
