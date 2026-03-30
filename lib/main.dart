import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BrothersApp()));
}

class BrothersApp extends StatelessWidget {
  const BrothersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 Pro size
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Brothers Furniture & Electronics',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Outfit',
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          ),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
