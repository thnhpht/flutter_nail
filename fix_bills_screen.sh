#!/bin/bash

# Fix bills_screen.dart
echo "Fixing bills_screen.dart..."

# Remove the local AppWidgets.showFlushbar function definition
sed -i '' '/void AppWidgets\.showFlushbar(context, String message) {/,/^  }$/d' app/lib/screens/bills_screen.dart

echo "Fixed bills_screen.dart"
