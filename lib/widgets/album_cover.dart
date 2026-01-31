import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AlbumCover extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final int gradientIndex;
  final String? label;
  final String? subtitle;
  final bool isCircle;
  final IconData? icon;
  final String? imagePath;
  final Uint8List? imageData;

  const AlbumCover({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.gradientIndex = 0,
    this.label,
    this.subtitle,
    this.isCircle = false,
    this.icon,
    this.imagePath,
    this.imageData,
  });

  static const _gradients = [
    [Color(0xFFFC3E4E), Color(0xFFFF7B54)],
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    [Color(0xFFFCCB90), Color(0xFFD57EEB)],
    [Color(0xFF5EE7DF), Color(0xFFB490CA)],
    [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    [Color(0xFF89F7FE), Color(0xFF66A6FF)],
  ];

  @override
  Widget build(BuildContext context) {
    // If we have a real image, show it
    if (imageData != null) {
      return _buildImageCover(
        Image.memory(imageData!, fit: BoxFit.cover, width: width, height: height),
      );
    }
    if (imagePath != null && File(imagePath!).existsSync()) {
      return _buildImageCover(
        Image.file(File(imagePath!), fit: BoxFit.cover, width: width, height: height),
      );
    }

    // Fallback: gradient placeholder
    final colors = _gradients[gradientIndex % _gradients.length];
    final shape = isCircle ? BoxShape.circle : BoxShape.rectangle;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: (label != null || icon != null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, color: Colors.white.withValues(alpha: 0.9),
                        size: width * 0.3),
                  if (icon != null && label != null) const SizedBox(height: 6),
                  if (label != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        label!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.1 > 16 ? 16 : width * 0.1,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildImageCover(Widget image) {
    return ClipRRect(
      borderRadius: isCircle
          ? BorderRadius.circular(width / 2)
          : BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}
