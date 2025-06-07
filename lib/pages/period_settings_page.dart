import 'package:flutter/material.dart';
import 'package:myfinance2/services/configuration_entity_service.dart';
import 'package:myfinance2/services/monthly_account_entity_service.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';
import 'package:myfinance2/widgets/info_label.dart';

class PeriodSettingsPage extends StatefulWidget {
  final int periodStartingDay;
  
  const PeriodSettingsPage({super.key, required this.periodStartingDay});

  @override
  State createState() => PeriodSettingsPageState();
}

class PeriodSettingsPageState extends State<PeriodSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late int _periodStartingDay;
  late int _previousPeriodStartingDay;

  @override
  void initState() {
    super.initState();
    _periodStartingDay = widget.periodStartingDay;
    _previousPeriodStartingDay = widget.periodStartingDay;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping GeneralSettingsPage _dataChanged=false, result=$result");
          Navigator.pop(context, false);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text("Settings")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child:
              Column(
                children: [
                  InfoLabel(text: "Change the 'Monthly start day' if you prefer that your budgeting monthly stats are calculated considering another day of the month as first day (allowed values: from 1 to 28)"),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Monthly start day *'),
                    initialValue: "$_periodStartingDay",
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: false,
                      signed: false
                    ),
                    onChanged: (value) => _periodStartingDay = int.tryParse(value) ?? 1,
                    validator: (value) => int.tryParse(value ?? "") == null 
                      || (int.tryParse(value ?? "") ?? 0) < 1 
                      || (int.tryParse(value ?? "") ?? 0) > 28 ? 'Enter a number between 1 and 28' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _saveConfigurations();
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        )
      ),
    );
  }

  _saveConfigurations() async {
    if (_previousPeriodStartingDay != _periodStartingDay) {
      _showChangePeriodStartingDayDialog();
    } else {
      if (mounted){
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _showChangePeriodStartingDayDialog() async {
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              title: const Text('Monthly starting day update'),
              content: isLoading
                  ? SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const Text("Changing the monthly starting day will recalculate all statistics, this process may require a minute. Proceed?"),
              actions: isLoading
                  ? []
                  : <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, 'Cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        child: const Text('Confirm'),
                        onPressed: () async {
                          setState(() => isLoading = true);
                          await saveAndRecalculateStatistics();
                          if (mounted) {
                            Navigator.pop(dialogContext); // Close dialog
                            Navigator.pop(context, true); // Close settings page
                          }
                        },
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> saveAndRecalculateStatistics() async {
    await ConfigurationEntityService.updatePeriodStartingDay(_periodStartingDay);
    await MonthlyCategoryTransactionEntityService.recalculateAllMonthlyCategorySummaries();
    await MonthlyAccountEntityService.recalculateAllMonthlyAccountSummaries();
  }
} 