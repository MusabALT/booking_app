import 'package:booking_room/core/helper/spacing.dart';
import 'package:booking_room/core/theming/colors.dart';
import 'package:booking_room/core/theming/styles.dart';
import 'package:booking_room/core/widgets/app_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/athentication/athentication_controller.dart';

import 'package:booking_room/core/models/user.dart' as local_model;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthController _authController = AuthController();

  late String email, password, name, phoneNumber, address;
  final _formKey = GlobalKey<FormState>();
  bool _passwordValid = false;
  String _passwordErrorMessage = '';
  double _passwordStrength = 0;
  IconData _passwordStrengthIcon = Icons.clear;
  bool _isPasswordFieldTouched = false;

  void _validatePassword(String value) {
    setState(() {
      _isPasswordFieldTouched = true;
      _passwordValid = true;
      _passwordErrorMessage = '';
      _passwordStrength = 0;
      _passwordStrengthIcon = Icons.clear;

      if (value.length < 8) {
        _passwordValid = false;
        _passwordErrorMessage = 'Password must be at least 8 characters long';
      } else {
        _passwordStrength += 0.25;
      }
      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
        _passwordValid = false;
        _passwordErrorMessage += '\nPassword must contain an uppercase letter';
      } else {
        _passwordStrength += 0.25;
      }
      if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
        _passwordValid = false;
        _passwordErrorMessage += '\nPassword must contain a special character';
      } else {
        _passwordStrength += 0.25;
      }
      if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
        _passwordValid = false;
        _passwordErrorMessage += '\nPassword must contain a number';
      } else {
        _passwordStrength += 0.25;
      }

      if (_passwordStrength == 1) {
        _passwordStrengthIcon = Icons.check_circle;
      } else if (_passwordStrength >= 0.75) {
        _passwordStrengthIcon = Icons.check;
      } else if (_passwordStrength >= 0.5) {
        _passwordStrengthIcon = Icons.remove_circle;
      } else {
        _passwordStrengthIcon = Icons.clear;
      }
    });
  }

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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Create Account', style: TextStyles.font32BlueBold),
              verticalSpace(8),
              Text(
                'Sign up now to book your perfect room and start your journey with us.',
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
                      hintText: 'Enter Your Name',
                      icon: Icons.person,
                      onChanged: (value) => name = value,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _buildCustomTextFormField(
                      hintText: 'Enter Phone Number',
                      icon: Icons.phone,
                      onChanged: (value) => phoneNumber = value,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your phone number'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _buildCustomTextFormField(
                      hintText: 'Enter Address',
                      icon: Icons.home,
                      onChanged: (value) => address = value,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your address'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _buildCustomTextFormField(
                      hintText: 'Enter Password',
                      icon: Icons.lock,
                      obscureText: true,
                      onChanged: (value) {
                        password = value;
                        _validatePassword(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (!_passwordValid) {
                          return _passwordErrorMessage;
                        }
                        return null;
                      },
                    ),
                    if (_isPasswordFieldTouched) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: Colors.red,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _passwordStrength >= 1 ? Colors.green : Colors.yellow,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Icon(
                        _passwordStrengthIcon,
                        color: _passwordStrength >= 1
                            ? Colors.green
                            : (_passwordStrength >= 0.75
                                ? Colors.yellow
                                : Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppTextButton(
                      buttonText: 'Create an Account',
                      textStyle: TextStyles.font16WhiteSemiBold,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        try {
                          local_model.User? newUser =
                              (await _authController.register(
                                  email, password, name, phoneNumber, address));
                          if (newUser != null) {
                            Navigator.pushReplacementNamed(
                                context, '/customer_home');
                          } else {
                            _showErrorDialog(
                                'Registration failed. Please try again.');
                          }
                        } catch (error) {
                          _showErrorDialog(
                              'An error occurred: ${error.toString()}');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ]),
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
