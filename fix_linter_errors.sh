#!/bin/bash

echo "Fixing linter errors in pdf_bill_generator.dart and bill_helper.dart..."

# First, add missing import to pdf_bill_generator.dart
sed -i '' "s|import '../api_client.dart';|import '../api_client.dart';\nimport 'design_system.dart';|g" app/lib/ui/pdf_bill_generator.dart

# Fix all AppWidgets.showFlushbar calls in pdf_bill_generator.dart
# Fix syntax: AppWidgets.showFlushbar(context, type: MessageType.error); errorMessage, 
# Should be: AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);

# Pattern 1: Fix the broken syntax where type is first and message is on next line
sed -i '' '
/AppWidgets\.showFlushbar(context,/{
N
N
N
N
N
s/AppWidgets\.showFlushbar(context, \n *type: MessageType\.error);\n *\([^,]*\), \n *\n *\n *),/AppWidgets.showFlushbar(context, \1, type: MessageType.error);/g
}
' app/lib/ui/pdf_bill_generator.dart

# Pattern 2: Fix more complex broken patterns
sed -i '' '
/AppWidgets\.showFlushbar(context,/{
N
N
N
N
N
N
s/AppWidgets\.showFlushbar(context, \n *type: MessageType\.error);\n *content: Text(\([^)]*\)),\n *backgroundColor: Colors\.[^,]*,\n *),/AppWidgets.showFlushbar(context, \1, type: MessageType.error);/g
}
' app/lib/ui/pdf_bill_generator.dart

# Pattern 3: Fix simple broken patterns
sed -i '' 's/AppWidgets\.showFlushbar(context, \n *type: MessageType\.error);\n *content: Text(\([^)]*\)),\n *\n *),/AppWidgets.showFlushbar(context, \1, type: MessageType.error);/g' app/lib/ui/pdf_bill_generator.dart

# Fix ElevatedButton missing child parameter
sed -i '' '/ElevatedButton(/,/),/{
s/),$/),\n            child: const Text('\''Mở file'\''),/
}' app/lib/ui/pdf_bill_generator.dart

echo "Fixed pdf_bill_generator.dart"

# Now fix bill_helper.dart - add missing import
sed -i '' "s|import 'design_system.dart';|import 'design_system.dart';\nimport 'package:flutter/material.dart' as material;|g" app/lib/ui/bill_helper.dart

echo "Fixed bill_helper.dart"

echo "Done!"
