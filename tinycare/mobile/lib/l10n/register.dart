import 'app_strings.dart';
import 'partials/common.dart';
import 'partials/auth.dart';
import 'partials/admin_core.dart';
import 'partials/admin_finance.dart';
import 'partials/admin_daily.dart';
import 'partials/admin_mgmt.dart';
import 'partials/parent.dart';
import 'partials/components.dart';
import 'partials/scaffolds.dart';
import 'partials/misc.dart';
import 'partials/offline.dart';

/// Merges every localization partial into [AppStrings].
/// Call this once at app startup (before runApp).
void registerLocalizations() {
  final appStrings = AppStrings.instance;
  appStrings.addEn(commonEn);
  appStrings.addEn(authEn);
  appStrings.addEn(adminCoreEn);
  appStrings.addEn(adminFinanceEn);
  appStrings.addEn(adminDailyEn);
  appStrings.addEn(adminMgmtEn);
  appStrings.addEn(parentEn);
  appStrings.addEn(componentsEn);
  appStrings.addEn(scaffoldsEn);
  appStrings.addEn(miscEn);
  appStrings.addEn(offlineEn);
}