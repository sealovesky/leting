import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../l10n/app_localizations.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.scanTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          final denied = library.permissionDenied;
          final permanentlyDenied = library.permissionPermanentlyDenied;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: denied
                        ? Colors.orange.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    denied
                        ? Icons.lock_rounded
                        : library.isScanning
                            ? Icons.radar_rounded
                            : Icons.folder_open_rounded,
                    size: 56,
                    color: denied ? Colors.orange : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                // Status text
                Text(
                  denied
                      ? l10n.scanNeedPermission
                      : library.isScanning
                          ? library.scanStatus
                          : library.songs.isEmpty
                              ? l10n.scanTapToScan
                              : l10n.scanSongCount(library.songs.length),
                  style: TextStyle(
                    fontSize: 16,
                    color: denied
                        ? Colors.orange
                        : AppColors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (permanentlyDenied) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.scanPermPermanentDenied,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                if (library.isScanning)
                  Text(
                    l10n.scanFoundCount(library.scanCount),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                const SizedBox(height: 16),
                // Progress indicator
                if (library.isScanning)
                  LinearProgressIndicator(
                    backgroundColor: AppColors.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                const Spacer(),
                // Action button
                if (permanentlyDenied) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => library.openSettings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        l10n.scanGoToSettings,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => library.scanLocalMusic(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        l10n.scanRetry,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: library.isScanning
                          ? null
                          : () => library.scanLocalMusic(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: denied
                            ? Colors.orange
                            : AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        library.isScanning
                            ? l10n.scanScanning
                            : denied
                                ? l10n.scanGrantPermission
                                : library.songs.isEmpty
                                    ? l10n.scanStart
                                    : l10n.scanRescan,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Supported formats info
                Text(
                  l10n.scanSupportedFormats,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
