public import CoreData

@objc(PoolLog)
public class PoolLog: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var ph: Double
    @NSManaged public var fc: Double
    @NSManaged public var ta: Double
    @NSManaged public var ch: Double
    @NSManaged public var cya: Double
    @NSManaged public var saltPpm: Double
    @NSManaged public var notes: String?
    @NSManaged public var chemicals: NSSet?

    public var chemicalsArray: [ChemicalEntry] {
        let set = chemicals as? Set<ChemicalEntry> ?? []
        return set.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    public var wrappedDate: Date {
        date ?? Date()
    }
}
