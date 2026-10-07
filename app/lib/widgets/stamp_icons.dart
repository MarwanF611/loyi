import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'loyi_icons.dart';

/// Icons a business can pick for its stamps. Keys are stored in Firestore,
/// so never rename one; add new keys instead.
const stampIcons = <String, IconData>{
  'check': LoyiIcons.check,
  'star': LoyiIcons.star,
  'heart': LoyiIcons.heart,
  'coffee': LoyiIcons.coffee,
  'croissant': LoyiIcons.croissant,
  'sandwich': LoyiIcons.sandwich,
  'pizza': LoyiIcons.pizza,
  'icecream': LoyiIcons.iceCreamCone,
  'cake': LoyiIcons.cake,
  'drink': LoyiIcons.wine,
  'scissors': LoyiIcons.scissors,
  'spa': LoyiIcons.sparkles,
  'flower': LoyiIcons.flower,
  'paw': LoyiIcons.pawPrint,
  'car': LoyiIcons.car,
  'bag': LoyiIcons.shoppingBag,
};

IconData stampIconData(String key) => stampIcons[key] ?? stampIcons['check']!;

/// The icon's name, for the picker's tooltips and screen readers.
String stampIconName(L10n l, String key) => switch (key) {
  'star' => l.stampIconStar,
  'heart' => l.stampIconHeart,
  'coffee' => l.stampIconCoffee,
  'croissant' => l.stampIconBakery,
  'sandwich' => l.stampIconSandwich,
  'pizza' => l.stampIconPizza,
  'icecream' => l.stampIconIceCream,
  'cake' => l.stampIconCake,
  'drink' => l.stampIconDrink,
  'scissors' => l.stampIconHair,
  'spa' => l.stampIconBeauty,
  'flower' => l.stampIconFlowers,
  'paw' => l.stampIconPets,
  'car' => l.stampIconCarWash,
  'bag' => l.stampIconShopping,
  _ => l.stampIconCheck,
};
