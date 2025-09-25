import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/services/monthly_account_entity_service.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';

class CleanService {

 static Future<void> cleanTablesFromDeletedObjects() async {
    await GroupEntityService.cleanGroupCategoryLinks();
    await MonthlyAccountEntityService.deleteSummariesOfDeletedAccount();
    await MonthlyCategoryTransactionEntityService.deleteSummariesOfDeletedCategories();
  }
}