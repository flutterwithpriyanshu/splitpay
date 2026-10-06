import 'package:flutter/material.dart';

/// Curated Material icons ("Fintech Icons" tab). Stored by [key], not
/// code point, so release builds keep icon tree-shaking working.
class CategoryIcon {
  final String key;
  final IconData icon;
  final String tags;
  const CategoryIcon(this.key, this.icon, this.tags);
}

const List<CategoryIcon> categoryIcons = [
  // Money & finance
  CategoryIcon('payments', Icons.payments_rounded, 'money cash pay payment'),
  CategoryIcon('wallet', Icons.account_balance_wallet_rounded, 'wallet money balance'),
  CategoryIcon('card', Icons.credit_card_rounded, 'credit card bill'),
  CategoryIcon('bank', Icons.account_balance_rounded, 'bank finance loan'),
  CategoryIcon('savings', Icons.savings_rounded, 'savings piggy money invest'),
  CategoryIcon('rupee', Icons.currency_rupee_rounded, 'rupee inr money'),
  CategoryIcon('dollar', Icons.attach_money_rounded, 'dollar usd money'),
  CategoryIcon('euro', Icons.euro_rounded, 'euro eur money'),
  CategoryIcon('receipt', Icons.receipt_long_rounded, 'receipt bill invoice'),
  CategoryIcon('atm', Icons.local_atm_rounded, 'atm cash withdraw'),
  CategoryIcon('trend', Icons.trending_up_rounded, 'growth invest stock'),
  CategoryIcon('chart', Icons.bar_chart_rounded, 'chart report stats'),
  CategoryIcon('percent', Icons.percent_rounded, 'tax discount percent'),
  CategoryIcon('swap', Icons.swap_horiz_rounded, 'transfer swap exchange'),
  CategoryIcon('gift', Icons.card_giftcard_rounded, 'gift present birthday'),
  CategoryIcon('volunteer', Icons.volunteer_activism_rounded, 'donate charity give'),
  // Food
  CategoryIcon('restaurant', Icons.restaurant_rounded, 'food dining restaurant meal'),
  CategoryIcon('pizza', Icons.local_pizza_rounded, 'pizza food'),
  CategoryIcon('burger', Icons.lunch_dining_rounded, 'burger lunch food'),
  CategoryIcon('fastfood', Icons.fastfood_rounded, 'fast food snack'),
  CategoryIcon('ramen', Icons.ramen_dining_rounded, 'ramen noodles food'),
  CategoryIcon('cafe', Icons.local_cafe_rounded, 'coffee tea cafe'),
  CategoryIcon('bar', Icons.local_bar_rounded, 'bar drinks cocktail'),
  CategoryIcon('beer', Icons.sports_bar_rounded, 'beer pub drinks'),
  CategoryIcon('cake', Icons.cake_rounded, 'cake birthday dessert'),
  CategoryIcon('icecream', Icons.icecream_rounded, 'ice cream dessert'),
  CategoryIcon('bakery', Icons.bakery_dining_rounded, 'bakery bread'),
  CategoryIcon('grocery', Icons.local_grocery_store_rounded, 'grocery groceries market'),
  // Shopping
  CategoryIcon('cart', Icons.shopping_cart_rounded, 'shopping cart buy'),
  CategoryIcon('bag', Icons.shopping_bag_rounded, 'shopping bag buy'),
  CategoryIcon('mall', Icons.local_mall_rounded, 'mall shop store'),
  CategoryIcon('store', Icons.storefront_rounded, 'store shop market'),
  CategoryIcon('checkroom', Icons.checkroom_rounded, 'clothes fashion wardrobe'),
  CategoryIcon('watch', Icons.watch_rounded, 'watch accessories'),
  // Travel
  CategoryIcon('car', Icons.directions_car_rounded, 'car drive cab travel'),
  CategoryIcon('fuel', Icons.local_gas_station_rounded, 'fuel petrol diesel gas'),
  CategoryIcon('taxi', Icons.local_taxi_rounded, 'taxi cab ride'),
  CategoryIcon('bus', Icons.directions_bus_rounded, 'bus transport'),
  CategoryIcon('train', Icons.train_rounded, 'train rail metro'),
  CategoryIcon('flight', Icons.flight_rounded, 'flight plane air trip'),
  CategoryIcon('bike', Icons.directions_bike_rounded, 'bike cycle ride'),
  CategoryIcon('scooter', Icons.two_wheeler_rounded, 'scooter motorbike'),
  CategoryIcon('parking', Icons.local_parking_rounded, 'parking car'),
  CategoryIcon('hotel', Icons.hotel_rounded, 'hotel stay room'),
  CategoryIcon('luggage', Icons.luggage_rounded, 'luggage trip travel bag'),
  CategoryIcon('map', Icons.map_rounded, 'map trip place'),
  CategoryIcon('beach', Icons.beach_access_rounded, 'beach holiday vacation'),
  CategoryIcon('hiking', Icons.hiking_rounded, 'hiking trek trail'),
  // Home
  CategoryIcon('home', Icons.home_rounded, 'home house rent'),
  CategoryIcon('apartment', Icons.apartment_rounded, 'apartment flat rent building'),
  CategoryIcon('bolt', Icons.bolt_rounded, 'electricity power bolt'),
  CategoryIcon('water', Icons.water_drop_rounded, 'water bill drop'),
  CategoryIcon('wifi', Icons.wifi_rounded, 'wifi internet broadband'),
  CategoryIcon('phone', Icons.phone_android_rounded, 'phone mobile recharge'),
  CategoryIcon('tv', Icons.tv_rounded, 'tv cable dth'),
  CategoryIcon('laundry', Icons.local_laundry_service_rounded, 'laundry wash clothes'),
  CategoryIcon('cleaning', Icons.cleaning_services_rounded, 'cleaning maid'),
  CategoryIcon('repair', Icons.handyman_rounded, 'repair fix tools'),
  CategoryIcon('plumbing', Icons.plumbing_rounded, 'plumber pipe'),
  CategoryIcon('weekend', Icons.weekend_rounded, 'sofa furniture'),
  CategoryIcon('kitchen', Icons.kitchen_rounded, 'kitchen fridge'),
  // Fun & sports
  CategoryIcon('tennis', Icons.sports_tennis_rounded, 'badminton tennis racket sport turf'),
  CategoryIcon('soccer', Icons.sports_soccer_rounded, 'football soccer sport turf'),
  CategoryIcon('cricket', Icons.sports_cricket_rounded, 'cricket sport bat'),
  CategoryIcon('basketball', Icons.sports_basketball_rounded, 'basketball sport'),
  CategoryIcon('esports', Icons.sports_esports_rounded, 'gaming games console'),
  CategoryIcon('gym', Icons.fitness_center_rounded, 'gym fitness workout'),
  CategoryIcon('pool', Icons.pool_rounded, 'swimming pool'),
  CategoryIcon('golf', Icons.golf_course_rounded, 'golf sport'),
  CategoryIcon('trophy', Icons.emoji_events_rounded, 'trophy win tournament'),
  CategoryIcon('movie', Icons.movie_rounded, 'movie cinema film'),
  CategoryIcon('music', Icons.music_note_rounded, 'music concert song'),
  CategoryIcon('headphones', Icons.headphones_rounded, 'music headphones'),
  CategoryIcon('party', Icons.celebration_rounded, 'party celebration event'),
  CategoryIcon('nightlife', Icons.nightlife_rounded, 'club night party'),
  CategoryIcon('theater', Icons.theater_comedy_rounded, 'theatre drama show'),
  CategoryIcon('camera', Icons.photo_camera_rounded, 'photo camera'),
  CategoryIcon('brush', Icons.brush_rounded, 'art paint hobby'),
  // Health, work, life
  CategoryIcon('medical', Icons.medical_services_rounded, 'doctor medical clinic'),
  CategoryIcon('hospital', Icons.local_hospital_rounded, 'hospital health'),
  CategoryIcon('pharmacy', Icons.medication_rounded, 'medicine pharmacy'),
  CategoryIcon('spa', Icons.spa_rounded, 'spa salon wellness'),
  CategoryIcon('school', Icons.school_rounded, 'school college fees study'),
  CategoryIcon('book', Icons.menu_book_rounded, 'book study read'),
  CategoryIcon('work', Icons.work_rounded, 'work office job'),
  CategoryIcon('laptop', Icons.laptop_mac_rounded, 'laptop computer work'),
  CategoryIcon('subscription', Icons.subscriptions_rounded, 'subscription netflix ott'),
  CategoryIcon('cloud', Icons.cloud_rounded, 'cloud software saas'),
  CategoryIcon('pets', Icons.pets_rounded, 'pet dog cat'),
  CategoryIcon('child', Icons.child_care_rounded, 'baby child kids'),
  CategoryIcon('family', Icons.family_restroom_rounded, 'family kids'),
  CategoryIcon('florist', Icons.local_florist_rounded, 'flowers garden'),
  CategoryIcon('park', Icons.park_rounded, 'park nature tree'),
  CategoryIcon('security', Icons.shield_rounded, 'insurance security safe'),
  CategoryIcon('star', Icons.star_rounded, 'star favourite'),
  CategoryIcon('heart', Icons.favorite_rounded, 'love heart favourite'),
  CategoryIcon('group', Icons.groups_rounded, 'group friends team'),
  CategoryIcon('category', Icons.category_rounded, 'misc other general'),
];

final Map<String, CategoryIcon> _byKey = {
  for (final i in categoryIcons) i.key: i,
};

IconData? categoryIconByKey(String? key) => key == null ? null : _byKey[key]?.icon;

List<CategoryIcon> searchCategoryIcons(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return categoryIcons;
  return categoryIcons
      .where((i) => i.key.contains(q) || i.tags.contains(q))
      .toList();
}
