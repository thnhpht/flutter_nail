#!/bin/bash

# Fix duplicate context parameters
fix_context_duplicates() {
    local file="$1"
    echo "Fixing context duplicates in $file..."
    sed -i '' 's/AppWidgets\.showFlushbar(context, context,/AppWidgets.showFlushbar(context,/g' "$file"
}

# Fix all files
fix_context_duplicates "app/lib/screens/services_screen.dart"
fix_context_duplicates "app/lib/screens/employees_screen.dart"
fix_context_duplicates "app/lib/screens/salon_info_screen.dart"
fix_context_duplicates "app/lib/screens/categories_screen.dart"

echo "Fixed all context duplicates"
