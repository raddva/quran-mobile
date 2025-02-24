import 'package:flutter/material.dart';
import 'package:quran_mobile/utils/helpers.dart';
import 'package:quran_mobile/utils/sizes.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key,
    required this.img,
    required this.title,
    required this.subtitle,
    this.isWeb = false,
  });

  final String img, title, subtitle;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            image: AssetImage(img),
            width: isWeb
                ? THelperFunctions.screenWidth() * 0.4
                : THelperFunctions.screenWidth() * 0.8,
            height: isWeb
                ? THelperFunctions.screenHeight() * 0.5
                : THelperFunctions.screenHeight() * 0.6,
          ),
          if (!isWeb) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TSizes.spaceBtwItems),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    );
  }
}
