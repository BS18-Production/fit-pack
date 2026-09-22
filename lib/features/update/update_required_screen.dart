import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_l10n.dart';
import '../../shared/widgets/gate_scaffold.dart';
import 'update_providers.dart';

/// Zorunlu güncelleme ekranı (docs/23 §3.2).
///
/// **Neden geçilemez.** Kapı yalnız sunucu açıkça "bu build artık
/// desteklenmiyor" dediğinde açılır; o noktada eski istemcinin yazmaları
/// sunucuda sessizce reddedilirdi. Kullanıcıyı uygulamanın içine alıp veri
/// kaybettirmektense açıkça durdurmak daha dürüst.
///
/// **Yereldeki veri güvende** — mesaj bunu söylüyor. Güncelleme kurulduğunda
/// kuyruk olduğu yerden devam eder.
class UpdateRequiredScreen extends ConsumerStatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  ConsumerState<UpdateRequiredScreen> createState() =>
      _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends ConsumerState<UpdateRequiredScreen> {
  bool _busy = false;

  /// Mağazayı açar. Açılamazsa (mağaza yok, emülatör) sessizce geçilir —
  /// kullanıcı elle de güncelleyebilir, hata diyaloğu bir şey çözmez.
  Future<void> _openStore() async {
    final uri = Uri.parse(
      Platform.isIOS
          ? 'https://apps.apple.com/app/id0000000000'
          : 'market://details?id=com.sametorhan.fit_pack',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Yoksay — aşağıdaki "tekrar kontrol et" yolu açık kalır.
    }
  }

  /// Kullanıcı mağazadan dönmüş olabilir → kapıyı yeniden değerlendir.
  Future<void> _recheck() async {
    setState(() => _busy = true);
    try {
      await ref.read(updateGateProvider).refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    // Sunucu kullanıcının dilini bilmiyor: metin varsa onu, yoksa
    // yerelleştirilmiş varsayılanı göster.
    final sunucuMesaji = ref.watch(updateGateProvider).state.message;
    return GateScaffold(
      icon: Icons.system_update_rounded,
      title: l.updateRequiredTitle,
      message: (sunucuMesaji != null && sunucuMesaji.trim().isNotEmpty)
          ? sunucuMesaji
          : l.updateRequiredBody,
      actions: [
        FilledButton(
          onPressed: _busy ? null : _openStore,
          child: Text(l.updateRequiredAction),
        ),
        TextButton(
          onPressed: _busy ? null : _recheck,
          child: Text(l.commonRetry),
        ),
      ],
    );
  }
}
