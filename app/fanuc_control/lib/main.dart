import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/routing/app_router.dart';
import 'config/themes/app_theme.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/devices/cubit/devices_cubit.dart';

void main() {
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
        BlocProvider(
          create: (context) => DevicesCubit(),
        ),
      ],
      child: MaterialApp.router(
        title: 'FANUC Controller',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
