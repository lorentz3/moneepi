import 'package:flutter/material.dart';
import 'package:myfinance2/services/configuration_entity_service.dart';
import 'package:myfinance2/widgets/info_label.dart';

class GeneralSettingsPage extends StatefulWidget {
  final double monthlySaving;
  final int periodStartingDay;
  
  const GeneralSettingsPage({super.key, required this.monthlySaving, required this.periodStartingDay});

  @override
  State createState() => GeneralSettingsPageState();
}

class GeneralSettingsPageState extends State<GeneralSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late double _monthlySaving;
  late int _periodStartingDay;
  late int _previousPeriodStartingDay;

  @override
  void initState() {
    super.initState();
    _monthlySaving = widget.monthlySaving;
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
                  InfoLabel(text: "You can set how much money you would like to save each month"),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Monthly saving amount'),
                    initialValue: _monthlySaving == 0.0 ? "" : _monthlySaving.toStringAsFixed(2),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: false,
                      signed: false
                    ),
                    onChanged: (value) => _monthlySaving = double.tryParse(value) ?? 0.00,
                    validator: (value) => value != null && (double.tryParse(value) ?? 0.00) < 0 ? 'The amount must be a positive value' : null,
                  ),
                  SizedBox(height: 30,),
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
      // TODO recalc
    }
    await ConfigurationEntityService.updateMonthlySaving(_monthlySaving);
    await ConfigurationEntityService.updatePeriodStartingDay(_periodStartingDay);
    if (mounted){
      Navigator.pop(context, true);
    }
  }
} 