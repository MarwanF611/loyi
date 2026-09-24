import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'config.dart';
import 'demo_firebase_options.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // clean URLs like /t/<tagId>, needed for NFC links

  await Firebase.initializeApp(
    options: useEmulators ? DemoFirebaseOptions.currentPlatform : DefaultFirebaseOptions.currentPlatform,
  );
  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8085);
  }
  // Wait for the persisted session so the first screen knows who is signed in.
  await FirebaseAuth.instance.authStateChanges().first;

  runApp(const LoyiApp());
}

class LoyiApp extends StatefulWidget {
  const LoyiApp({super.key});

  @override
  State<LoyiApp> createState() => _LoyiAppState();
}

class _LoyiAppState extends State<LoyiApp> {
  final _router = buildRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Loyi',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    routerConfig: _router,
  );
}
