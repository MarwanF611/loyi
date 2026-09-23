import 'package:flutter/material.dart';

/// Icons a business can pick for its stamps. Keys are stored in Firestore,
/// so never rename one; add new keys instead.
const stampIcons = <String, (IconData, String)>{
  'check': (Icons.check_rounded, 'Check'),
  'star': (Icons.star_rounded, 'Star'),
  'heart': (Icons.favorite_rounded, 'Heart'),
  'coffee': (Icons.coffee_rounded, 'Coffee'),
  'croissant': (Icons.bakery_dining_rounded, 'Bakery'),
  'sandwich': (Icons.lunch_dining_rounded, 'Sandwich'),
  'pizza': (Icons.local_pizza_rounded, 'Pizza'),
  'icecream': (Icons.icecream_rounded, 'Ice cream'),
  'cake': (Icons.cake_rounded, 'Cake'),
  'drink': (Icons.local_bar_rounded, 'Drink'),
  'scissors': (Icons.content_cut_rounded, 'Hair'),
  'spa': (Icons.spa_rounded, 'Beauty'),
  'flower': (Icons.local_florist_rounded, 'Flowers'),
  'paw': (Icons.pets_rounded, 'Pets'),
  'car': (Icons.local_car_wash_rounded, 'Car wash'),
  'bag': (Icons.shopping_bag_rounded, 'Shopping'),
};

IconData stampIconData(String key) => (stampIcons[key] ?? stampIcons['check']!).$1;
