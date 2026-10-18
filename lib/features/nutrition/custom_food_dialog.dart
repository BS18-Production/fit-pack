import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import 'food_labels.dart';

/// Custom food creator sonucu — porsiyon değerleri /100g'a çevrilir.
class CustomFood {
  final String name;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final double defaultGrams;
  final String? unitLabel; // null → birim yok (sadece gram)

  CustomFood({
    required this.name,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    required this.defaultGrams,
    required this.unitLabel,
  });
}

/// Kullanıcı kendi yemeğini girer. "Yediğin porsiyon" mantığı: toplam
/// gram + o porsiyonun toplam kcal/P/K/Y'si → /100g'a çevrilip kaydedilir
/// (tekrar kullanılabilir). Örn: "3 Yumurtalı Omlet" 220 g, 320 kcal...
class CustomFoodDialog extends StatefulWidget {
  final String? barcode;
  const CustomFoodDialog({super.key, this.barcode});

  @override
  State<CustomFoodDialog> createState() => CustomFoodDialogState();
}

class CustomFoodDialogState extends State<CustomFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();
  // Birim: "porsiyon" varsayılan (locale'e göre, ilk build'de atanır).
  // null → "birim yok" (sadece gram).
  String? _unit;
  bool _unitInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_unitInitialized) {
      _unitInitialized = true;
      _unit = AppL10n.of(context).unitPortion;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _grams, _kcal, _protein, _carb, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final g = _num(_grams);
    final f = 100 / g; // porsiyon → /100g
    Navigator.pop(
      context,
      CustomFood(
        name: _name.text.trim(),
        kcalPer100g: _num(_kcal) * f,
        proteinPer100g: _num(_protein) * f,
        carbPer100g: _num(_carb) * f,
        fatPer100g: _num(_fat) * f,
        defaultGrams: g,
        unitLabel: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return AlertDialog(
      title: Text(l.nutritionCustomTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.barcode != null) SelectableText(
                '${l.expBarcode}: ${widget.barcode}'),
              Text(
                l.nutritionCustomHelp,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapMd,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.nutritionFoodName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.commonEnterName : null,
              ),
              AppSpacing.vGapMd,
              DropdownButtonFormField<String?>(
                initialValue: _unit,
                decoration: InputDecoration(labelText: l.nutritionUnit),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l.nutritionNoUnitOption),
                  ),
                  ...unitOptionsWith(l, _unit).map(
                    (u) => DropdownMenuItem(
                      value: u,
                      child: Text(l.nutritionOneUnit(u)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _unit = v),
              ),
              AppSpacing.vGapMd,
              _NumberField(
                controller: _grams,
                label: _unit == null
                    ? l.nutritionPortionGrams
                    : l.nutritionUnitGramsQuestion(_unit!),
                requiredField: true,
              ),
              AppSpacing.vGapMd,
              _NumberField(
                controller: _kcal,
                label: l.nutritionTotalKcal,
                requiredField: true,
              ),
              AppSpacing.vGapMd,
              _NumberField(
                controller: _protein,
                label: '${l.macroProtein} (g)',
              ),
              AppSpacing.vGapMd,
              _NumberField(controller: _carb, label: '${l.macroCarbs} (g)'),
              AppSpacing.vGapMd,
              _NumberField(controller: _fat, label: '${l.macroFat} (g)'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField;

  const _NumberField({
    required this.controller,
    required this.label,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label),
      validator: (raw) {
        final l = AppL10n.of(context);
        final t = (raw ?? '').trim().replaceAll(',', '.');
        if (t.isEmpty) return requiredField ? l.commonRequired : null;
        final v = double.tryParse(t);
        if (v == null) return l.commonInvalidNumber;
        if (requiredField && v <= 0) return l.commonMustBePositive;
        if (v < 0) return l.commonNotNegative;
        return null;
      },
    );
  }
}
