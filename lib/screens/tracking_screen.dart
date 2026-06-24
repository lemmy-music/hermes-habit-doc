import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/tracking_provider.dart';
import '../providers/widget_manager_provider.dart';

// ─── TrackingScreen ───────────────────────────────────────────────────────────

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TrackingProvider(ctx.read<AppDatabase>()),
      child: const _TrackingView(),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Events'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<TrackingProvider>().refresh(),
          ),
        ],
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, TrackingProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.read<TrackingProvider>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.widgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No widgets to track.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Create widgets in the Widgets tab first.'),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return _TrackingGrid(
              widgets: provider.widgets,
              columns: constraints.maxWidth >= 900 ? 3 : 2);
        }
        return _TrackingList(widgets: provider.widgets);
      },
    );
  }
}

// ─── Grid (tablet / web) ──────────────────────────────────────────────────────

class _TrackingGrid extends StatelessWidget {
  const _TrackingGrid({required this.widgets, required this.columns});

  final List<CustomWidget> widgets;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: widgets.length,
      itemBuilder: (ctx, i) => _TrackingCard(widget: widgets[i]),
    );
  }
}

// ─── List (mobile) ────────────────────────────────────────────────────────────

class _TrackingList extends StatelessWidget {
  const _TrackingList({required this.widgets});

  final List<CustomWidget> widgets;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widgets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) => _TrackingCard(widget: widgets[i]),
    );
  }
}

// ─── Tracking Card ────────────────────────────────────────────────────────────

class _TrackingCard extends StatefulWidget {
  const _TrackingCard({required this.widget});

  final CustomWidget widget;

  @override
  State<_TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends State<_TrackingCard> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Color _colorForType(BuildContext context, FieldType ft) {
    final cs = Theme.of(context).colorScheme;
    switch (ft) {
      case FieldType.slider:
        return cs.tertiary;
      case FieldType.checkbox:
        return cs.secondary;
      case FieldType.duration:
        return cs.primaryContainer.withValues(alpha: 1.0);
      case FieldType.time:
        return cs.tertiaryContainer.withValues(alpha: 1.0);
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();
    final state = provider.stateFor(widget.widget.id);
    if (state == null) return const SizedBox.shrink();

    final fieldType = FieldType.fromDb(widget.widget.fieldType);
    final accentColor = _colorForType(context, fieldType);
    final cs = Theme.of(context).colorScheme;

    // For time type, we don't show the timestamp picker (auto-set)
    final showTimestampPicker = fieldType != FieldType.time;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      fieldType.icon,
                      color: cs.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.widget.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── Dynamic Input Field ──────────────────────────────────────
              _buildInputField(context, provider, state, fieldType),

              const SizedBox(height: 16),

              // ── Timestamp Picker (not shown for time type) ───────────────
              if (showTimestampPicker) ...[
                _TimestampPicker(
                  timestamp: state.selectedTimestamp,
                  onChanged: (dt) =>
                      context.read<TrackingProvider>().setTimestamp(widget.widget.id, dt),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // For time type, show auto-set timestamp info
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Timestamp: today at ${state.timeValue.isNotEmpty ? state.timeValue : "--:--"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Error message ────────────────────────────────────────────
              if (state.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.error!,
                    style:
                        TextStyle(color: cs.onErrorContainer, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Save Button ──────────────────────────────────────────────
              FilledButton.icon(
                onPressed: state.saving ? null : () => _saveEvent(context),
                icon: state.saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_alt_outlined),
                label: Text(state.saving ? 'Saving…' : 'Save Event'),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    TrackingProvider provider,
    WidgetTrackingState state,
    FieldType fieldType,
  ) {
    final widgetId = widget.widget.id;

    switch (fieldType) {
      case FieldType.number:
        // Sync controller text without disrupting cursor when driven from outside
        if (_numberController.text != state.numberValue) {
          _numberController.value = _numberController.value.copyWith(
            text: state.numberValue,
            selection:
                TextSelection.collapsed(offset: state.numberValue.length),
          );
        }
        return TextFormField(
          controller: _numberController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Value',
            hintText: 'Enter a number',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.numbers),
            suffixIcon: state.numberValue.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      provider.setNumberValue(widgetId, '');
                      _numberController.clear();
                    },
                  )
                : null,
          ),
          onChanged: (v) => provider.setNumberValue(widgetId, v),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (double.tryParse(v.trim()) == null) return 'Must be a number';
            return null;
          },
        );

      case FieldType.slider:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Value', style: Theme.of(context).textTheme.bodyMedium),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.sliderValue.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('0', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: state.sliderValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: state.sliderValue.toStringAsFixed(0),
                    onChanged: (v) => provider.setSliderValue(widgetId, v),
                  ),
                ),
                const Text('100', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        );

      case FieldType.checkbox:
        return CheckboxListTile(
          value: state.checkboxValue,
          onChanged: (v) =>
              provider.setCheckboxValue(widgetId, v ?? false),
          title: Text(state.checkboxValue ? 'Yes / Done' : 'No / Not done'),
          subtitle: const Text('Tap to toggle'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        );

      case FieldType.duration:
        return _DurationInput(
          hours: state.durationHours,
          minutes: state.durationMinutes,
          hoursController: _hoursController,
          minutesController: _minutesController,
          onHoursChanged: (h) => provider.setDurationHours(widgetId, h),
          onMinutesChanged: (m) => provider.setDurationMinutes(widgetId, m),
        );

      case FieldType.time:
        return _TimeInput(
          value: state.timeValue,
          onChanged: (hhmm) => provider.setTimeValue(widgetId, hhmm),
        );
    }
  }

  Future<void> _saveEvent(BuildContext context) async {
    // Validate number fields via Form
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TrackingProvider>();
    final widgetId = widget.widget.id;
    final widgetName = widget.widget.name;

    final error = await provider.saveEvent(widgetId);

    if (!mounted) return;

    if (error == null) {
      // Reset controllers to match provider reset
      _numberController.clear();
      _hoursController.clear();
      _minutesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Event saved for "$widgetName"')),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── Duration Input ───────────────────────────────────────────────────────────

class _DurationInput extends StatelessWidget {
  const _DurationInput({
    required this.hours,
    required this.minutes,
    required this.hoursController,
    required this.minutesController,
    required this.onHoursChanged,
    required this.onMinutesChanged,
  });

  final int hours;
  final int minutes;
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;

  @override
  Widget build(BuildContext context) {
    // Keep controllers in sync with state
    final hText = hours > 0 ? hours.toString() : '';
    if (hoursController.text != hText) {
      hoursController.value = hoursController.value.copyWith(
        text: hText,
        selection: TextSelection.collapsed(offset: hText.length),
      );
    }
    final mText = minutes > 0 ? minutes.toString() : '';
    if (minutesController.text != mText) {
      minutesController.value = minutesController.value.copyWith(
        text: mText,
        selection: TextSelection.collapsed(offset: mText.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.hourglass_empty),
                ),
                onChanged: (v) {
                  final val = int.tryParse(v) ?? 0;
                  onHoursChanged(val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                onChanged: (v) {
                  var val = int.tryParse(v) ?? 0;
                  if (val > 59) val = 59;
                  onMinutesChanged(val);
                },
                validator: (v) {
                  final val = int.tryParse(v ?? '') ?? 0;
                  if (val < 0 || val > 59) return '0–59';
                  return null;
                },
              ),
            ),
          ],
        ),
        if (hours > 0 || minutes > 0) ...[
          const SizedBox(height: 8),
          Text(
            '= ${hours}h ${minutes}min',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ],
    );
  }
}

// ─── Time Input ───────────────────────────────────────────────────────────────

class _TimeInput extends StatelessWidget {
  const _TimeInput({
    required this.value,
    required this.onChanged,
  });

  final String value; // "HH:mm" or empty
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : 'Select time…',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: value.isNotEmpty ? null : cs.outline,
                    ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: cs.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay? initial;
    if (value.isNotEmpty) {
      final parts = value.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      initial = TimeOfDay(hour: h, minute: m);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
      helpText: 'Select time',
    );

    if (picked != null) {
      final hhmm =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(hhmm);
    }
  }
}

// ─── Timestamp Picker ─────────────────────────────────────────────────────────

class _TimestampPicker extends StatelessWidget {
  const _TimestampPicker({
    required this.timestamp,
    required this.onChanged,
  });

  final DateTime timestamp;
  final ValueChanged<DateTime> onChanged;

  static final _dateFormat = DateFormat('EEE, d MMM y');
  static final _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isToday = _isToday(timestamp);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : _dateFormat.format(timestamp),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  isToday
                      ? '${_dateFormat.format(timestamp)}, ${_timeFormat.format(timestamp)}'
                      : _timeFormat.format(timestamp),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _pickDateTime(context),
            icon: const Icon(Icons.edit_calendar_outlined, size: 16),
            label: const Text('Change'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: timestamp,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Select event date',
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(timestamp),
      helpText: 'Select event time',
    );
    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    onChanged(combined);
  }
}
