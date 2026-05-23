class MedIconEntry {
  final String label;
  final String assetPath;
  final String category;

  const MedIconEntry({
    required this.label,
    required this.assetPath,
    required this.category,
  });
}

class MedIconCatalog {
  static const String tablets = 'Tablets';
  static const String capsules = 'Capsules';
  static const String liquids = 'Liquids';
  static const String delivery = 'Delivery';

  static const List<String> categories = [
    tablets,
    capsules,
    liquids,
    delivery,
  ];

  static const List<MedIconEntry> entries = [
    MedIconEntry(
      label: 'Round White Tablet',
      assetPath: 'assets/images/icons/pills/tablet_round_white_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Round Blue Tablet',
      assetPath: 'assets/images/icons/pills/tablet_round_blue_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Round Pink Tablet',
      assetPath: 'assets/images/icons/pills/tablet_round_pink_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Scored Yellow Tablet',
      assetPath: 'assets/images/icons/pills/tablet_round_yellow_scored_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Green Dot Tablet',
      assetPath: 'assets/images/icons/pills/tablet_round_green_dot_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'White Oval Tablet',
      assetPath: 'assets/images/icons/pills/tablet_oval_white_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Peach Oval Tablet',
      assetPath: 'assets/images/icons/pills/tablet_oval_peach_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Blue Scored Caplet',
      assetPath: 'assets/images/icons/pills/tablet_oval_blue_scored_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Purple Caplet',
      assetPath: 'assets/images/icons/pills/tablet_caplet_purple_32.png',
      category: tablets,
    ),
    MedIconEntry(
      label: 'Blue/White Capsule',
      assetPath: 'assets/images/icons/pills/capsule_blue_white_32.png',
      category: capsules,
    ),
    MedIconEntry(
      label: 'Green/Cream Capsule',
      assetPath: 'assets/images/icons/pills/capsule_green_cream_32.png',
      category: capsules,
    ),
    MedIconEntry(
      label: 'Purple/Pink Capsule',
      assetPath: 'assets/images/icons/pills/capsule_purple_pink_32.png',
      category: capsules,
    ),
    MedIconEntry(
      label: 'Red/White Capsule',
      assetPath: 'assets/images/icons/pills/capsule_red_white_32.png',
      category: capsules,
    ),
    MedIconEntry(
      label: 'Amber Softgel',
      assetPath: 'assets/images/icons/pills/softgel_amber_32.png',
      category: capsules,
    ),
    MedIconEntry(
      label: 'Red Softgel',
      assetPath: 'assets/images/icons/pills/softgel_red_32.png',
      category: capsules,
    ),
    MedIconEntry(
      label: 'Teal Softgel',
      assetPath: 'assets/images/icons/pills/softgel_teal_32.png',
      category: capsules,
    ),
    MedIconEntry(
      label: 'Amber Bottle',
      assetPath: 'assets/images/icons/pills/bottle_amber_32.png',
      category: liquids,
    ),
    MedIconEntry(
      label: 'Teal Bottle',
      assetPath: 'assets/images/icons/pills/bottle_teal_32.png',
      category: liquids,
    ),
    MedIconEntry(
      label: 'Teal Dropper',
      assetPath: 'assets/images/icons/pills/dropper_teal_32.png',
      category: liquids,
    ),
    MedIconEntry(
      label: 'Purple Vial',
      assetPath: 'assets/images/icons/pills/vial_purple_32.png',
      category: liquids,
    ),
    MedIconEntry(
      label: 'Teal Vial',
      assetPath: 'assets/images/icons/pills/vial_teal_32.png',
      category: liquids,
    ),
    MedIconEntry(
      label: 'Blue Inhaler',
      assetPath: 'assets/images/icons/pills/inhaler_blue_32.png',
      category: delivery,
    ),
    MedIconEntry(
      label: 'Peach Patch',
      assetPath: 'assets/images/icons/pills/patch_peach_32.png',
      category: delivery,
    ),
    MedIconEntry(
      label: 'Teal Nasal Spray',
      assetPath: 'assets/images/icons/pills/spray_teal_32.png',
      category: delivery,
    ),
    MedIconEntry(
      label: 'Purple Syringe',
      assetPath: 'assets/images/icons/pills/syringe_purple_32.png',
      category: delivery,
    ),
    MedIconEntry(
      label: 'Teal Syringe',
      assetPath: 'assets/images/icons/pills/syringe_teal_32.png',
      category: delivery,
    ),
  ];

  static const MedIconEntry defaultEntry = MedIconEntry(
    label: 'Blue/White Capsule',
    assetPath: 'assets/images/icons/pills/capsule_blue_white_32.png',
    category: capsules,
  );

  static MedIconEntry? byAssetPath(String? assetPath) {
    if (assetPath == null || assetPath.isEmpty) return null;
    for (final entry in entries) {
      if (entry.assetPath == assetPath) return entry;
    }
    return null;
  }

  static List<MedIconEntry> entriesForCategory(String category) {
    return entries.where((entry) => entry.category == category).toList();
  }

  static String categoryForAssetPath(String? assetPath) {
    return byAssetPath(assetPath)?.category ?? defaultEntry.category;
  }

  static String labelForAssetPath(String? assetPath) {
    return byAssetPath(assetPath)?.label ?? 'Default Capsule';
  }
}
