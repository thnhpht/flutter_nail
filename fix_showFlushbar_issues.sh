#!/bin/bash

# Fix duplicate AppWidgets.AppWidgets.showFlushbar
fix_duplicates() {
    local file="$1"
    echo "Fixing duplicates in $file..."
    sed -i '' 's/AppWidgets\.AppWidgets\.showFlushbar/AppWidgets.showFlushbar/g' "$file"
}

# Remove local showFlushbar function definitions
remove_local_functions() {
    local file="$1"
    echo "Removing local showFlushbar functions in $file..."
    
    # Remove function definition lines
    sed -i '' '/void AppWidgets\.showFlushbar(context, String message, {MessageType type = MessageType\.info}) {/,/^  }$/d' "$file"
}

# Fix all files
fix_duplicates "app/lib/screens/services_screen.dart"
fix_duplicates "app/lib/screens/employees_screen.dart"
fix_duplicates "app/lib/screens/salon_info_screen.dart"
fix_duplicates "app/lib/screens/categories_screen.dart"

remove_local_functions "app/lib/screens/employees_screen.dart"
remove_local_functions "app/lib/screens/salon_info_screen.dart"

echo "Fixed all showFlushbar issues"
