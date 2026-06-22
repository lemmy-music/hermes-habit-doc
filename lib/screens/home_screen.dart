import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/widget_manager_provider.dart';

// ─── HomeScreen (Widget-Manager) ─────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => WidgetManagerProvider(ctx.read<AppDatabase>()),
      child: const _WidgetManagerView(),
    );
  }
}

class _WidgetManagerView extends StatelessWidget {
  const _WidgetManagerView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<WidgetManagerProvider>().refresh(),
          ),
        ],
      ),
      body: const _WidgetList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Widget'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    // Capture the provider reference BEFORE await
    final provider = context.read<WidgetManagerProvider>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => _WidgetFormDialog(
        provider: provider,
      ),
    );
  }
}

// ─── Widget List ─────────────────────────────────────────────────────────────

class _WidgetList extends StatelessWidget {
  const _WidgetList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WidgetManagerProvider>();

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
            ElevatedButton(
              onPressed: provider.refresh,
              child: const Text('Retry'),
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
            Icon(Icons.widgets_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No widgets yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Tap "Create Widget" to get started.'),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: provider.widgets.length,
          itemBuilder: (ctx, i) => _WidgetCard(widget: provider.widgets[i]),
        );
      },
    );
  }
}

// ─── Widget Card ─────────────────────────────────────────────────────────────

class _WidgetCard extends StatelessWidget {
  const _WidgetCard({required this.widget});

  final CustomWidget widget;

  IconData _iconForType(String type) {
    switch (type) {
      case 'slider':
        return Icons.linear_scale;
      case 'checkbox':
        return Icons.check_box_outlined;
      default:
        return Icons.pin_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<WidgetManagerProvider>();
    final fieldType = FieldType.fromDb(widget.fieldType);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditDialog(context, provider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconForType(widget.fieldType),
                      color: colorScheme.primary, size: 28),
                  const Spacer(),
                  _CardMenu(
                    onEdit: () => _showEditDialog(context, provider),
                    onDelete: () => _confirmDelete(context, provider),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Chip(
                padding: EdgeInsets.zero,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                label: Text(fieldType.label,
                    style: const TextStyle(fontSize: 11)),
                backgroundColor: colorScheme.secondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetManagerProvider provider) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _WidgetFormDialog(
        provider: provider,
        existingWidget: widget,
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetManagerProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Widget?'),
        content: Text('Are you sure you want to delete "${widget.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteWidget(widget.id);
    }
  }
}

// ─── Card popup menu ─────────────────────────────────────────────────────────

class _CardMenu extends StatelessWidget {
  const _CardMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 20),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
    );
  }
}

// ─── Create / Edit Dialog ─────────────────────────────────────────────────────

class _WidgetFormDialog extends StatefulWidget {
  const _WidgetFormDialog({
    required this.provider,
    this.existingWidget,
  });

  final WidgetManagerProvider provider;
  final CustomWidget? existingWidget;

  @override
  State<_WidgetFormDialog> createState() => _WidgetFormDialogState();
}

class _WidgetFormDialogState extends State<_WidgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late FieldType _selectedType;
  bool _saving = false;

  bool get _isEditing => widget.existingWidget != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingWidget?.name ?? '');
    _selectedType = widget.existingWidget != null
        ? FieldType.fromDb(widget.existingWidget!.fieldType)
        : FieldType.number;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Widget' : 'Create Widget'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Widget Name',
                  hintText: 'e.g. Sleep Hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field type dropdown
              DropdownButtonFormField<FieldType>(
                // ignore: deprecated_member_use
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Field Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: FieldType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(_iconForType(t), size: 18),
                              const SizedBox(width: 8),
                              Text(t.label),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  IconData _iconForType(FieldType t) {
    switch (t) {
      case FieldType.slider:
        return Icons.linear_scale;
      case FieldType.checkbox:
        return Icons.check_box_outlined;
      default:
        return Icons.pin_outlined;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      if (_isEditing) {
        await widget.provider
            .editWidget(widget.existingWidget!.id, name, _selectedType);
      } else {
        await widget.provider.createWidget(name, _selectedType);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
