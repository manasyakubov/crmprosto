import 'package:flutter/material.dart';

import '../models.dart';

class AppColors {
  static const accent = Color(0xFF2B3BC0);
  static const accentSoft = Color(0xFFE9EBF8);
  static const ink = Color(0xFF16181D);
  static const muted = Color(0xFF555B66);
  static const line = Color(0xFFE4E6EA);
  static const surface = Color(0xFFF4F5F7);
  static const whatsapp = Color(0xFF1A7F45);
  static const instagram = Color(0xFFB0306F);

  static (Color bg, Color fg) status(ClientStatus s) => switch (s) {
        ClientStatus.newLead => (accentSoft, const Color(0xFF1E2A8C)),
        ClientStatus.inWork => (const Color(0xFFFFF1DC), const Color(0xFF7A4A00)),
        ClientStatus.bought => (const Color(0xFFE1F3E8), const Color(0xFF1D6B3C)),
        ClientStatus.declined => (const Color(0xFFF1F2F4), const Color(0xFF3A3F48)),
      };
}

ThemeData buildTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent, primary: AppColors.accent, surface: Colors.white),
    scaffoldBackgroundColor: AppColors.surface,
    dividerColor: AppColors.line,
    useMaterial3: true,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD5D8DE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD5D8DE))),
    ),
  );
}

class ChannelBadge extends StatelessWidget {
  const ChannelBadge(this.channel, {super.key});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: channel == Channel.whatsapp ? AppColors.whatsapp : AppColors.instagram,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(channel.short, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final ClientStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.status(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(status.title, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 44, this.channel});

  final String initials;
  final double size;
  final Channel? channel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: const Color(0xFFE9EBEF),
            child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3A3F48))),
          ),
          if (channel != null) Positioned(right: -4, bottom: -2, child: ChannelBadge(channel!)),
        ],
      ),
    );
  }
}

class ProductPhoto extends StatelessWidget {
  const ProductPhoto(this.product, {super.key, this.size = 64});

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: const Color(0xFFE9EBEF),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Color(0xFF8A909B)),
    );
    final url = product.photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.startsWith('http')
          ? Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
          : placeholder,
    );
  }
}
