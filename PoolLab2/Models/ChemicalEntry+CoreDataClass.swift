import Foundation
public import CoreData

@objc(ChemicalEntry)
public class ChemicalEntry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged @objc dynamic public var date: Date?
    @NSManaged @objc dynamic public var type: String?
    @NSManaged @objc dynamic public var amount: Double
    @NSManaged @objc dynamic public var unit: String?
    @NSManaged @objc dynamic public var poolLog: PoolLog?

    public var wrappedType: String {
        type ?? "other"
    }

    public var wrappedUnit: String {
        unit ?? "oz"
    }
}
