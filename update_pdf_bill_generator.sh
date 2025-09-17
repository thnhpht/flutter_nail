#!/bin/bash

# Update pdf_bill_generator.dart to use flushbar from design system
echo "Updating pdf_bill_generator.dart..."

# Replace ScaffoldMessenger.showSnackBar with AppWidgets.showFlushbar
sed -i '' 's/ScaffoldMessenger\.of(context)\.showSnackBar(/AppWidgets.showFlushbar(context, /g' app/lib/ui/pdf_bill_generator.dart

# Remove SnackBar content and replace with message
sed -i '' 's/SnackBar(/type: MessageType.error);/g' app/lib/ui/pdf_bill_generator.dart
sed -i '' 's/content: Text(errorMessage),/errorMessage, /g' app/lib/ui/pdf_bill_generator.dart
sed -i '' 's/backgroundColor: Colors\.red,//g' app/lib/ui/pdf_bill_generator.dart
sed -i '' 's/duration: const Duration(seconds: 5),//g' app/lib/ui/pdf_bill_generator.dart

echo "Updated pdf_bill_generator.dart"
