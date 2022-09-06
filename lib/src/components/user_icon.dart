import 'package:flutter/material.dart';

class UserIcon extends StatelessWidget {
  const UserIcon({
    Key? key,
    this.size = 48,
    required this.avatar,
    this.borderWidth = 0.0,
    this.borderColor = Colors.white,
    this.defaultAvatar = defaultAvatarAsset,
  }) : super(key: key);

  static const defaultAvatarAsset = 'assets/jira_placeholder.png';

  final String? avatar;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final String defaultAvatar;

  double get iconSize => size - borderWidth * 2;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(iconSize),
          child: FadeInImage.assetNetwork(
            placeholderErrorBuilder: (context, error, stackTrace) => Image.asset(defaultAvatarAsset),
            imageErrorBuilder: (context, error, stackTrace) => Image.asset(defaultAvatarAsset),
            image: avatar ?? defaultAvatar,
            placeholder: defaultAvatar,
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 150),
            height: iconSize,
            width: iconSize,
          ),
        ),
      );
}
