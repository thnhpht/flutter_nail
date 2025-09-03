# Date Range Picker Feature

## Overview

A user-friendly date range picker has been implemented in the Bills Screen to allow users to filter bills by specific time periods. This feature enhances the user experience by providing quick access to historical data and better data analysis capabilities.

## Features

### 1. Date Range Selection

- **Custom Date Range**: Users can select any custom date range using a calendar-based picker
- **Preset Quick Options**: Quick selection buttons for common time periods:
  - Hôm nay (Today)
  - Hôm qua (Yesterday)
  - Tuần này (This Week)
  - Tháng này (This Month)
  - 30 ngày qua (Last 30 Days)

### 2. Visual Feedback

- **Active State**: Selected date range is highlighted with primary color
- **Clear Button**: Easy way to remove date filter with a red clear button
- **Info Display**: Shows the number of bills found in the selected date range
- **Dynamic Stats**: Statistics cards update to show filtered data

### 3. Filtering Logic

- Bills are filtered based on their `createdAt` date
- Date comparison is done at day level (ignoring time)
- Works in combination with existing search functionality
- Maintains sorting by most recent first

## Implementation Details

### Dependencies Added

- `intl: ^0.19.0` - For date formatting

### Key Components

#### State Management

```dart
DateTimeRange? _selectedDateRange;
```

#### Date Range Picker Method

```dart
Future<void> _selectDateRange() async {
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 1)),
    initialDateRange: _selectedDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    ),
    // Custom theme configuration
  );
}
```

#### Filtering Logic

```dart
// In _filteredOrders getter
if (_selectedDateRange != null) {
  filtered = filtered.where((order) {
    final orderDate = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
    final startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
    final endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);

    return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
           orderDate.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();
}
```

### UI Components

#### Date Range Picker Container

- Card-based design matching the app's design system
- Calendar icon and descriptive label
- Interactive date range display
- Clear button when filter is active

#### Preset Buttons

- Wrap layout for responsive design
- Consistent styling with the app theme
- Quick access to common date ranges

#### Info Display

- Shows filtered results count
- Only appears when date range is selected
- Uses primary color theme

## User Experience

### Workflow

1. User opens Bills Screen
2. Sees preset quick selection buttons
3. Can either:
   - Click a preset button for quick selection
   - Tap the date range field for custom selection
4. Date range picker opens with calendar interface
5. User selects start and end dates
6. Bills list updates automatically
7. Statistics update to reflect filtered data
8. User can clear filter using the red clear button

### Visual States

- **Default**: Shows "Chọn khoảng thời gian" with grey styling
- **Selected**: Shows formatted date range with primary color styling
- **Active Filter**: Displays info banner with filtered count
- **No Results**: Shows appropriate empty state message

## Technical Notes

### Date Handling

- Uses `DateTime` objects for precise date handling
- Compares dates at day level to avoid time-based issues
- Supports date ranges from 2020 to current date + 1 day

### Performance

- Filtering is done in memory for fast response
- No additional API calls required
- Efficient date comparison logic

### Accessibility

- Proper touch targets for mobile interaction
- Clear visual feedback for all states
- Descriptive labels and icons

## Future Enhancements

- Export filtered data to PDF/Excel
- Save favorite date ranges
- Advanced filtering options (by employee, service type)
- Date range analytics and charts
- Bulk operations on filtered bills
