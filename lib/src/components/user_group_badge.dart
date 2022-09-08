import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/components/user_icon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserGroupBadge extends StatelessWidget {
  const UserGroupBadge({
    Key? key,
    required this.users,
    this.gap = 8.0,
    this.maxIcons = 3,
    this.circleSize = 44,
    this.borderWidth = 2,
    this.iconOverlap = 0.5,
  }) : super(key: key);

  final List<UserDetails> users;
  final double circleSize;
  final int maxIcons;

  /// Should be in range from 0 to 1
  final double iconOverlap;
  final double borderWidth;
  final double gap;

  int get iconsCount {
    final difference = users.length - maxIcons;
    // Don't show number of users left placeholder if just one lefr
    return difference <= 1 ? users.length : maxIcons;
  }

  Iterable<UserDetails> get usersWithIcons => users.getRange(0, iconsCount);
  double get iconsExtent => circleSize + circleSize * (iconsCount - 1) * iconOverlap;

  TextStyle get counterStyle => GoogleFonts.lato(
        color: Colors.white,
        fontSize: circleSize / 3,
        fontWeight: FontWeight.bold,
      );

  BoxDecoration get circleDecoration => BoxDecoration(
        border: Border.all(color: Colors.black, width: borderWidth),
        shape: BoxShape.circle,
        color: Colors.black38,
      );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: circleSize,
        maxWidth: iconsExtent + (iconsCount < users.length ? circleSize + gap : 0),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ...List.generate(
            usersWithIcons.length,
            (i) => Positioned(
              left: i * (circleSize * iconOverlap),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: circleSize, maxWidth: circleSize),
                child: UserIcon(
                  size: circleSize,
                  borderWidth: borderWidth,
                  avatar: usersWithIcons.elementAt(i).avatarUrls?.$48X48,
                ),
              ),
            ),
          ).reversed,
          if (iconsCount < users.length) SizedBox(width: gap),
          if (iconsCount < users.length)
            Positioned(
              left: iconsExtent + gap,
              child: Container(
                decoration: circleDecoration,
                constraints: BoxConstraints(maxHeight: circleSize, maxWidth: circleSize),
                child: Center(child: Text('+${users.length - iconsCount}', style: counterStyle)),
              ),
            )
        ],
      ),
    );
  }
}
