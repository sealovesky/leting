import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'scan_screen.dart';
import 'equalizer_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 22,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                        Text(
                          l10n.settingsTitle,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Music management
                        _buildSectionTitle(l10n.settingsMusicManagement),
                        const SizedBox(height: 12),
                        _buildNavItem(
                          context,
                          icon: Icons.radar_rounded,
                          gradient: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
                          title: l10n.settingsScanLocalMusic,
                          subtitle: l10n.settingsScanLocalMusicDesc,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ScanScreen()),
                          ),
                        ),

                        // Playback
                        const SizedBox(height: 24),
                        _buildSectionTitle(l10n.settingsPlayback),
                        const SizedBox(height: 12),
                        _buildNavItem(
                          context,
                          icon: Icons.equalizer_rounded,
                          gradient: const [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
                          title: l10n.settingsEqualizer,
                          subtitle: l10n.settingsEqualizerDesc,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const EqualizerScreen()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          icon: Icons.headphones_rounded,
                          gradient: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                          title: l10n.settingsAudioQuality,
                          subtitle: settings.audioQuality,
                          onTap: () =>
                              _showAudioQualityDialog(context, settings),
                        ),

                        // Appearance
                        const SizedBox(height: 24),
                        _buildSectionTitle(l10n.settingsAppearance),
                        const SizedBox(height: 12),
                        _buildNavItem(
                          context,
                          icon: Icons.palette_rounded,
                          gradient: const [Color(0xFFFA709A), Color(0xFFFEE140)],
                          title: l10n.settingsTheme,
                          subtitle: _themeLabel(context, settings.themeMode),
                          onTap: () =>
                              _showThemePicker(context, settings),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          icon: Icons.language_rounded,
                          gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                          title: l10n.settingsLanguage,
                          subtitle: _localeLabel(context, settings),
                          onTap: () =>
                              _showLanguagePicker(context, settings),
                        ),

                        // Other
                        const SizedBox(height: 24),
                        _buildSectionTitle(l10n.settingsOther),
                        const SizedBox(height: 12),
                        _buildSwitchItem(
                          icon: Icons.notifications_rounded,
                          gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          title: l10n.settingsNotification,
                          subtitle: l10n.settingsNotificationDesc,
                          value: settings.notificationEnabled,
                          onChanged: (v) =>
                              settings.setNotificationEnabled(v),
                        ),

                        // Footer
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFC3E4E),
                                      Color(0xFFFF7B54),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.music_note_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(l10n.settingsVersion,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.mutedForeground)),
                              const SizedBox(height: 2),
                              Text(l10n.settingsMadeWith,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required List<Color> gradient,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16, color: AppColors.foreground)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16, color: AppColors.foreground)),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  String _themeLabel(BuildContext context, int mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 1:
        return l10n.settingsThemeLight;
      case 2:
        return l10n.settingsThemeSystem;
      default:
        return l10n.settingsThemeDark;
    }
  }

  String _localeLabel(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final code = settings.locale?.languageCode;
    if (code == null) return l10n.settingsLangSystem;
    if (code == 'en') return l10n.settingsLangEnglish;
    return l10n.settingsLangChinese;
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'label': l10n.settingsThemeDark, 'icon': Icons.dark_mode_rounded, 'value': 0},
      {'label': l10n.settingsThemeLight, 'icon': Icons.light_mode_rounded, 'value': 1},
      {'label': l10n.settingsThemeSystem, 'icon': Icons.brightness_auto_rounded, 'value': 2},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.mutedForeground.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(l10n.settingsSelectTheme,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground)),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = settings.themeMode == opt['value'];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(
                    opt['icon'] as IconData,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                  title: Text(opt['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.foreground,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    settings.setThemeMode(opt['value'] as int);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAudioQualityDialog(
      BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'label': l10n.settingsQualityStandard, 'desc': l10n.settingsQualityStandardDesc},
      {'label': l10n.settingsQualityHigh, 'desc': l10n.settingsQualityHighDesc},
      {'label': l10n.settingsQualityLossless, 'desc': l10n.settingsQualityLosslessDesc},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.mutedForeground.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(l10n.settingsSelectQuality,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground)),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected =
                    settings.audioQuality == opt['label'];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(opt['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.foreground,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                  subtitle: Text(opt['desc']!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground)),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    settings.setAudioQuality(opt['label']!);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final currentCode = settings.locale?.languageCode;
    final options = [
      {'label': l10n.settingsLangSystem, 'icon': Icons.brightness_auto_rounded, 'value': null},
      {'label': l10n.settingsLangChinese, 'icon': Icons.translate_rounded, 'value': 'zh'},
      {'label': l10n.settingsLangEnglish, 'icon': Icons.translate_rounded, 'value': 'en'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.mutedForeground.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(l10n.settingsSelectLanguage,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground)),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = currentCode == opt['value'];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(
                    opt['icon'] as IconData,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                  title: Text(opt['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.foreground,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    settings.setLocale(opt['value'] as String?);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
