import 'package:flutter/material.dart';
import '../presentation/settings/settings.dart';
import '../presentation/operation_history/operation_history.dart';
import '../presentation/file_browser/file_browser.dart';
import '../presentation/main_dashboard/main_dashboard.dart';
import '../presentation/confirmation_dialog/confirmation_dialog.dart';
import '../presentation/wipe_progress/wipe_progress.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String settings = '/settings';
  static const String operationHistory = '/operation-history';
  static const String fileBrowser = '/file-browser';
  static const String mainDashboard = '/main-dashboard';
  static const String confirmationDialog = '/confirmation-dialog';
  static const String wipeProgress = '/wipe-progress';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const Settings(),
    settings: (context) => const Settings(),
    operationHistory: (context) => const OperationHistory(),
    fileBrowser: (context) => const FileBrowser(),
    mainDashboard: (context) => const MainDashboard(),
    confirmationDialog: (context) => const ConfirmationDialog(),
    wipeProgress: (context) => const WipeProgress(),
    // TODO: Add your other routes here
  };
}
