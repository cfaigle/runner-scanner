import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/services.dart';
import 'models/models.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/race/race_bloc.dart';
import 'presentation/bloc/race/race_event.dart';
import 'screens/home_screen_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(RunnerAdapter());
  Hive.registerAdapter(ScanAdapter());
  Hive.registerAdapter(SyncOperationAdapter());
  Hive.registerAdapter(SyncItemAdapter());
  Hive.registerAdapter(LocalRaceAdapter());
  Hive.registerAdapter(LocalEntryAdapter());

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: databaseService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => RaceBloc(
              context.read<DatabaseService>(),
            )..add(LoadRaces()),
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
