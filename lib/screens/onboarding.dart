import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_mobile/controllers/onboarding_controller.dart';
import 'package:quran_mobile/utils/colors.dart';
import 'package:quran_mobile/utils/device_utility.dart';
import 'package:quran_mobile/utils/helpers.dart';
import 'package:quran_mobile/utils/image_strings.dart';
import 'package:quran_mobile/utils/sizes.dart';
import 'package:quran_mobile/utils/texts.dart';
import 'package:quran_mobile/widgets/onboarding_pages.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    final controller = Get.put(OnboardingController());
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardingPage(
                img: TImages.obImage1,
                title: TTexts.obTitle1,
                subtitle: TTexts.obSubtitle1,
              ),
              OnBoardingPage(
                img: TImages.obImage2,
                title: TTexts.obTitle2,
                subtitle: TTexts.obSubtitle2,
              ),
              OnBoardingPage(
                img: TImages.obImage3,
                title: TTexts.obTitle3,
                subtitle: TTexts.obSubtitle3,
              ),
            ],
          ),
          Positioned(
            top: TDeviceUtils.getAppBarHeight(),
            right: TSizes.defaultSpace,
            child: TextButton(
              onPressed: () => OnboardingController.instance.skipPage(),
              child: Text(
                "Skip",
                style: TextStyle(
                  color: dark ? TColors.light : TColors.dark,
                ),
              ),
            ),
          ),
          OnBoardingDotNavigation(),
          OnBoardingNextButton(),
        ],
      ),
    );
  }
}

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Positioned(
      right: TSizes.defaultSpace,
      bottom: TDeviceUtils.getBottomNavigationBarHeight(),
      child: ElevatedButton(
        onPressed: () => OnboardingController.instance.nextPage(),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: dark ? TColors.primary : TColors.dark,
        ),
        child: Icon(CupertinoIcons.chevron_right),
      ),
    );
  }
}

class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight() + 20,
      left: TSizes.defaultSpace,
      child: SmoothPageIndicator(
        controller: controller.pageController,
        onDotClicked: controller.dotNavigationClick,
        count: 3,
        effect: ExpandingDotsEffect(
          activeDotColor: dark ? TColors.light : TColors.dark,
          dotHeight: 6,
        ),
      ),
    );
  }
}
