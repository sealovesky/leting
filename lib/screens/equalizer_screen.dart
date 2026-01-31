import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../l10n/app_localizations.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  AndroidEqualizer? _equalizer;
  AndroidEqualizerParameters? _params;
  bool _enabled = false;
  String? _activePreset;

  Map<String, List<double>> _getPresets() {
    final l10n = AppLocalizations.of(context)!;
    return {
      l10n.equalizerPresetFlat: [0, 0, 0, 0, 0],
      l10n.equalizerPresetBassBoost: [4.5, 3.0, 0, 0, 0],
      l10n.equalizerPresetPop: [1.5, 3.0, 2.0, 1.0, 2.5],
      l10n.equalizerPresetRock: [4.0, 2.0, -1.0, 2.5, 3.5],
      l10n.equalizerPresetJazz: [3.0, 1.5, -1.5, 1.0, 3.0],
      l10n.equalizerPresetClassical: [3.5, 1.5, 0, 1.5, 3.0],
      l10n.equalizerPresetVocal: [-1.0, 0, 2.5, 3.0, 1.0],
      l10n.equalizerPresetElectronic: [3.5, 2.0, 0, -1.0, 3.5],
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_equalizer == null) {
      _equalizer = context.read<PlayerProvider>().equalizer;
      _loadParams();
    }
  }

  Future<void> _loadParams() async {
    if (_equalizer == null) return;
    _enabled = _equalizer!.enabled;
    final params = await _equalizer!.parameters;
    if (mounted) setState(() => _params = params);
  }

  void _applyPreset(String name) {
    final presets = _getPresets();
    final gains = presets[name];
    if (gains == null || _params == null) return;
    final bands = _params!.bands;
    final minDb = _params!.minDecibels.toDouble();
    final maxDb = _params!.maxDecibels.toDouble();
    for (int i = 0; i < bands.length && i < gains.length; i++) {
      bands[i].setGain(gains[i].clamp(minDb, maxDb));
    }
    setState(() => _activePreset = name);
  }

  String _formatFreq(double freq) {
    if (freq >= 1000) {
      final k = freq / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return '${freq.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      l10n.equalizerTitle,
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
            Expanded(
              child: _equalizer == null
                  ? _buildUnsupported()
                  : _params == null
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _buildEqualizer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupported() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.equalizer_rounded,
              size: 64, color: AppColors.mutedForeground),
          const SizedBox(height: 16),
          Text(l10n.equalizerUnsupported,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.mutedForeground)),
          const SizedBox(height: 8),
          Text(l10n.equalizerAndroidOnly,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }

  Widget _buildEqualizer() {
    final l10n = AppLocalizations.of(context)!;
    final presets = _getPresets();
    return Column(
      children: [
        // Enable toggle
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.equalizerEnable,
                  style:
                      TextStyle(fontSize: 16, color: AppColors.foreground)),
              Switch(
                value: _enabled,
                onChanged: (v) {
                  _equalizer!.setEnabled(v);
                  setState(() => _enabled = v);
                },
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Presets
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final name = presets.keys.elementAt(index);
              final isActive = _activePreset == name;
              return GestureDetector(
                onTap: _enabled ? () => _applyPreset(name) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? Colors.white
                          : _enabled
                              ? AppColors.foreground
                              : AppColors.mutedForeground,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Band sliders
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _params!.bands.map((band) {
                return Expanded(child: _buildBandSlider(band));
              }).toList(),
            ),
          ),
        ),
        // Reset button
        Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _enabled
                ? () {
                    for (final band in _params!.bands) {
                      band.setGain(0);
                    }
                    setState(() => _activePreset = l10n.equalizerPresetFlat);
                  }
                : null,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _enabled ? AppColors.card : AppColors.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  l10n.equalizerReset,
                  style: TextStyle(
                    fontSize: 15,
                    color: _enabled
                        ? AppColors.foreground
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBandSlider(AndroidEqualizerBand band) {
    final minDb = _params!.minDecibels.toDouble();
    final maxDb = _params!.maxDecibels.toDouble();
    final gainText = band.gain >= 0
        ? '+${band.gain.toStringAsFixed(1)}'
        : band.gain.toStringAsFixed(1);

    return Column(
      children: [
        // Gain value
        Text(
          gainText,
          style: TextStyle(
            fontSize: 11,
            color: _enabled ? AppColors.foreground : AppColors.mutedForeground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        // dB labels + slider
        Expanded(
          child: Column(
            children: [
              Text('${maxDb.round()}',
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.mutedForeground)),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12),
                      activeTrackColor:
                          _enabled ? AppColors.primary : AppColors.mutedForeground,
                      inactiveTrackColor: AppColors.border,
                      thumbColor:
                          _enabled ? AppColors.primary : AppColors.mutedForeground,
                      overlayColor: AppColors.primary.withValues(alpha: 0.15),
                      disabledActiveTrackColor: AppColors.mutedForeground,
                      disabledInactiveTrackColor: AppColors.border,
                      disabledThumbColor: AppColors.mutedForeground,
                    ),
                    child: Slider(
                      value: band.gain,
                      min: minDb,
                      max: maxDb,
                      onChanged: _enabled
                          ? (v) {
                              band.setGain(v);
                              setState(() => _activePreset = null);
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              Text('${minDb.round()}',
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.mutedForeground)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Frequency label
        Text(
          _formatFreq(band.centerFrequency),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _enabled ? AppColors.foreground : AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
