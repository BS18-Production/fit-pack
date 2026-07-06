import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';

/// Açık Veri Kaynakları / Atıf (C-6, docs/11 + docs/16 §6).
/// OFF ODbL atfı yasal zorunluluk; diğerleri teşekkür + şeffaflık.
class AttributionScreen extends StatelessWidget {
  const AttributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAttribution)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          Text(l.attribIntro,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          AppSpacing.vGapLg,
          _SourceCard(
            name: 'Open Food Facts',
            license: 'Open Database License (ODbL)',
            description: l.attribOffDesc,
            url: 'https://world.openfoodfacts.org',
          ),
          _SourceCard(
            name: 'free-exercise-db',
            license: 'Public Domain (Unlicense)',
            description: l.attribFedDesc,
            url: 'https://github.com/yuhonas/free-exercise-db',
          ),
          _SourceCard(
            name: 'muscle_selector',
            license: 'MIT',
            description: l.attribMuscleDesc,
            url: 'https://pub.dev/packages/muscle_selector',
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String name;
  final String license;
  final String description;
  final String url;

  const _SourceCard({
    required this.name,
    required this.license,
    required this.description,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name, style: context.texts.titleSmall),
                  ),
                  Icon(Icons.open_in_new_rounded,
                      size: AppIconSize.sm, color: c.onSurfaceVariant),
                ],
              ),
              AppSpacing.vGapXs,
              Text(description,
                  style: context.texts.bodySmall
                      ?.copyWith(color: c.onSurfaceVariant)),
              AppSpacing.vGapSm,
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(
                  l.attribLicense(license),
                  style: context.texts.labelSmall
                      ?.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
