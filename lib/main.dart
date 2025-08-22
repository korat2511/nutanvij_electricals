import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/screens/home/home_screen.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/create_transporter_provider.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/download_report_provider.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/edit_transporter_provider.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/inventory_provider.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/transporter_fair_provider.dart';
import 'package:nutanvij_electricals/screens/site/providers/contractor_provider.dart';
import 'package:nutanvij_electricals/screens/splash_screen.dart';
import 'package:nutanvij_electricals/screens/task/task_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/utils/navigation_utils.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'screens/task/task_details_screen.dart' show TaskDetailsScreen;
import 'services/notification_permission_service.dart';
import 'services/foreground_notification_service.dart';
import 'services/auto_checkout_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await PackageInfo.fromPlatform();

  // Configure FCM
  NotificationPermissionService.configureBackgroundMessage();
  NotificationPermissionService.configureForegroundMessage();

  // Handle notification tap when app is opened from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from notification: ${message.data}');
    _handleNotificationNavigation(message);
  });

  // Handle initial notification if app was terminated
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('App opened from terminated state: ${initialMessage.data}');
    _handleNotificationNavigation(initialMessage);
  }

  runApp(const MyApp());
}

void _handleNotificationNavigation(RemoteMessage message) {
  final data = message.data;
  if (data.containsKey('screen')) {
    final screen = data['screen'];
    final context = ForegroundNotificationService.navigatorKey.currentContext;
    
    if (context == null) {
      print('Context not available for navigation');
      return;
    }
    
    switch (screen) {
      case 'taskDetailsScreen':
        if (data.containsKey('task_id')) {
          NavigationUtils.push(context, TaskDetailsScreen(taskId: data['task_id']));
        }
        break;
      case 'taskListScreen':
        if (data.containsKey('site_id')) {
          print('Navigate to site details: ${data['site_id']}');
          NavigationUtils.push(context, TaskListScreen(siteId: data['site_id']));
        }
        break;
      case 'homeScreen':
        print('Navigate to attendance screen');
        NavigationUtils.push(context, HomeScreen());
        break;
      default:
        print('Unknown screen: $screen');
        break;
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        print('App resumed - auto checkout monitoring continues');
        // Check location immediately when app comes to foreground
        AutoCheckoutService.instance.checkLocationInBackground();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., receiving a phone call)
        print('App inactive - auto checkout monitoring continues');
        break;
      case AppLifecycleState.paused:
        // App is in background
        print('App paused - auto checkout monitoring continues in background');
        // Perform a background auto checkout check
        AutoCheckoutService.instance.performBackgroundAutoCheckout();
        break;
      case AppLifecycleState.detached:
        // App is terminated
        print('App detached - auto checkout monitoring will stop');
        AutoCheckoutService.instance.stopMonitoring();
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new in Flutter 3.7+)
        print('App hidden - auto checkout monitoring continues');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()), // 👈 Added
        ChangeNotifierProvider(create: (_) => CreateTransporterProvider()),
        ChangeNotifierProvider(create: (_) => EditTransporterProvider()),
        ChangeNotifierProvider(create: (_) => TransporterFairProvider()),
        ChangeNotifierProvider(create: (_) => DownloadReportProvider()),
        ChangeNotifierProvider(create: (_) => ContractorProvider()),


      ],
      child: MaterialApp(
        navigatorKey: ForegroundNotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Nutanvij Electricals',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0XFF0D6EFD)),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),

    );
  }
}


