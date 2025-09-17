#!/bin/bash

# Fix reports_screen.dart
echo "Fixing reports_screen.dart..."

# Remove the local AppWidgets.showFlushbar function definition
sed -i '' '/void AppWidgets\.showFlushbar(context, String message) {/,/^  }$/d' app/lib/screens/reports_screen.dart

echo "Fixed reports_screen.dart"
