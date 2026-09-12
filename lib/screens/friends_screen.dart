import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Group;
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/friend_details_screen.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/core/app_toast.dart';

/// Bottom-nav "Friends" screen — your friend list with live balances
/// (same data as ManageFriendsScreen, shown inline instead of as a
/// separate push). Groups now live on their own bottom-nav tab —
/// see GroupsScreen.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Friends',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _FriendsTab(
                onAddFriend: () => _showAddFriendSheet(context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool isChecking = false;
    Uint8List? pendingContactPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Friend',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pendingContactPhoto != null) ...[
                    Center(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: MemoryImage(pendingContactPhoto!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Phone number',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            try {
                              // read only — readWrite also asks for
                              // WRITE_CONTACTS and can come back denied
                              // even after the user taps Allow.
                              var status = await FlutterContacts.permissions
                                  .request(PermissionType.read);
                              if (status != PermissionStatus.granted) {
                                status = await FlutterContacts.permissions
                                    .request(PermissionType.read);
                              }
                              if (status != PermissionStatus.granted) {
                                if (sheetContext.mounted) {
                                  showAppToast(
                                    sheetContext,
                                    'Contacts permission is required to pick a contact',
                                  );
                                }
                                return;
                              }

                              final picked = await FlutterContacts.native
                                  .showPicker(
                                    properties: {
                                      ContactProperty.phone,
                                      ContactProperty.photoFullRes,
                                    },
                                  );
                              if (picked == null || picked.id == null) return;

                              final fullContact = await FlutterContacts.get(
                                picked.id!,
                                properties: ContactProperties.all,
                              );
                              if (fullContact == null) return;

                              final pickedName = fullContact.displayName ?? '';
                              final pickedPhone = fullContact.phones.isNotEmpty
                                  ? normalizePhone(
                                      fullContact.phones.first.number,
                                    )
                                  : '';
                              final photo = fullContact.photo?.fullSize;
                              final pickedPhoto =
                                  photo != null && photo.isNotEmpty
                                  ? photo
                                  : null;

                              if (!sheetContext.mounted) return;
                              setSheetState(() {
                                nameController.text = pickedName;
                                phoneController.text = pickedPhone;
                                pendingContactPhoto = pickedPhoto;
                              });
                            } catch (e) {
                              if (sheetContext.mounted) {
                                showAppToast(
                                  sheetContext,
                                  'Could not open contacts: $e',
                                );
                              }
                            }
                          },
                          icon: Icon(
                            Icons.contact_page_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only phone numbers registered on SplitPay can be added as friends.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isChecking
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final phone = normalizePhone(
                                phoneController.text.trim(),
                              );

                              if (name.isEmpty || phone.isEmpty) {
                                showAppToast(
                                  sheetContext,
                                  'Name and phone are required',
                                );
                                return;
                              }

                              setSheetState(() => isChecking = true);

                              if (await FriendService.isOwnPhone(phone)) {
                                setSheetState(() => isChecking = false);
                                if (sheetContext.mounted) {
                                  showAppToast(
                                    sheetContext,
                                    "That's your own number — you can't add yourself as a friend",
                                  );
                                }
                                return;
                              }

                              final linkedUid =
                                  await FriendService.findUserByPhone(phone);

                              if (linkedUid == null) {
                                setSheetState(() => isChecking = false);
                                if (sheetContext.mounted) {
                                  showAppToast(
                                    sheetContext,
                                    "This number hasn't signed up for SplitPay — friend not added",
                                  );
                                }
                                return;
                              }

                              final alreadyAdded =
                                  await FriendService.isFriendAlreadyAdded(
                                    phoneNumber: phone,
                                    linkedUid: linkedUid,
                                  );
                              if (alreadyAdded) {
                                setSheetState(() => isChecking = false);
                                if (sheetContext.mounted) {
                                  showAppToast(
                                    sheetContext,
                                    'Friend already added',
                                  );
                                }
                                return;
                              }

                              final newFriend = await FriendService.addFriend(
                                name,
                                phoneNumber: phone,
                              );

                              if (pendingContactPhoto != null) {
                                await LocalImageService.saveFriendImage(
                                  newFriend.id,
                                  pendingContactPhoto!,
                                );
                              }

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Add Friend',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Same list/balance logic as ManageFriendsScreen, inline.
class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.onAddFriend});

  final VoidCallback onAddFriend;

  double _balanceForFriend(List<Bill> bills, Friend friend) {
    double balance = 0;
    for (final bill in bills) {
      if (friend.isLinked) {
        if (!bill.isParticipant(friend.linkedUid!)) continue;
        balance += bill.balanceForUid(friend.linkedUid!);
      } else {
        if (bill.isSettledFor(friend.id)) continue;
        if (!bill.friendIds.contains(friend.id)) continue;
        if (bill.paidBy == 'me') {
          balance += bill.shareForFriend(friend.id);
        } else if (bill.paidBy == friend.id) {
          balance -= bill.myShare;
        }
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.streamFriends(),
      builder: (context, friendSnapshot) {
        final friends = friendSnapshot.data ?? [];
        final friendsLoading =
            friendSnapshot.connectionState == ConnectionState.waiting;

        if (friendsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No friends added yet',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onAddFriend,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add Friend'),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<Bill>>(
          stream: BillService.streamBills(),
          builder: (context, billSnapshot) {
            final bills = billSnapshot.data ?? [];
            final billsLoading =
                billSnapshot.connectionState == ConnectionState.waiting;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final balance = _balanceForFriend(bills, friend);

                String balanceText;
                Color balanceColor;

                if (billsLoading) {
                  balanceText = '...';
                  balanceColor = AppColors.textSecondary;
                } else if (balance == 0) {
                  balanceText = 'Settled up';
                  balanceColor = AppColors.textSecondary;
                } else if (balance > 0) {
                  balanceText = 'Owes you ₹${balance.abs().toStringAsFixed(0)}';
                  balanceColor = AppColors.success;
                } else {
                  balanceText = 'You owe ₹${balance.abs().toStringAsFixed(0)}';
                  balanceColor = AppColors.error;
                }

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FriendDetailsScreen(friend: friend),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        LocalAvatar(
                          localKey: friend.id,
                          isProfile: false,
                          fallbackUrl: friend.avatarUrl,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                balanceText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: balanceColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
