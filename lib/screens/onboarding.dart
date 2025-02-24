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
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final controller = Get.put(OnboardingController());

    return Scaffold(
      body: isLargeScreen
          ? Row(
              children: [
                Expanded(
                  flex: 1,
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.updatePageIndicator,
                    children: [
                      OnBoardingPage(
                        img: TImages.obImage1,
                        title: "",
                        subtitle: "",
                        isWeb: true,
                      ),
                      OnBoardingPage(
                        img: TImages.obImage2,
                        title: "",
                        subtitle: "",
                        isWeb: true,
                      ),
                      OnBoardingPage(
                        img: TImages.obImage3,
                        title: "",
                        subtitle: "",
                        isWeb: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                              controller.currentPageIndex.value == 0
                                  ? TTexts.obTitle1
                                  : controller.currentPageIndex.value == 1
                                      ? TTexts.obTitle2
                                      : TTexts.obTitle3,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: dark ? TColors.light : TColors.dark,
                              ),
                            )),
                        const SizedBox(height: 20),
                        Obx(() => Text(
                              controller.currentPageIndex.value == 0
                                  ? TTexts.obSubtitle1
                                  : controller.currentPageIndex.value == 1
                                      ? TTexts.obSubtitle2
                                      : TTexts.obSubtitle3,
                              style: TextStyle(
                                fontSize: 18,
                                color: dark ? Colors.white70 : Colors.black87,
                              ),
                            )),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OnBoardingDotNavigation(),
                            OnBoardingNextButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Stack(
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
                Positioned(
                  bottom: TDeviceUtils.getBottomNavigationBarHeight() + 20,
                  left: 0,
                  right: 0,
                  child: Center(child: OnBoardingDotNavigation()),
                ),
                Positioned(
                  bottom: TDeviceUtils.getBottomNavigationBarHeight(),
                  right: TSizes.defaultSpace,
                  child: OnBoardingNextButton(),
                ),
              ],
            ),
    );
  }
}

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return ElevatedButton(
      onPressed: () => OnboardingController.instance.nextPage(),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: dark ? TColors.light : TColors.dark,
        iconColor: dark ? TColors.dark : TColors.light,
        padding: const EdgeInsets.all(15),
      ),
      child: Icon(CupertinoIcons.chevron_right, size: isLargeScreen ? 40 : 24),
    );
  }
}

class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return SmoothPageIndicator(
      controller: controller.pageController,
      onDotClicked: controller.dotNavigationClick,
      count: 3,
      effect: ExpandingDotsEffect(
        activeDotColor: dark ? TColors.light : TColors.dark,
        dotHeight: isLargeScreen ? 10 : 6,
        dotWidth: isLargeScreen ? 10 : 6,
      ),
    );
  }
}
