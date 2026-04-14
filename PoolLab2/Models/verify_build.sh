#!/bin/bash

# Build Verification Script for PoolLab2

echo "🔍 Checking for common build issues..."
echo ""

# Check for internal imports
echo "1️⃣ Checking for 'internal import' issues..."
if grep -r "internal import" --include="*.swift" . 2>/dev/null; then
    echo "❌ Found 'internal import' - these should be regular imports"
else
    echo "✅ No 'internal import' found"
fi
echo ""

# Check for placeholders
echo "2️⃣ Checking for Xcode placeholders..."
if grep -r "<#" --include="*.swift" . 2>/dev/null; then
    echo "❌ Found placeholders - need to be replaced"
else
    echo "✅ No placeholders found"
fi
echo ""

# Check for required imports
echo "3️⃣ Checking file imports..."

check_file_import() {
    local file=$1
    local required_import=$2
    
    if [ -f "$file" ]; then
        if grep -q "$required_import" "$file"; then
            echo "✅ $file has $required_import"
        else
            echo "❌ $file missing $required_import"
        fi
    else
        echo "⚠️  $file not found"
    fi
}

check_file_import "ReminderManager.swift" "import UserNotifications"
check_file_import "ReminderManager.swift" "import Combine"
check_file_import "AnalyticsView.swift" "import Charts"
check_file_import "AnalyticsViewModel.swift" "import Combine"
check_file_import "TaskListView.swift" "import UIKit"

echo ""
echo "4️⃣ Checking Core Data classes..."
for file in *+CoreDataClass.swift; do
    if [ -f "$file" ]; then
        if grep -q "import CoreData" "$file" && ! grep -q "internal import" "$file"; then
            echo "✅ $file"
        else
            echo "❌ $file has import issues"
        fi
    fi
done

echo ""
echo "✅ Verification complete!"
echo ""
echo "Next steps:"
echo "1. Add new Swift files to Xcode target"
echo "2. Clean build folder (⌘⇧K)"
echo "3. Build (⌘B)"

