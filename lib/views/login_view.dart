import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trip_sync/controllers/auth_controller.dart';
import 'package:trip_sync/theme/app_theme.dart';
import 'package:trip_sync/utils/validators.dart';
import 'package:trip_sync/views/room_options_view.dart';
import 'package:trip_sync/views/signup_view.dart';
import 'package:trip_sync/widgets/app_text_field.dart';
import 'package:trip_sync/widgets/gradient_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  final AuthController _auth = Get.put(AuthController());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.login(email: _email.text, password: _password.text);
    if (ok) {
      Get.offAll(() => const RoomOptionsView());
    } else if (_auth.errorMessage.value.isNotEmpty) {
      Get.snackbar('Login failed', _auth.errorMessage.value,
          backgroundColor: AppColors.surfaceElevated, colorText: AppColors.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: const Icon(Icons.explore_rounded, color: Colors.black, size: 32),
                ),
                const SizedBox(height: 24),
                Text('Welcome back',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Sign in to sync up with your group',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
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
                      label: 'Log In',
                      loading: _auth.isLoading.value,
                      onPressed: _submit,
                    )),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?",
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Get.to(() => const SignupView()),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
