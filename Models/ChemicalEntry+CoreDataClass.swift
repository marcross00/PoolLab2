import CoreData

@objc(ChemicalEntry)
public class ChemicalEntry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var amount: Double
    @NSManaged public var unit: String?
    @NSManaged public var poolLog: PoolLog?

    public var wrappedType: String {
        type ?? "other"
    }

    public var wrappedUnit: String {
        unit ?? "oz"
    }
}
