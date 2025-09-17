#!/bin/bash

# Update bill_helper.dart to use flushbar from design system
echo "Updating bill_helper.dart..."

# Replace ScaffoldMessenger.showSnackBar with AppWidgets.showFlushbar
sed -i '' 's/ScaffoldMessenger\.of(context)\.showSnackBar(/AppWidgets.showFlushbar(context, /g' app/lib/ui/bill_helper.dart

# Remove the SnackBar content and replace with message
sed -i '' 's/const SnackBar(/type: MessageType.error);/g' app/lib/ui/bill_helper.dart
sed -i '' 's/content: Text('\''Không tìm thấy thông tin dịch vụ cho đơn hàng này'\''),/'\''Không tìm thấy thông tin dịch vụ cho đơn hàng này'\'', /g' app/lib/ui/bill_helper.dart
sed -i '' 's/backgroundColor: Colors\.red,//g' app/lib/ui/bill_helper.dart

echo "Updated bill_helper.dart"
