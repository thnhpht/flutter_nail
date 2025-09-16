import 'package:flutter/material.dart';

class SalonInfoInherited extends InheritedWidget {
  final String? salonName;
  final String? salonAddress;
  final String? salonPhone;
  final String? salonQRCode;

  const SalonInfoInherited({
    required Widget child,
    this.salonName,
    this.salonAddress,
    this.salonPhone,
    this.salonQRCode,
  }) : super(child: child);

  @override
  bool updateShouldNotify(SalonInfoInherited oldWidget) =>
      salonName != oldWidget.salonName ||
      salonAddress != oldWidget.salonAddress ||
      salonPhone != oldWidget.salonPhone ||
      salonQRCode != oldWidget.salonQRCode;

  static SalonInfoInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SalonInfoInherited>();
  }

  static SalonInfoInherited? maybeOf(BuildContext context) {
    return context
        .getElementForInheritedWidgetOfExactType<SalonInfoInherited>()
        ?.widget as SalonInfoInherited?;
  }
}
