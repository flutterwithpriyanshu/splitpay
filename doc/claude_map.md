# SplitPay map (read this first, skip rest)

## Rules

- Output only changed files, path `lib/...`. No zip.
- No Flutter SDK → unverified. Only bracket-balance check.
- Preserve logic. Redesign UI only.
- Use tokens: `AppColors`, `AppText` (+`.tabular` on amounts), `AppRadius`, `AppSpacing`, `AppShadows`.
- Use shared widgets in `lib/widgets/app_ui.dart`: `AppCard`, `GradientButton`, `UpiPayButton`, `AmountPill`, `AppFab`, `FloatingDock`, `showAppSheet`.
- No hardcoded colors, no `GoogleFonts.inter`.
- Split rule: file name = widget name (`stat_tile.dart`, `card_button.dart`). Never `*_parts.dart`, `*_helpers.dart`. One main widget per file.
- Code rule: small files (<~250 lines), private widgets split into `widgets/` subfolder, one job per file, reuse shared widgets, no duplicate code.
- Restart (`q`, `flutter run`) when assets, State classes, `main.dart` change.

## Status

DONE: theme/_, widgets/app_ui, app_logo, intro_illustrations, screens/main_shell, splash, intro, auth, auth/security_check_screen, main.dart
TODO order: complete_profile, home, friends, groups, wallet, add_bill, settings, then detail/edit screens, then `screens/_/widgets`.

## Locations

- Entry: `lib/main.dart`
- Theme: `lib/theme/{app_colors,app_text,theme,theme_notifier}.dart`
- Shared UI: `lib/widgets/{app_ui,app_logo,intro_illustrations}.dart`
- Core: `lib/core/{app_currency,onboarding_prefs,profile_prefs,app_toast,debt_simplifier,upi_*,phone_utils}.dart`
- Services: `lib/services/{bill,friend,group,transaction,upi,fcm,local_notification,local_image}_service.dart`
- Models: `lib/model/{bill,friend,group,transaction}.dart`
- Screens: `lib/screens/*.dart`, subwidgets `lib/screens/<name>/widgets/`
- Unused (ask before delete): `lib/widgets/auth_form.dart`, `lib/screens/auth/widgets/auth_form.dart`

## Per-task log (append one line per task)

- [task] files changed → paths
- [home blank, dock mid-screen] FloatingDock Center expanded full height in bottomNavigationBar → heightFactor: 1 → lib/widgets/app_ui.dart
- [home fonts big + balance card restyle to image] smaller type, card gradient/rings/tiles, parts split → lib/screens/home/widgets/{balance_card,balance_card_parts (to rename: ring_painter, stat_tile, card_button),home_header,quick_split,activity_tile}.dart, lib/screens/home_screen.dart
- [home match image 2nd pass] sizes/weights tuned (top bar 20, greeting 20 ellipsis, titles 18 w600, tile amount 18, promo circle icon, page pad 16) → lib/screens/home_screen.dart, home/widgets/{home_header,quick_split,activity_tile}.dart
