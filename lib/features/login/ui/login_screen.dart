import 'package:booking_room/core/athentication/athentication_controller.dart';
import 'package:flutter/material.dart';
import 'package:booking_room/core/helper/spacing.dart';
import 'package:booking_room/core/theming/colors.dart';
import 'package:booking_room/core/theming/styles.dart';
import 'package:booking_room/core/widgets/app_text_button.dart';
import 'package:booking_room/core/models/user.dart' as local_model;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();

  late String email, password;
  final _formKey = GlobalKey<FormState>();
  final String _errorMessage = '';

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back', style: TextStyles.font32BlueBold),
                verticalSpace(8),
                Text(
                  'Log in to continue booking your perfect room.',
                  style: TextStyles.font14GrayRegular,
                ),
                verticalSpace(36),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildCustomTextFormField(
                        hintText: 'Enter Email',
                        icon: Icons.email,
                        onChanged: (value) => email = value,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your email'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildCustomTextFormField(
                        hintText: 'Enter Password',
                        icon: Icons.lock,
                        obscureText: true,
                        onChanged: (value) => password = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AppTextButton(
                        buttonText: 'Log In',
                        textStyle: TextStyles.font16WhiteSemiBold,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          try {
                            local_model.User? user =
                                await _authController.login(email, password);
                            if (user != null) {
                              // Navigate to the appropriate screen based on role
                              if (user.role == 'admin') {
                                Navigator.pushReplacementNamed(
                                    context, '/adminHomeScreen');
                              } else if (user.role == 'superAdmin') {
                                Navigator.pushReplacementNamed(
                                    context, '/superAdminHomeScreen');
                              } else {
                                Navigator.pushReplacementNamed(
                                    context, '/homeScreen');
                              }
                            } else {
                              _showErrorDialog(
                                  'Login failed. Please check your credentials.');
                            }
                          } catch (error) {
                            _showErrorDialog(
                                'An error occurred: ${error.toString()}');
                          }
                        },
                      ),
                      verticalSpace(36),
                      AppTextButton(
                        buttonText: 'Sign Up',
                        textStyle: TextStyles.font16WhiteSemiBold,
                        onPressed: () async {
                          Navigator.pushNamed(context, '/registrationScreen');
                        },
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(_errorMessage,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextFormField({
    required String hintText,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: ColorsManager.mainBlue,
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: ColorsManager.lighterGray,
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        hintStyle: TextStyles.font13GrayRegular,
        hintText: hintText,
        suffixIcon: Icon(icon),
        fillColor: ColorsManager.moreLightGray,
        filled: true,
      ),
      onChanged: onChanged,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
