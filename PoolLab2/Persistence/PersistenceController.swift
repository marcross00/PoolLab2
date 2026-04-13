import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        for i in 0..<5 {
            let log = PoolLog(context: context)
            log.id = UUID()
            log.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            log.ph = 7.2 + Double(i) * 0.1
            log.fc = 3.0 + Double(i) * 0.5
            log.ta = 80 + Double(i) * 5
            log.ch = 250 + Double(i) * 10
            log.cya = 30 + Double(i) * 2
            log.saltPpm = 3200 + Double(i) * 50

            let chemical = ChemicalEntry(context: context)
            chemical.id = UUID()
            chemical.date = log.date!
            chemical.type = "chlorine"
            chemical.amount = 2.0
            chemical.unit = "oz"
            chemical.poolLog = log
        }

        try? context.save()
        return controller
    }()

    init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        container = NSPersistentContainer(name: "PoolLab2", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // PoolLog entity
        let poolLogEntity = NSEntityDescription()
        poolLogEntity.name = "PoolLog"
        poolLogEntity.managedObjectClassName = NSStringFromClass(PoolLog.self)

        let poolLogId = NSAttributeDescription()
        poolLogId.name = "id"
        poolLogId.attributeType = .UUIDAttributeType

        let poolLogDate = NSAttributeDescription()
        poolLogDate.name = "date"
        poolLogDate.attributeType = .dateAttributeType

        let poolLogPh = NSAttributeDescription()
        poolLogPh.name = "ph"
        poolLogPh.attributeType = .doubleAttributeType
        poolLogPh.defaultValue = 0.0

        let poolLogFc = NSAttributeDescription()
        poolLogFc.name = "fc"
        poolLogFc.attributeType = .doubleAttributeType
        poolLogFc.defaultValue = 0.0

        let poolLogTa = NSAttributeDescription()
        poolLogTa.name = "ta"
        poolLogTa.attributeType = .doubleAttributeType
        poolLogTa.defaultValue = 0.0

        let poolLogCh = NSAttributeDescription()
        poolLogCh.name = "ch"
        poolLogCh.attributeType = .doubleAttributeType
        poolLogCh.defaultValue = 0.0

        let poolLogCya = NSAttributeDescription()
        poolLogCya.name = "cya"
        poolLogCya.attributeType = .doubleAttributeType
        poolLogCya.defaultValue = 0.0

        let poolLogSalt = NSAttributeDescription()
        poolLogSalt.name = "saltPpm"
        poolLogSalt.attributeType = .doubleAttributeType
        poolLogSalt.defaultValue = 0.0

        let poolLogNotes = NSAttributeDescription()
        poolLogNotes.name = "notes"
        poolLogNotes.attributeType = .stringAttributeType
        poolLogNotes.isOptional = true

        // ChemicalEntry entity
        let chemicalEntity = NSEntityDescription()
        chemicalEntity.name = "ChemicalEntry"
        chemicalEntity.managedObjectClassName = NSStringFromClass(ChemicalEntry.self)

        let chemId = NSAttributeDescription()
        chemId.name = "id"
        chemId.attributeType = .UUIDAttributeType

        let chemDate = NSAttributeDescription()
        chemDate.name = "date"
        chemDate.attributeType = .dateAttributeType

        let chemType = NSAttributeDescription()
        chemType.name = "type"
        chemType.attributeType = .stringAttributeType

        let chemAmount = NSAttributeDescription()
        chemAmount.name = "amount"
        chemAmount.attributeType = .doubleAttributeType
        chemAmount.defaultValue = 0.0

        let chemUnit = NSAttributeDescription()
        chemUnit.name = "unit"
        chemUnit.attributeType = .stringAttributeType

        // Relationships
        let poolLogToChemicals = NSRelationshipDescription()
        poolLogToChemicals.name = "chemicals"
        poolLogToChemicals.destinationEntity = chemicalEntity
        poolLogToChemicals.minCount = 0
        poolLogToChemicals.maxCount = 0 // to-many
        poolLogToChemicals.deleteRule = .cascadeDeleteRule

        let chemicalToPoolLog = NSRelationshipDescription()
        chemicalToPoolLog.name = "poolLog"
        chemicalToPoolLog.destinationEntity = poolLogEntity
        chemicalToPoolLog.minCount = 0
        chemicalToPoolLog.maxCount = 1
        chemicalToPoolLog.deleteRule = .nullifyDeleteRule

        poolLogToChemicals.inverseRelationship = chemicalToPoolLog
        chemicalToPoolLog.inverseRelationship = poolLogToChemicals

        poolLogEntity.properties = [
            poolLogId, poolLogDate, poolLogPh, poolLogFc, poolLogTa,
            poolLogCh, poolLogCya, poolLogSalt, poolLogNotes, poolLogToChemicals
        ]

        chemicalEntity.properties = [
            chemId, chemDate, chemType, chemAmount, chemUnit, chemicalToPoolLog
        ]

        model.entities = [poolLogEntity, chemicalEntity]
        return model
    }
}
