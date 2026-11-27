import 'package:flutter/material.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/auto_capture/presentation/notification_access_bottom_sheet.dart';
import 'package:personal_finance/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart';
import 'package:personal_finance/utils/app_localization.dart';

Future<void> showShortcutsGuide(
  BuildContext context,
  AutoCaptureService service,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder:
      (sheet) => ShortcutsSetupBottomSheet(
        onClose: () => Navigator.pop(sheet),
        onOpenShortcuts: () async {
          if (!await service.openShortcuts() && sheet.mounted) {
            await showDialog<void>(
              context: sheet,
              builder:
                  (dialog) => AlertDialog(
                    content: Text(
                      AppLocalizations.captureText(
                        dialog,
                        'captureLaunchFailed',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: Text(
                          AppLocalizations.captureText(dialog, 'captureClose'),
                        ),
                      ),
                    ],
                  ),
            );
          }
        },
      ),
);

Future<void> showAndroidCaptureSetup(
  BuildContext context,
  AutoCaptureService service,
) async {
  final enable = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder:
        (sheet) => SafeArea(
          child: SingleChildScrollView(
            child: NotificationAccessBottomSheet(
              onEnable: () => Navigator.pop(sheet, true),
              onNotNow: () => Navigator.pop(sheet, false),
            ),
          ),
        ),
  );
  if (enable != true || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (sheet) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CaptureSourceChoices(service: service),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(sheet);
                    await service.openAccessSettings();
                  },
                  child: Text(
                    AppLocalizations.captureText(sheet, 'captureDenied'),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

class CaptureSourceChoices extends StatefulWidget {
  const CaptureSourceChoices({required this.service, super.key});
  final AutoCaptureService service;

  @override
  State<CaptureSourceChoices> createState() => _CaptureSourceChoicesState();
}

class _CaptureSourceChoicesState extends State<CaptureSourceChoices> {
  static const packages = {
    'com.google.android.apps.walletnfcrel': 'Google Wallet',
    'com.google.android.apps.nbu.paisa.user': 'Google Pay',
    'com.samsung.android.spay': 'Samsung Wallet',
    'gt.com.bi.bienlinea': 'Bi en Línea',
    'org.ctk.bancamovil': 'Banrural',
    'com.google.android.apps.messaging': 'Google Messages (SMS)',
    'com.samsung.android.messaging': 'Samsung Messages (SMS)',
  };
  bool saving = false;

  Future<void> _addBank() async {
    String? package;
    final selected = await showDialog<String>(
      context: context,
      builder:
          (dialog) => StatefulBuilder(
            builder:
                (context, update) => AlertDialog(
                  title: Text(
                    AppLocalizations.captureText(context, 'captureAddBank'),
                  ),
                  content: TextField(
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.captureText(
                        context,
                        'captureBankPackage',
                      ),
                      hintText: 'com.example.bank',
                    ),
                    onChanged: (value) => update(() => package = value.trim()),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: Text(
                        AppLocalizations.captureText(context, 'captureClose'),
                      ),
                    ),
                    FilledButton(
                      onPressed:
                          RegExp(
                                r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
                              ).hasMatch(package ?? '')
                              ? () => Navigator.pop(dialog, package)
                              : null,
                      child: Text(AppLocalizations.captureText(context, 'add')),
                    ),
                  ],
                ),
          ),
    );
    if (selected == null || !mounted) return;
    await widget.service.setSources({...widget.service.sources, selected});
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        title: Text(AppLocalizations.captureText(context, 'captureSources')),
      ),
      for (final entry
          in {
            ...packages,
            for (final id in widget.service.sources)
              if (!packages.containsKey(id)) id: id,
          }.entries)
        CheckboxListTile(
          title: Text(entry.value),
          value: widget.service.sources.contains(entry.key),
          onChanged:
              saving
                  ? null
                  : (checked) async {
                    final sources = {...widget.service.sources};
                    if (checked == true) {
                      sources.add(entry.key);
                    } else {
                      sources.remove(entry.key);
                    }
                    setState(() => saving = true);
                    try {
                      await widget.service.setSources(sources);
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
        ),
      ListTile(
        leading: const Icon(Icons.add),
        title: Text(AppLocalizations.captureText(context, 'captureAddBank')),
        onTap: saving ? null : _addBank,
      ),
    ],
  );
}
