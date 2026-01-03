class OnboardingPageModel {
  final String title;
  final String description;
  final String? imageAsset;
  final String? icon;
  final bool showImage;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    this.imageAsset,
    this.icon,
    this.showImage = false,
  });
}
