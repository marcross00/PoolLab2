import Foundation
public import CoreData

@objc(MaintenanceTask)
public class MaintenanceTask: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var intervalDays: Int16
    @NSManaged public var intervalValue: Int16  // New: The numeric value (e.g., 2 for "every 2 weeks")
    @NSManaged public var intervalUnit: String  // New: "day", "week", or "month"
    @NSManaged public var lastCompletedDate: Date
    @NSManaged public var isEnabled: Bool
    @NSManaged public var notes: String?
    
    public var wrappedName: String {
        name 
    }
    
    public var wrappedNotes: String {
        notes ?? ""
    }
    
    public var intervalType: IntervalUnit {
        get { IntervalUnit(rawValue: intervalUnit) ?? .day }
        set { intervalUnit = newValue.rawValue }
    }
    
    public var intervalDescription: String {
        let value = Int(intervalValue)
        let unit = intervalType.displayName(count: value)
        return value == 1 ? "Every \(unit)" : "Every \(value) \(unit)"
    }
    
    public var nextDueDate: Date {
        let calendar = Calendar.current
        let value = Int(intervalValue)
        
        switch intervalType {
        case .day:
            return calendar.date(byAdding: .day, value: value, to: lastCompletedDate) ?? lastCompletedDate
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: value, to: lastCompletedDate) ?? lastCompletedDate
        case .month:
            return calendar.date(byAdding: .month, value: value, to: lastCompletedDate) ?? lastCompletedDate
        }
    }
    
    public var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
    }
    
    public var status: TaskStatus {
        let days = daysUntilDue
        if days < 0 {
            return .overdue
        } else if days == 0 {
            return .dueToday
        } else {
            return .upcoming
        }
    }
    
    public enum TaskStatus {
        case overdue
        case dueToday
        case upcoming
        
        var icon: String {
            switch self {
            case .overdue: return "exclamationmark.circle.fill"
            case .dueToday: return "exclamationmark.triangle.fill"
            case .upcoming: return "checkmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .overdue: return "red"
            case .dueToday: return "orange"
            case .upcoming: return "green"
            }
        }
    }
    
    public enum IntervalUnit: String, CaseIterable {
        case day = "day"
        case week = "week"
        case month = "month"
        
        var displayName: String {
            rawValue
        }
        
        func displayName(count: Int) -> String {
            switch self {
            case .day:
                return count == 1 ? "day" : "days"
            case .week:
                return count == 1 ? "week" : "weeks"
            case .month:
                return count == 1 ? "month" : "months"
            }
        }
        
        var icon: String {
            switch self {
            case .day: return "calendar"
            case .week: return "calendar.badge.clock"
            case .month: return "calendar.badge.plus"
            }
        }
    }
}

extension MaintenanceTask: Identifiable {}
