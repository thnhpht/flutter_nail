#!/bin/bash

# Function to update showFlushbar calls in a file
update_file() {
    local file="$1"
    echo "Updating $file..."
    
    # Replace showFlushbar calls with AppWidgets.showFlushbar
    sed -i '' 's/showFlushbar(/AppWidgets.showFlushbar(context, /g' "$file"
    
    # Fix the closing parenthesis and add context parameter
    sed -i '' 's/AppWidgets.showFlushbar(context, \([^)]*\))/AppWidgets.showFlushbar(context, \1)/g' "$file"
}

# Update all screen files
update_file "app/lib/screens/services_screen.dart"
update_file "app/lib/screens/salon_info_screen.dart"
update_file "app/lib/screens/categories_screen.dart"
update_file "app/lib/screens/employees_screen.dart"

echo "Updated all showFlushbar calls to use AppWidgets.showFlushbar"
