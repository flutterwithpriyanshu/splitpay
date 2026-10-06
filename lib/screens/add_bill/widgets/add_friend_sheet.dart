import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Group;
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/contact_utils.dart';
import 'package:splitpay/core/phone_utils.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

/// "Add Friend" bottom sheet (name + phone / contact picker). Friend must
/// be registered on SplitPay. [onAdded] runs with the new friend before
/// the sheet closes.
Future<void> showAddFriendSheet(
  BuildContext context, {
  required void Function(Friend friend) onAdded,
}) async {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isChecking = false;
  Uint8List? pendingContactPhoto;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Friend',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pendingContactPhoto != null) ...[
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: MemoryImage(pendingContactPhoto!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Friend\'s name',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
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
                              // Only reading a contact here — request
                              // read, not readWrite. readWrite also asks
                              // for WRITE_CONTACTS, and on some devices
                              // that half of the combined prompt gets
                              // denied even after the user taps Allow,
                              // which made this show "permission required"
                              // even though contacts access was granted.
                              var status = await FlutterContacts.permissions
                                  .request(PermissionType.read);
                              if (status != PermissionStatus.granted) {
                                // Ask once more directly — some OEM
                                // dialogs report the first check as
                                // denied right after the user taps Allow.
                                status = await FlutterContacts.permissions
                                    .request(PermissionType.read);
                              }
                              if (status != PermissionStatus.granted) {
                                if (context.mounted) {
                                  showAppToast(
                                    context,
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
                              if (!context.mounted) return;
                              if (fullContact == null) return;

                              final pickedName =
                                  fullContact.displayName ?? '';
                              final phoneNumbers = fullContact.phones
                                  .map((phone) => phone.number)
                                  .toList();
                              final selectedPhone =
                                  await chooseContactPhoneNumber(
                                    context,
                                    phoneNumbers,
                                  );
                              if (!context.mounted) return;
                              if (phoneNumbers.length > 1 &&
                                  selectedPhone == null) {
                                return;
                              }
                              final pickedPhone = selectedPhone == null
                                  ? ''
                                  : normalizePhone(selectedPhone);
                              final photo =
                                  fullContact.photo?.fullSize ??
                                  fullContact.photo?.thumbnail;
                              final pickedPhoto =
                                  photo != null && photo.isNotEmpty
                                  ? photo
                                  : null;

                              setSheetState(() {
                                nameController.text = pickedName;
                                phoneController.text = pickedPhone;
                                pendingContactPhoto = pickedPhoto;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                showAppToast(
                                  context,
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
                  const SizedBox(height: 6),
                  Text(
                    'Only phone numbers registered on SplitPay can be added as friends.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isChecking
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final phone = normalizePhone(
                              phoneController.text.trim(),
                            );

                            if (name.isEmpty) {
                              showAppToast(context, 'Please enter a name');
                              return;
                            }
                            if (phone.isEmpty) {
                              showAppToast(
                                context,
                                'Phone number is required',
                              );
                              return;
                            }

                            setSheetState(() => isChecking = true);
                            try {
                              if (await FriendService.isOwnPhone(phone)) {
                                if (context.mounted) {
                                  showAppToast(
                                    context,
                                    "That's your own number — you can't add yourself as a friend",
                                  );
                                }
                                return;
                              }

                              final linkedUid =
                                  await FriendService.findUserByPhone(phone);

                              if (linkedUid == null) {
                                if (context.mounted) {
                                  showAppToast(
                                    context,
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
                                if (context.mounted) {
                                  showAppToast(
                                    context,
                                    'Friend already added',
                                  );
                                }
                                return;
                              }

                              final newFriend = await FriendService.addFriend(
                                name,
                                phoneNumber: phone,
                                contactPhotoBytes: pendingContactPhoto,
                              );

                              onAdded(newFriend);

                              if (context.mounted) {
                                Navigator.pop(context);
                                showAppToast(
                                  context,
                                  '${newFriend.name} is on SplitPay! Accounts linked.',
                                  isError: false,
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                showAppToast(
                                  context,
                                  'Could not add friend: $error',
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setSheetState(() => isChecking = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Add',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  nameController.dispose();
  phoneController.dispose();
}
