import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/playback_state.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Settings', style: AppTextStyles.heading2),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        children: [
          // Theme
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: 'Theme',
                subtitle: 'Dark',
                onTap: () {},
              ),
            ],
          ),

          // Playback
          _SettingsSection(
            title: 'Playback',
            children: [
              _SettingsTile(
                icon: Icons.high_quality_rounded,
                title: 'Audio Quality',
                subtitle: playback.quality.label,
                onTap: () => _showQualityPicker(context, ref),
              ),
              _SettingsTile(
                icon: Icons.skip_next_rounded,
                title: 'Gapless Playback',
                subtitle: 'Seamless transitions between songs',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.equalizer_rounded,
                title: 'Equalizer',
                subtitle: 'Adjust audio settings',
                onTap: () {},
              ),
            ],
          ),

          // Notifications
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Playback Notifications',
                subtitle: 'Show media controls in notification',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),

          // Storage
          _SettingsSection(
            title: 'Storage & Cache',
            children: [
              _SettingsTile(
                icon: Icons.cached_rounded,
                title: 'Image Cache',
                subtitle: 'Cached images for faster loading',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.storage_rounded,
                title: 'Clear Local Data',
                subtitle: 'Remove all locally stored data',
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),

          // About
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About ${AppConstants.appName}',
                subtitle: 'Version ${AppConstants.appVersion}',
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.code_rounded,
                title: 'Open Source Licenses',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App tagline
          Center(
            child: Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appTagline,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Text(
                  'v${AppConstants.appVersion}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showQualityPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(playbackProvider).quality;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Audio Quality', style: AppTextStyles.heading3),
            ),
            ...AudioQuality.values.map((q) => ListTile(
                  leading: Icon(
                    current == q
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: current == q
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                  title: Text(q.label, style: AppTextStyles.bodyMedium),
                  onTap: () {
                    ref.read(playbackProvider.notifier).setQuality(q);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Data', style: AppTextStyles.heading3),
        content: Text(
          'This will remove all locally stored data including playlists, liked songs, and recently played. This action cannot be undone.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Clear', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.music_note_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(AppConstants.appName, style: AppTextStyles.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appTagline,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A modern music player that lets you search and play music from YouTube using the official YouTube Data API and embedded player.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Version ${AppConstants.appVersion}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 24),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.bodySmall)
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
