import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../providers/theme_provider.dart';
import '../services/data_port_service.dart';

// ─── SettingsButton ──────────────────────────────────────────────────────────
// Central settings entry point (gear icon) shown in every screen's AppBar.
// Opens a bottom sheet with Dark-Mode toggle, Export and Import.

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, this.onImportComplete});

  /// Called after a successful import so the host screen can refresh its data.
  final VoidCallback? onImportComplete;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () => _openSettings(context),
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetCtx) => _SettingsSheet(onImportComplete: onImportComplete),
    );
  }
}

// ─── Settings Sheet ──────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({this.onImportComplete});

  final VoidCallback? onImportComplete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.effectivelyDark(
        MediaQuery.of(context).platformBrightness);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Settings',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: cs.primary,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              isDark
                  ? 'Dark color scheme active'
                  : 'Light color scheme active',
            ),
            value: isDark,
            onChanged: (value) => themeProvider.setDark(value),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range, color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Date format',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<DateFormatPref>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: DateFormatPref.german,
                      label: Text('DE (TT.MM.)'),
                    ),
                    ButtonSegment(
                      value: DateFormatPref.us,
                      label: Text('US (MM/DD)'),
                    ),
                  ],
                  selected: {themeProvider.dateFormat},
                  onSelectionChanged: (selection) =>
                      themeProvider.setDateFormat(selection.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Time format',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<TimeFormatPref>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: TimeFormatPref.h24,
                      label: Text('24h'),
                    ),
                    ButtonSegment(
                      value: TimeFormatPref.h12,
                      label: Text('12h (AM/PM)'),
                    ),
                  ],
                  selected: {themeProvider.timeFormat},
                  onSelectionChanged: (selection) =>
                      themeProvider.setTimeFormat(selection.first),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.upload_file, color: cs.primary),
            title: const Text('Export (JSON)'),
            subtitle: const Text('Save all widgets & events to a file'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: Icon(Icons.download_for_offline, color: cs.primary),
            title: const Text('Import (JSON)'),
            subtitle: const Text('Import data from an export file'),
            onTap: () => _importData(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Export ──────────────────────────────────────────────────────────────

  Future<void> _exportData(BuildContext context) async {
    final db = context.read<AppDatabase>();
    final service = DataPortService(db);

    // Show loading indicator.
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Exporting…'),
          ],
        ),
        duration: Duration(seconds: 60),
      ),
    );

    final error = await service.exportData();
    messenger.hideCurrentSnackBar();

    if (error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Export complete!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ─── Import ──────────────────────────────────────────────────────────────

  Future<void> _importData(BuildContext context) async {
    final db = context.read<AppDatabase>();
    final service = DataPortService(db);

    // 1. Pick & parse file.
    Map<String, dynamic>? parsed;
    try {
      parsed = await service.pickAndParseJson();
    } on FormatException catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Invalid file', e.message);
      }
      return;
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error', e.toString());
      }
      return;
    }

    if (parsed == null) return; // user cancelled

    // 2. Ask overwrite or merge.
    if (!context.mounted) return;
    final choice = await _showImportModeDialog(context);
    if (choice == null) return; // cancelled

    final overwrite = choice == _ImportMode.overwrite;

    // 3. Confirm if overwriting.
    if (overwrite && context.mounted) {
      final confirmed = await _showOverwriteConfirm(context);
      if (confirmed != true) return;
    }

    // 4. Run import.
    if (!context.mounted) return;
    final result = await service.importData(parsed, overwrite: overwrite);

    if (!context.mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Imported ${result.widgetsAdded} widget(s) '
            'and ${result.eventsAdded} event(s).',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      onImportComplete?.call();
    } else {
      _showErrorDialog(context, 'Import failed', result.error ?? 'Unknown error');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<_ImportMode?> _showImportModeDialog(BuildContext context) {
    return showDialog<_ImportMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Mode'),
        content: const Text(
          'How should the imported data be handled?\n\n'
          '• Add (Merge): keeps existing data and adds new entries.\n'
          '• Overwrite: deletes ALL current data before importing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, _ImportMode.merge),
            child: const Text('Add (Merge)'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, _ImportMode.overwrite),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showOverwriteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 40),
        title: const Text('Delete all data?'),
        content: const Text(
          'This will permanently delete ALL your current habits and events '
          'before importing. This action cannot be undone.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete & Import'),
          ),
        ],
      ),
    );
  }
}

enum _ImportMode { merge, overwrite }
