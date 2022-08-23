import 'package:flutter/material.dart';

class UserIcon extends StatelessWidget {
  const UserIcon({
    Key? key,
    this.size = 48,
    required this.avatar,
    this.borderWidth = 0.0,
    this.borderColor = Colors.white,
    this.defaultAvatar = defaultAvatarUrl,
  }) : super(key: key);

  static const defaultAvatarUrl = 'https://avatar-management--avatars.us-west-2.prod.public.atl-paas.net/';

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
          child: Image.network(avatar ?? defaultAvatar, height: iconSize, width: iconSize),
        ),
      );
}
