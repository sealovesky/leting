import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/scan_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/mini_player_bar.dart';
import 'services/audio_player_service.dart';
import 'services/local_music_service.dart';
import 'services/storage_service.dart';
import 'services/preference_service.dart';
import 'providers/player_provider.dart';
import 'providers/library_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/search_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final preferenceService = PreferenceService();
  await preferenceService.init();
  final storageService = StorageService();
  final audioPlayerService = AudioPlayerService();
  await audioPlayerService.initAudioService();
  final localMusicService = LocalMusicService();

  runApp(MusicPlayerApp(
    preferenceService: preferenceService,
    storageService: storageService,
    audioPlayerService: audioPlayerService,
    localMusicService: localMusicService,
  ));
}

class MusicPlayerApp extends StatelessWidget {
  final PreferenceService preferenceService;
  final StorageService storageService;
  final AudioPlayerService audioPlayerService;
  final LocalMusicService localMusicService;

  const MusicPlayerApp({
    super.key,
    required this.preferenceService,
    required this.storageService,
    required this.audioPlayerService,
    required this.localMusicService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(
            audioService: audioPlayerService,
            storageService: storageService,
            preferenceService: preferenceService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(
            storageService: storageService,
            localMusicService: localMusicService,
            preferenceService: preferenceService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaylistProvider(storageService: storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(
            storageService: storageService,
            preferenceService: preferenceService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(preferenceService: preferenceService),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '乐听',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.flutterThemeMode,
            locale: settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MainScreen(key: ValueKey('${settings.themeMode}_${settings.locale}')),
            routes: {
              '/settings': (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const PlaylistScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadLibrary();
      context.read<PlaylistProvider>().loadPlaylists();
      final player = context.read<PlayerProvider>();
      final library = context.read<LibraryProvider>();
      player.onPlayHistoryChanged = () => library.loadRecentlyPlayed();
      player.restoreLastSession();
      _checkFirstLaunch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final settings = context.read<SettingsProvider>();
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    settings.applySystemBrightness(brightness);
  }

  void _checkFirstLaunch() {
    final settings = context.read<SettingsProvider>();
    if (!settings.hasScanned) {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(l10n.welcomeTitle,
              style: TextStyle(color: AppColors.foreground)),
          content: Text(l10n.welcomeScanPrompt,
              style: const TextStyle(color: AppColors.mutedForeground)),
          actions: [
            TextButton(
              onPressed: () {
                settings.setHasScanned(true);
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.welcomeLater,
                  style: const TextStyle(color: AppColors.mutedForeground)),
            ),
            TextButton(
              onPressed: () {
                settings.setHasScanned(true);
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
              child: Text(l10n.welcomeScanNow,
                  style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          BottomNav(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }
}
