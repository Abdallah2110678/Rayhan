import 'package:flutter/material.dart';

import '../core/utils/translator.dart';
import '../models/packaging_item.dart';
import '../state/packaging_controller.dart';
import '../widgets/collapsing_header_page.dart';
import '../widgets/page_header.dart';

class PackagingPage extends StatefulWidget {
  const PackagingPage({super.key, required this.packaging});

  final PackagingController packaging;

  @override
  State<PackagingPage> createState() => _PackagingPageState();
}

class _PackagingPageState extends State<PackagingPage> {
  Future<void> _openEditor([PackagingItem? item]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PackagingEditor(item: item),
    );

    if (result == null) return;

    if (item == null) {
      widget.packaging.addItem(
        result['sizeMl'] as double,
        result['quantity'] as int,
      );
    } else {
      widget.packaging.updateItem(
        item.id,
        sizeMl: result['sizeMl'] as double,
        quantity: result['quantity'] as int,
      );
    }
  }

  Future<void> _deleteItem(PackagingItem item) async {
    final sizeLabel = item.sizeMl % 1 == 0
        ? '${item.sizeMl.toInt()} ml'
        : '${item.sizeMl} ml';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translator.translate('delete_packaging')),
        content: Text(
          Translator.translate('delete_packaging_confirm', {'name': sizeLabel}),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Translator.translate('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Translator.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.packaging.removeItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.packaging,
      builder: (context, _) {
        final items = widget.packaging.items;
        final totalBottles = items.fold<int>(0, (sum, i) => sum + i.quantity);

        return CollapsingHeaderPage(
          header: PageHeader(
            title: Translator.translate('packaging_title'),
            subtitle: Translator.translate('packaging_subtitle'),
          ),
          between: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (items.isNotEmpty)
                _SummaryChip(
                  label: Translator.translate('total_bottles'),
                  value: '$totalBottles',
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: Text(Translator.translate('add_packaging')),
              ),
            ],
          ),
          betweenSpacing: 20,
          child: items.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _PackagingTile(
                      item: item,
                      onEdit: () => _openEditor(item),
                      onDelete: () => _deleteItem(item),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DDCF)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D403B),
            ),
      ),
    );
  }
}

class _PackagingTile extends StatelessWidget {
  const _PackagingTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final PackagingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isLow = item.quantity <= 5;
    final isEmpty = item.quantity == 0;

    Color quantityColor = const Color(0xFF1D403B);
    if (isEmpty) {
      quantityColor = Colors.red.shade700;
    } else if (isLow) {
      quantityColor = Colors.orange.shade700;
    }

    final sizeLabel = item.sizeMl % 1 == 0
        ? '${item.sizeMl.toInt()} ml'
        : '${item.sizeMl} ml';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEmpty
              ? Colors.red.shade200
              : isLow
                  ? Colors.orange.shade200
                  : const Color(0xFFE5DCCF),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.water_drop_outlined,
              color: isEmpty
                  ? Colors.red.shade400
                  : isLow
                      ? Colors.orange.shade400
                      : const Color(0xFF4A7C6F),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              sizeLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${item.quantity}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: quantityColor,
                    ),
              ),
              Text(
                Translator.translate('bottle_quantity'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9EB5AF),
                    ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            children: <Widget>[
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: Translator.translate('edit'),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: Translator.translate('delete'),
                color: Colors.red.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.water_drop_outlined,
            size: 56,
            color: Color(0xFFB8D0CA),
          ),
          const SizedBox(height: 16),
          Text(
            Translator.translate('no_packaging_yet'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A7C6F),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            Translator.translate('no_packaging_yet_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9EB5AF),
                ),
          ),
        ],
      ),
    );
  }
}

class _PackagingEditor extends StatefulWidget {
  const _PackagingEditor({this.item});

  final PackagingItem? item;

  @override
  State<_PackagingEditor> createState() => _PackagingEditorState();
}

class _PackagingEditorState extends State<_PackagingEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _sizeController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _sizeController = TextEditingController(
      text: widget.item == null
          ? ''
          : (widget.item!.sizeMl % 1 == 0
              ? widget.item!.sizeMl.toInt().toString()
              : widget.item!.sizeMl.toString()),
    );
    _quantityController = TextEditingController(
      text: widget.item == null ? '' : '${widget.item!.quantity}',
    );
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      'sizeMl': double.parse(_sizeController.text.trim()),
      'quantity': int.parse(_quantityController.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return AlertDialog(
      title: Text(
        Translator.translate(isEditing ? 'edit_packaging' : 'add_packaging'),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _sizeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: Translator.translate('bottle_size_ml'),
                suffixText: 'ml',
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return Translator.translate('field_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: Translator.translate('bottle_quantity'),
              ),
              validator: (v) {
                final parsed = int.tryParse((v ?? '').trim());
                if (parsed == null || parsed < 0) {
                  return Translator.translate('field_required');
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Translator.translate('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(Translator.translate('save')),
        ),
      ],
    );
  }
}
