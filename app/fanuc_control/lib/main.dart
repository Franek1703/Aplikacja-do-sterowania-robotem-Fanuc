import 'package:fanuc_control/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/routing/app_router.dart';
import 'config/themes/app_theme.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/devices/cubit/devices_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FanucControlApp());
}

class FanucControlApp extends StatelessWidget {
  const FanucControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(),
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final router = AppRouter.createRouter(
                        state == AuthState.initial() ? '/login' : '/devices',
                      );
          return MaterialApp.router(
            title: 'FANUC Controller',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              routerConfig: router
            );
          }
        ),
    );
  }
}
