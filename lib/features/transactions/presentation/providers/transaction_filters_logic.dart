import 'package:flutter/material.dart';

class TransactionFiltersLogic extends ChangeNotifier {
  final Set<String> _selectedCategories = <String>{};
  DateTime? _startDate;
  DateTime? _endDate;

  Set<String> get selectedCategories => _selectedCategories;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void selectCategory(String category, {required bool isSelected}) {
    if (isSelected) {
      _selectedCategories.add(category);
    } else {
      _selectedCategories.remove(category);
    }
    notifyListeners();
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategories.clear();
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  Map<String, dynamic> getFilters() => <String, dynamic>{
    'categories': _selectedCategories.toList(),
    'startDate': _startDate,
    'endDate': _endDate,
  };
}
