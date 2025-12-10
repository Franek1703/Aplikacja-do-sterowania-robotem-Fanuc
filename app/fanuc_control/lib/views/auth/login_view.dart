import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/primary_button.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/widgets/login_header.dart';
import '../../features/auth/widgets/login_tab_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupCompanyController = TextEditingController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupCompanyController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    context.read<AuthCubit>().login(
          _loginEmailController.text,
          _loginPasswordController.text,
        );
  }

  void _handleSignup() {
    context.read<AuthCubit>().signUp(
          email: _signupEmailController.text,
          password: _signupPasswordController.text,
          name: _signupNameController.text,
          company: _signupCompanyController.text.isEmpty
              ? null
              : _signupCompanyController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          context.go('/devices');
        }
      },
      child: AppScaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const LoginHeader(),
                  // Login/Signup Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: LoginTabButton(
                                  label: 'Log In',
                                  isSelected: _selectedTab == 0,
                                  onTap: () => setState(() => _selectedTab = 0),
                                ),
                              ),
                              Expanded(
                                child: LoginTabButton(
                                  label: 'Sign Up',
                                  isSelected: _selectedTab == 1,
                                  onTap: () => setState(() => _selectedTab = 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Login Form
                        if (_selectedTab == 0) ...[
                          AppTextField(
                            label: 'Email',
                            hint: 'engineer@company.com',
                            controller: _loginEmailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Password',
                            hint: '••••••••',
                            controller: _loginPasswordController,
                            obscureText: true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            text: 'Log In',
                            icon: Icons.login,
                            onPressed: _handleLogin,
                          ),
                        ],

                        // Signup Form
                        if (_selectedTab == 1) ...[
                          AppTextField(
                            label: 'Full Name',
                            hint: 'John Smith',
                            controller: _signupNameController,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Email',
                            hint: 'engineer@company.com',
                            controller: _signupEmailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Company',
                            hint: 'Acme Manufacturing',
                            controller: _signupCompanyController,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Password',
                            hint: '••••••••',
                            controller: _signupPasswordController,
                            obscureText: true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            text: 'Create Account',
                            icon: Icons.person_add,
                            onPressed: _handleSignup,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Secure access to your industrial robots',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
