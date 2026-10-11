import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Gizlilik politikası + aydınlatma metni (docs/41 P-1). Metin
/// `assets/legal/privacy_<dil>.md`'de; dil yoksa İngilizce. Rota yok — alt
/// sayfa (tam yükseklik) her yerden açılır: Ayarlar, giriş, rıza ekranı.
///
/// Basit biçim: `# ` başlık, `## ` alt başlık, `- ` madde, diğerleri paragraf.
Future<void> showPrivacyPolicy(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _PrivacyPolicyBody(
          lang: Localizations.localeOf(ctx).languageCode,
        ),
      ),
    );

/// Varlık yolu: desteklenen dil yoksa İngilizce.
String privacyAssetFor(String lang) =>
    'assets/legal/privacy_${lang == 'tr' ? 'tr' : 'en'}.md';

class _PrivacyPolicyBody extends StatelessWidget {
  final String lang;
  const _PrivacyPolicyBody({required this.lang});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(privacyAssetFor(lang)),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          children: [
            for (final line in snap.data!.split('\n')) _line(context, line),
          ],
        );
      },
    );
  }

  Widget _line(BuildContext context, String raw) {
    final line = raw.trimRight();
    final t = context.texts;
    if (line.isEmpty) return AppSpacing.vGapSm;
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(line.substring(2), style: t.titleLarge),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(line.substring(3), style: t.titleMedium),
      );
    }
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: t.bodyMedium),
            Expanded(child: Text(line.substring(2), style: t.bodyMedium)),
          ],
        ),
      );
    }
    return Text(line, style: t.bodyMedium);
  }
}
