import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/core/routes/app_router.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';
import 'package:dannisa_sweet_pos/features/dashboard/presentation/providers/product_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}
