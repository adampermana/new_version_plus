import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({
    required this.source,
    this.colorAsset,
    super.key,
    this.isCircle = false,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorBuilder,
    this.width,
    this.height,
    this.cacheHeight,
    this.cacheWidth,
  });

  final String source;
  final Color? colorAsset;
  final bool isCircle;
  final BorderRadius? borderRadius;

  final Widget Function(BuildContext context, String error, dynamic stackrace)?
      errorBuilder;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheHeight;
  final int? cacheWidth;

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (source.toLowerCase().startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        width: width,
        height: height,
        memCacheHeight: cacheHeight,
        memCacheWidth: cacheWidth,
        color: colorAsset,
        progressIndicatorBuilder: (context, url, progress) => Center(
          child: SizedBox(
            height: 32,
            child: CircularProgressIndicator(
              value: progress.progress,
            ),
          ),
        ),
        errorWidget:
            errorBuilder ?? (context, e, s) => _buildErrorWidget(context),
      );
    } else if (source.toLowerCase().startsWith('assets')) {
      imageWidget = Image.asset(
        source,
        fit: fit,
        width: width,
        height: height,
        cacheHeight: cacheHeight,
        cacheWidth: cacheWidth,
        color: colorAsset,
        errorBuilder: (context, e, s) => _buildErrorWidget(context),
      );
    } else {
      imageWidget = Image.file(
        File(source),
        fit: fit,
        width: width,
        height: height,
        cacheHeight: cacheHeight,
        cacheWidth: cacheWidth,
        color: colorAsset,
        errorBuilder: (context, e, s) => _buildErrorWidget(context),
      );
    }

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;

    // if (isCircle) {
    //   return ClipOval(
    //     child: imageWidget,
    //   );
    // } else {
    //   return imageWidget;
    // }
  }
}
