public import CoreData

@objc(PoolLog)
public class PoolLog: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var ph: NSNumber?
    @NSManaged public var fc: NSNumber?
    @NSManaged public var ta: NSNumber?
    @NSManaged public var ch: NSNumber?
    @NSManaged public var cya: NSNumber?
    @NSManaged public var saltPpm: NSNumber?
    @NSManaged public var notes: String?
    @NSManaged public var chemicals: NSSet?

    public var chemicalsArray: [ChemicalEntry] {
        let set = chemicals as? Set<ChemicalEntry> ?? []
        return set.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    public var wrappedDate: Date {
        date ?? Date()
    }
    
    // Convenience properties for optional Double values
    public var phValue: Double? {
        ph?.doubleValue
    }
    
    public var fcValue: Double? {
        fc?.doubleValue
    }
    
    public var taValue: Double? {
        ta?.doubleValue
    }
    
    public var chValue: Double? {
        ch?.doubleValue
    }
    
    public var cyaValue: Double? {
        cya?.doubleValue
    }
    
    public var saltPpmValue: Double? {
        saltPpm?.doubleValue
    }
}
// MARK: - Formatting Helpers

extension Optional where Wrapped == Double {
    /// Formats an optional Double value with the specified format, or returns "--" if nil
    /// - Parameter format: The format specifier (e.g., "%.1f")
    /// - Returns: Formatted string or "--"
    public func formatted(with format: String = "%.1f") -> String {
        if let value = self {
            return String(format: format, value)
        } else {
            return "--"
        }
    }
    
    /// Formats an optional Double value with a unit, or returns "--" if nil
    /// - Parameters:
    ///   - format: The format specifier (e.g., "%.1f")
    ///   - unit: The unit string (e.g., "ppm")
    /// - Returns: Formatted string with unit or "--"
    public func formatted(with format: String = "%.1f", unit: String) -> String {
        if let value = self {
            return String(format: format, value) + " " + unit
        } else {
            return "--"
        }
    }
}

