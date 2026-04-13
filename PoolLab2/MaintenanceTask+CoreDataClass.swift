import Foundation
import CoreData

@objc(MaintenanceTask)
public class MaintenanceTask: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var intervalDays: Int16
    @NSManaged public var lastCompletedDate: Date
    @NSManaged public var isEnabled: Bool
    @NSManaged public var notes: String?
    
    public var wrappedName: String {
        name 
    }
    
    public var wrappedNotes: String {
        notes ?? ""
    }
    
    public var nextDueDate: Date {
        Calendar.current.date(byAdding: .day, value: Int(intervalDays), to: lastCompletedDate) ?? lastCompletedDate
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
}

extension MaintenanceTask: Identifiable {}
