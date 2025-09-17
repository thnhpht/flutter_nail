#!/bin/bash

# Update bills_screen.dart to use flushbar from design system
echo "Updating bills_screen.dart..."

# Replace _showErrorSnackBar calls with AppWidgets.showFlushbar
sed -i '' 's/_showErrorSnackBar(/AppWidgets.showFlushbar(context, /g' app/lib/screens/bills_screen.dart

# Remove the local _showErrorSnackBar method
sed -i '' '/void _showErrorSnackBar(String message) {/,/^  }$/d' app/lib/screens/bills_screen.dart

# Add type parameter to the calls
sed -i '' 's/AppWidgets.showFlushbar(context, '\''Lỗi tải dữ liệu: $e'\'');/AppWidgets.showFlushbar(context, '\''Lỗi tải dữ liệu: $e'\'', type: MessageType.error);/g' app/lib/screens/bills_screen.dart
sed -i '' 's/AppWidgets.showFlushbar(context, '\''Không tìm thấy thông tin dịch vụ cho đơn hàng này'\'');/AppWidgets.showFlushbar(context, '\''Không tìm thấy thông tin dịch vụ cho đơn hàng này'\'', type: MessageType.error);/g' app/lib/screens/bills_screen.dart

echo "Updated bills_screen.dart"
