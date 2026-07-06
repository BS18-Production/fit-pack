import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';

/// Profil + Ayarlar ekranlarının ortak yapı taşları (docs/16).
/// Ayarlar'daki özel widget'lar buraya çıkarıldı ki iki ekran da aynı
/// görsel dili kullansın — kopya yok, tek doğruluk kaynağı.

/// Tutarlı, sakin (Pro) ayar satırı — primary-tonlu ikon rozeti.
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// true → ikon/başlık hata renginde (yıkıcı aksiyonlar, örn. Hesabı Sil).
  final bool destructive;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        destructive ? context.colors.error : context.colors.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: AppRadius.brSm,
        ),
        child: Icon(icon, color: accent, size: AppIconSize.sm + 2),
      ),
      title: Text(title,
          style: destructive
              ? TextStyle(color: context.colors.error)
              : null),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          (value != null
              ? Text(value!,
                  style: context.texts.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600))
              : null),
    );
  }
}

/// Bölüm başlığı (BÜYÜK HARF, geniş letter-spacing).
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Basit tek-seçim listesi dialog'u. Seçilen değerin anahtarını döner.
Future<String?> pickOptionDialog(
  BuildContext context, {
  required String title,
  required List<(String, String)> options,
  required String? current,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        for (final (value, label) in options)
          ListTile(
            title: Text(label),
            trailing: value == current
                ? Icon(Icons.check_rounded, color: ctx.colors.primary)
                : null,
            onTap: () => Navigator.pop(ctx, value),
          ),
      ],
    ),
  );
}

/// Aralık-validasyonlu sayı düzenleme dialog'u. Geçerli değer ya da null döner.
Future<num?> showNumberEditDialog(
  BuildContext context, {
  required String title,
  required String unit,
  required num initial,
  required bool isInt,
  required num min,
  required num max,
}) {
  return showDialog<num>(
    context: context,
    builder: (_) => _NumberEditDialog(
      title: title,
      unit: unit,
      initial: initial,
      isInt: isInt,
      min: min,
      max: max,
    ),
  );
}

/// Controller'ı kendi State'inde tutar — dialog kapanış animasyonu
/// sırasında "disposed controller" hatasını önler.
class _NumberEditDialog extends StatefulWidget {
  final String title;
  final String unit;
  final num initial;
  final bool isInt;
  final num min;
  final num max;
  const _NumberEditDialog({
    required this.title,
    required this.unit,
    required this.initial,
    required this.isInt,
    required this.min,
    required this.max,
  });

  @override
  State<_NumberEditDialog> createState() => _NumberEditDialogState();
}

class _NumberEditDialogState extends State<_NumberEditDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppL10n.of(context);
    final v = widget.isInt
        ? int.tryParse(_controller.text.trim())
        : double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (v == null) {
      setState(() => _error = l.commonInvalidNumber);
      return;
    }
    if (v < widget.min || v > widget.max) {
      setState(() =>
          _error = l.commonRangeError('${widget.min}', '${widget.max}'));
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: !widget.isInt),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          suffixText: widget.unit,
          helperText: l.commonRangeHint('${widget.min}', '${widget.max}'),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
