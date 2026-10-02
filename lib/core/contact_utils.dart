import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<String?> chooseContactPhoneNumber(
  BuildContext context,
  List<String> phoneNumbers,
) async {
  if (phoneNumbers.isEmpty) return null;
  if (phoneNumbers.length == 1) return phoneNumbers.first;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('choose_phone_number'.tr()),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final number in phoneNumbers)
              ListTile(
                title: Text(number),
                onTap: () => Navigator.of(dialogContext).pop(number),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('cancel'.tr()),
        ),
      ],
    ),
  );
}
