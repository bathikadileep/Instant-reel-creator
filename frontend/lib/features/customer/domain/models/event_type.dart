import 'package:flutter/material.dart';

enum EventType {
  birthday,
  wedding,
  shopPromotion,
  restaurant,
  realEstate,
  personalBranding;

  String get displayName {
    switch (this) {
      case EventType.birthday:
        return 'Birthday';
      case EventType.wedding:
        return 'Wedding';
      case EventType.shopPromotion:
        return 'Shop Promotion';
      case EventType.restaurant:
        return 'Restaurant';
      case EventType.realEstate:
        return 'Real Estate';
      case EventType.personalBranding:
        return 'Personal Branding';
    }
  }

  String get description {
    switch (this) {
      case EventType.birthday:
        return 'Capturing celebrations, cake cutting, and joyous moments.';
      case EventType.wedding:
        return 'Cinematic highlights of ceremonies and intimate moments.';
      case EventType.shopPromotion:
        return 'Showcasing store launch, offers, inventory, and footfall.';
      case EventType.restaurant:
        return 'Mouth-watering dish B-roll, chef spotlight, and ambiance.';
      case EventType.realEstate:
        return 'Fast walkthroughs of properties, interiors, and architectural features.';
      case EventType.personalBranding:
        return 'Creator speaking hooks, outfit transitions, and personal aesthetics.';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.birthday:
        return Icons.cake_outlined;
      case EventType.wedding:
        return Icons.favorite_border_rounded;
      case EventType.shopPromotion:
        return Icons.storefront_outlined;
      case EventType.restaurant:
        return Icons.restaurant_menu_rounded;
      case EventType.realEstate:
        return Icons.apartment_rounded;
      case EventType.personalBranding:
        return Icons.star_border_rounded;
    }
  }

  String toApiKey() {
    switch (this) {
      case EventType.birthday:
        return 'birthday';
      case EventType.wedding:
        return 'wedding';
      case EventType.shopPromotion:
        return 'shop_promotion';
      case EventType.restaurant:
        return 'restaurant';
      case EventType.realEstate:
        return 'real_estate';
      case EventType.personalBranding:
        return 'personal_branding';
    }
  }
}
