import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Reusable child photo with a FIXED 4:6 portrait frame (like the web
/// TinyCare `ChildPhoto` component).
///
/// Source priority: `photo_url` → `photo` → `image_url` → [src] → placeholder.
///
/// Rules enforced here (shared by every page — never use initial-letter
/// avatars for children):
/// - fixed frame: width = [width], height = [height] ?? width * 1.5  (4:6)
/// - `object-fit: cover` + `object-position: center` crop (never stretched,
///   never `contain` with empty space)
/// - rounded corners (not a circle), no text initials.
class ChildPhoto extends StatelessWidget {
  const ChildPhoto({
    super.key,
    this.child,
    this.src,
    this.width = 48,
    this.height,
    this.radius = 12,
    this.alt,
    this.border,
    this.backgroundColor,
  });

  /// A child object map (from the API) that may contain photo_url/photo/image_url.
  final Map<String, dynamic>? child;

  /// Direct image source, used when [child] carries no photo data.
  final String? src;

  /// Fixed frame width; height defaults to `width * 1.5` (4:6 ratio).
  final double width;

  /// Optional explicit height (overrides the 4:6 default).
  final double? height;

  /// Corner radius of the frame.
  final double radius;

  final String? alt;

  final BoxBorder? border;

  final Color? backgroundColor;

  double get _height => height ?? width * 1.5;

  String? get _source {
    final photoUrl = child?['photo_url'] as String?;
    final photo = child?['photo'] as String?;
    final imageUrl = child?['image_url'] as String?;
    final raw = photoUrl?.isNotEmpty == true
        ? photoUrl
        : photo?.isNotEmpty == true
            ? photo
            : imageUrl?.isNotEmpty == true
                ? imageUrl
                : src?.isNotEmpty == true
                    ? src
                    : null;
    if (raw == null) return null;
    return ApiService.resolveMediaUrl(raw);
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    final frame = Container(
      width: width,
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor ?? ThemeHelper.bgAlt(context),
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: source == null
          ? const _PhotoPlaceholder()
          : CachedNetworkImage(
              imageUrl: source,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              placeholder: (_, _) => const _PhotoPlaceholder(subtle: true),
              errorWidget: (_, _, _) => const _PhotoPlaceholder(),
            ),
    );
    return frame;
  }
}

/// Soft placeholder shown while loading or when no photo exists.
/// Uses an icon (child silhouette) — NEVER an initial letter.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.subtle = false});

  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final muted = ThemeHelper.textMuted(context);
    return Container(
      color: Colors.transparent,
      child: Center(
        child: subtle
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : Icon(Icons.child_care, size: widthIconSize, color: muted.withValues(alpha: 0.6)),
      ),
    );
  }

  double get widthIconSize => 28;
}