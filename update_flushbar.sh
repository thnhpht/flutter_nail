#!/bin/bash

# Update login_screen.dart
sed -i '' 's/import '\''package:another_flushbar\/flushbar.dart'\'';//g' app/lib/screens/login_screen.dart
sed -i '' '/enum MessageType { success, error, info, warning }/d' app/lib/screens/login_screen.dart
sed -i '' 's/import '\''..\/models.dart'\'';/import '\''..\/models.dart'\'';\nimport '\''..\/ui\/design_system.dart'\'';/g' app/lib/screens/login_screen.dart

# Update services_screen.dart
sed -i '' 's/import '\''package:another_flushbar\/flushbar.dart'\'';//g' app/lib/screens/services_screen.dart
sed -i '' '/enum MessageType { success, error, warning, info }/d' app/lib/screens/services_screen.dart

# Update salon_info_screen.dart
sed -i '' 's/import '\''package:another_flushbar\/flushbar.dart'\'';//g' app/lib/screens/salon_info_screen.dart
sed -i '' '/enum MessageType { success, error, warning, info }/d' app/lib/screens/salon_info_screen.dart

# Update categories_screen.dart
sed -i '' 's/import '\''package:another_flushbar\/flushbar.dart'\'';//g' app/lib/screens/categories_screen.dart
sed -i '' '/enum MessageType { success, error, warning, info }/d' app/lib/screens/categories_screen.dart

# Update employees_screen.dart
sed -i '' 's/import '\''package:another_flushbar\/flushbar.dart'\'';//g' app/lib/screens/employees_screen.dart
sed -i '' '/enum MessageType { success, error, warning, info }/d' app/lib/screens/employees_screen.dart

echo "Updated all screen files to use design system"
