import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/deep_links/app_deep_links.dart';

/// Sample links. Tap one to open it as if it came from another app, or share
/// a web link and tap it there.
class DeepLinkSamples extends StatelessWidget {
  const DeepLinkSamples({super.key});

  static const _links = [
    'https://app.example.com/products/42',
    'https://app.example.com/products',
    'https://app.example.com/p/1',
    'https://app.example.com/unknown',
    'myapp://products/42',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final link in _links)
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(link),
            onTap: () => deepLinks.handle(Uri.parse(link)),
            // WhatsApp and most apps only make web links tappable.
            trailing: link.startsWith('https://')
                ? IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share),
                    onPressed: () =>
                        SharePlus.instance.share(ShareParams(text: link)),
                  )
                : null,
          ),
      ],
    );
  }
}
