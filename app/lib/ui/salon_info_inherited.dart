import 'package:flutter/material.dart';

class SalonInfoInherited extends InheritedWidget {
  final String? salonName;
  final String? salonAddress;
  final String? salonPhone;
  const SalonInfoInherited({
    required Widget child,
    this.salonName,
    this.salonAddress,
    this.salonPhone,
  }) : super(child: child);

  @override
  bool updateShouldNotify(SalonInfoInherited oldWidget) =>
      salonName != oldWidget.salonName ||
      salonAddress != oldWidget.salonAddress ||
      salonPhone != oldWidget.salonPhone;
}