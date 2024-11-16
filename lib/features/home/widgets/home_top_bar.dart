import 'package:booking_room/core/theming/colors.dart';
import 'package:booking_room/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back',
              style: TextStyles.font18DarkBlueBold,
            ),
            Text(
              'How Are you today?',
              style: TextStyles.font14GrayRegular,
            )
          ],
        ),
        const Spacer(),
        CircleAvatar(
          backgroundColor: ColorsManager.moreLighterGray,
          child: SvgPicture.asset('assets/svgs/notification.svg'),
        )
      ],
    );
  }
}
