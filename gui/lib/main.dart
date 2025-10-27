import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:url_strategy/url_strategy.dart';
import 'providers/reservation_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_form_provider.dart';
import 'providers/login_ui_provider.dart';
import 'providers/approval_ui_provider.dart';
import 'providers/booking_ui_provider.dart';
import 'screens/public/booking_screen.dart';
import 'screens/operator/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('hr');
  Intl.defaultLocale = 'hr';
  // Enable clean path URLs on web so /login opens LoginScreen instead of defaulting to '/'
  if (kIsWeb) {
    setPathUrlStrategy();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ReservationProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => BookingFormProvider()),
          ChangeNotifierProvider(create: (_) => BookingUiProvider()),
          ChangeNotifierProvider(create: (_) => LoginUiProvider()),
          ChangeNotifierProvider(create: (_) => ApprovalUiProvider()),
        ],
        child: MaterialApp(
          title: 'Tyre Change Reservation',
          debugShowCheckedModeBanner: false,
          locale: const Locale('hr'),
          supportedLocales: const [Locale('hr')],
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2196F3),
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3), primary: const Color(0xFF2196F3)),
              useMaterial3: true,
              inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade100)),
          routes: {
            '/': (_) => const BookingScreen(),
            '/login': (_) => const LoginScreen(),
          },
          initialRoute: '/',
        ));
  }
}
