# SplitPay handoff (read only this. skip rest of chat)

Flutter app `splitpay`: bill split + UPI settle-up. Task = redesign UI screen-by-screen from user images. Keep logic.

## 0. How to use

- New chat: user uploads this file + `lib.zip` + 1 screen image.
- User says "create handoff" → update this file (sections 4, 5, 6, 7, 8) → send via `present_files` at `docs/handoff.md`. Keep < 150 lines. Prune old, no history essays.
- Extract: `unzip -oq /mnt/user-data/uploads/lib.zip -d /home/claude/proj`. Work in `/home/claude/proj/lib`. Copy each output back there.
- Read only files needed for the screen (grep first, `sed -n` ranges). No full-file dumps.

## 1. Rules (user, always)

- Reply caveman ULTRA until user says "stop caveman": terse, no articles/filler/pleasantries/hedging/emoji/decorative tables, arrows for causality, abbreviate prose (DB, auth, config, req, res, fn, impl). Code, paths, API names, error strings VERBATIM. Never name/announce mode. Security warnings / irreversible actions → normal prose, then resume.
- Send changed files only, path `lib/...`. NO zip, ever. Write `/mnt/user-data/outputs/lib/<path>` → `present_files` → short table (path, action).
- Split rule: big file → split into files named by widget (`stat_tile.dart`, `card_button.dart`). Never `*_parts.dart` / `*_helpers.dart`. One main widget per file. Files < ~250 lines. No duplicate code, reuse shared widgets. Optimize for low token.
- User English rough. Unclear → max 1 question.
- No Flutter SDK → nothing compiled. Only check: bracket balance (python count `() {} []`). Say "unverified". Ask console logs on break.
- After each screen: list diffs from image + what image bug/placeholder was fixed. Ask next screen.
- Remind full restart (`q`, `flutter run`) when assets, State classes, `main.dart` change.
- Image placeholders / render bugs (empty `img`, duplicate bell, flat nav) → fix sensibly, tell user.
- Source files CRLF; outputs LF fine. Edit via python replace on `\r\n`-normalized text; assert each old string exists.
- Log each task: 1 line in section 8.

## 2. Design system ("Electric Modern Fintech")

- Font Plus Jakarta Sans. `.tabular` on ALL amounts.
- Radii: card 24, control 16, pill 999, sheet 32, inner 12.
- Gradient only: FAB, balance/payment banners, main CTA.
- Light: primary `#5B3DF5`, grad `#5B3DF5→#8E5BFF`, success `#12B981`, danger `#F43F5E`, warning `#F59E0B`, bg `#F5F6FB`, surface `#FFFFFF`, raised `#EEF0F8`, text `#0F1226`, text2 `#6B7194`, divider `#E3E6F2`.
- Dark: primary `#8B7CFF`, bg `#0B0D17`, surface `#151826`, raised `#1E2235`. Dark = no shadows, borders.
- Balance card (fixed colors): grad `5B3DF5→4527DE→2E12B8`, mint `6BF5C6`, mint ink `0F2A22`.
- Page bg grad (light, intro/auth): `EDE9FF→F5F6FB`.
- Floating dock: pill, 64 tall, 20 above bottom, max 420 wide, in `bottomNavigationBar`.
- Image scale hint: mock 496 px ≈ 390 dp. Estimate font = char width / 0.55.

## 3. API cheat sheet (use, no hardcode)

- `AppColors`: `primary secondary success error warning background surface textPrimary textSecondary divider surfaceRaised successTint dangerTint warningTint primaryTint primaryGradient`, `AppColors.palette.isDark`.
- `AppRadius`: `card control inner sheet pill`. `AppSpacing`: `xs sm md lg xl dockHeight dockBottomGap`. `AppShadows`: `card raised dock fab`.
- `AppText`: `displayLg(40) displayLgMobile(32) headlineLg(28) headlineMd(22) headlineSm(18) bodyLg(16) bodyMd(14) bodySm(12) labelLg(16) labelMd(13) labelSm(11) currencyDisplay currencyMd` + `.tabular`. Phone screens: prefer headlineSm / bodySm / labelMd; big sizes overflow.
- `lib/widgets/app_ui.dart`: `AppCard({child,padding=20,onTap,margin})`, `GradientButton({label,onPressed,icon,expand=true,loading=false})`, `UpiPayButton`, `AmountPill({amount,settledLabel})`, `AppFab`, `DockItem`, `FloatingDock`, `showAppSheet<T>(context, builder:)`.
- `AppLogo({size=96,withBackground=true})`. `showAppToast(context,msg,{isError})` (still hardcoded red).
- Money: `formatMoney`, `formatSignedMoney` (`core/money_format.dart`). Date: `monthYear`, `dayPad`, `monthAbbr` (`core/app_date_format.dart`).

## 4. Project map

- Entry `lib/main.dart`: Firebase/FCM/prefs → `SplashScreen` → `IntroScreen` → auth `StreamBuilder` → `AuthScreen` | profile check | `MainShell` (tabs: Home, Friends, Groups, Wallet; `mainTabNotifier` switches tab).
- `lib/theme/{app_colors,app_text,theme,theme_notifier}.dart`
- `lib/widgets/{app_ui,app_logo,intro_illustrations,local_avatar,edit_profile_screen,manage_friends_screen,login_method_badge,day_of_month_picker}.dart`
- `lib/core/`: `app_notification` (model), `notification_feed` (builds feed from streams, exports model), `notification_store` (local JSON file `notifications_<uid>.json`, path*provider; delete/clearIds/sync), `time_ago`, `app_currency`, `onboarding_prefs`, `profile_prefs`, `app_toast`, `debt_simplifier`, `upi*\*`, `phone_utils`, `money_format`, `app_date_format`, `bill_category`, `notification_prefs`
- `lib/services/`: bill, friend, group, transaction, upi, fcm, local_notification, local_image
- `lib/model/`: bill, friend, group, transaction
- `lib/screens/`: splash, intro, auth, complete_profile, main_shell, home, friends, groups, wallet, add_bill, add_group_bill, edit_bill, bill_detail, friend_details, group_details, shared_group_details, edit_group_settings, group_settle_up, group_splitup, settings, static_content. Subwidgets in `lib/screens/<name>/widgets/`.
- Deps: firebase_core/auth, cloud_firestore, google_sign_in (new API `GoogleSignIn.instance.authenticate()`), easy_localization (en hi es fr), flutter_animate, google_fonts, shared_preferences.
- Test device `CPH2035` Android, Impeller, density 3.

## 5. Status

DONE: theme/_, widgets/app_ui, app_logo, intro_illustrations, main_shell (dock), splash, intro, auth, auth/security_check_screen, home (+ `home/widgets/{balance_card,balance_card_parts,home_header,quick_split,activity_tile,notification_bell}`), notifications (+ local file store, swipe delete, clear all).
TODO (in order, user sends image each): complete_profile, friends, groups, wallet, add_bill, settings, then detail/edit screens, then `screens/_/widgets`.
Home notes: `home_screen.dart`still ~1000 lines (split pending, user not yet approved).`balance_card_parts.dart`breaks split rule → rename to`ring_painter.dart`, `stat_tile.dart`, `card_button.dart` (user not yet approved).

## 6. Lessons (bugs seen)

- Notifications: feed derived from live streams, saved by `NotificationStore.sync` (post-frame). Swiped/cleared ids stay in `dismissed` list → never return. Resolved pending rows (paid request) auto-dropped.
- `Center` inside `bottomNavigationBar` fills full height → body 0 → blank screen. Use `Center(heightFactor: 1)`.
- `BackdropFilter` blank under Impeller → no blur, use translucent fill + border.
- State rebuild restarts `flutter_animate` → put timers in own State widget.
- Dark theme must use dark palette (fixed in `AppTheme`).
- Hot reload can't turn Stateless → Stateful.

## 7. Pending

- Old screens hardcode colors (`0xFF22C55E`, `0xFFEF4444`), `GoogleFonts.inter`, own FABs → swap to tokens/shared widgets, `.tabular` amounts.
- Restyle `showAppToast`.
- Intro/splash/auth text hardcoded English → localize only if user asks.
- Launcher icon needs `pubspec.yaml` (`flutter_launcher_icons` → `assets/icon/playstore.png`), not visible.
- Impeller fallback: `<meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="false" />` in `AndroidManifest.xml`.
- Auth: Terms/Privacy no tap handler; intro "Log in" only finishes intro.
- Unused (ask before delete): `lib/widgets/auth_form.dart`, `lib/screens/auth/widgets/auth_form.dart`.
- New features: ask user after all UI images done.

## 8. Task log (1 line each, newest last)

- Dock fix `Center heightFactor` → `lib/widgets/app_ui.dart`
- Home fonts smaller + balance card restyle → `home/widgets/{balance_card,balance_card_parts,home_header,quick_split,activity_tile}.dart`, `home_screen.dart`
- Home 2nd pass match image (sizes/weights, promo card, page pad 16) → same files
- Split-naming rule added
- Notifications screen: image match, local file store, swipe-right delete, clear all → `core/{app_notification,notification_store,notification_feed,time_ago}.dart`, `screens/notifications_screen.dart`, `screens/notifications/widgets/*` (13 files)

## 9. Per-screen workflow

1. grep/sed target screen + its `widgets/` folder. Keep ALL logic.
2. Build from image with tokens + shared widgets. Illustrations/avatars in code.
3. Write `/mnt/user-data/outputs/lib/<path>` → bracket-balance check → copy to working copy.
4. Append log line in this file (section 8) → `present_files` (changed files + `docs/handoff.md`).
5. Reply: table (path, action), logic kept, diffs from image, unverified + restart note, ask next screen.
