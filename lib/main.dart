import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/services.dart';
import 'models/models.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/race/race_bloc.dart';
import 'presentation/bloc/race/race_event.dart';
import 'presentation/bloc/scan/scan_bloc.dart';
import 'screens/home_screen_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 APP: Initializing Hive...');
  await Hive.initFlutter();

  // Register adapters
  debugPrint('🚀 APP: Registering Hive adapters...');
  Hive.registerAdapter(RunnerAdapter());
  Hive.registerAdapter(ScanAdapter());
  Hive.registerAdapter(SyncOperationAdapter());
  Hive.registerAdapter(SyncItemAdapter());
  Hive.registerAdapter(LocalRaceAdapter());
  Hive.registerAdapter(LocalEntryAdapter());

  // Initialize database
  debugPrint('🚀 APP: Initializing DatabaseService...');
  final databaseService = DatabaseService();
  await databaseService.init();
  debugPrint('🚀 APP: DatabaseService initialized');

  // Initialize AppState
  debugPrint('🚀 APP: Initializing AppState...');
  final appState = AppState();
  await appState.init();
  debugPrint('🚀 APP: AppState initialized');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        RepositoryProvider.value(value: databaseService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              debugPrint('🚀 APP: Creating RaceBloc...');
              final bloc = RaceBloc(
                context.read<DatabaseService>(),
              );
              debugPrint('🚀 APP: RaceBloc created, sending LoadRaces event...');
              bloc.add(LoadRaces());
              return bloc;
            },
          ),
          BlocProvider(
            create: (context) => ScanBloc(context.read<DatabaseService>()),
          ),
        ],
        child: const RunnerScanApp(),
      ),
    ),
  );
}

class RunnerScanApp extends StatelessWidget {
  const RunnerScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runner Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreenNew(),
    );
  }
}
