import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imagePath;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 38,
    this.imagePath,
    this.showEditBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'G';

    // Generate a consistent gradient based on the first character
    final List<Color> gradientColors = _getGradientColors(initial);

    final bool isBase64 = imagePath != null && imagePath!.startsWith('data:image/');

    final bool hasCustomImage = imagePath != null &&
        imagePath!.isNotEmpty &&
        (isBase64 || kIsWeb || File(imagePath!).existsSync());

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32), // squircle shape
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      alignment: Alignment.center,
      child: hasCustomImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.32 - 1.5),
              child: isBase64
                  ? Image.memory(
                      base64Decode(imagePath!.split(',').last),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          initial,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    )
                  : kIsWeb
                      ? Image.network(
                          imagePath!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              initial,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size * 0.44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(imagePath!),
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              initial,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size * 0.44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                        ),
            )
          : Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.44,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
    );


    if (showEditBadge) {
      final badgeSize = size * 0.36;
      final iconSize = badgeSize * 0.6;
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: -size * 0.03,
            bottom: -size * 0.03,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: avatarWidget,
        ),
      );
    }
    return avatarWidget;
  }

  List<Color> _getGradientColors(String char) {
    final int code = char.codeUnitAt(0);
    // 5 curated vibrant gradients
    switch (code % 5) {
      case 0:
        return [const Color(0xFF10B981), const Color(0xFF047857)]; // Emerald
      case 1:
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]; // Blue
      case 2:
        return [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]; // Purple
      case 3:
        return [const Color(0xFFEC4899), const Color(0xFFBE185D)]; // Pink
      default:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)]; // Amber
    }
  }
}
