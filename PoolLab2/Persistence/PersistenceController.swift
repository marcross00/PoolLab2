internal import CoreData

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
            log.ph = NSNumber(value: 7.2 + Double(i) * 0.1)
            log.fc = NSNumber(value: 3.0 + Double(i) * 0.5)
            log.ta = NSNumber(value: 80 + Double(i) * 5)
            log.ch = NSNumber(value: 250 + Double(i) * 10)
            log.cya = NSNumber(value: 30 + Double(i) * 2)
            log.saltPpm = NSNumber(value: 3200 + Double(i) * 50)

            let chemical = ChemicalEntry(context: context)
            chemical.id = UUID()
            chemical.date = log.date!
            chemical.type = "chlorine"
            chemical.amount = 2.0
            chemical.unit = "oz"
            chemical.poolLog = log
        }
        
        // Sample maintenance tasks
        let task1 = MaintenanceTask(context: context)
        task1.id = UUID()
        task1.name = "Check pH"
        task1.intervalValue = 3
        task1.intervalUnit = "day"
        task1.intervalDays = 3  // Keep for backwards compatibility
        task1.lastCompletedDate = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        task1.isEnabled = true
        
        let task2 = MaintenanceTask(context: context)
        task2.id = UUID()
        task2.name = "Check Total Alkalinity"
        task2.intervalValue = 2
        task2.intervalUnit = "week"
        task2.intervalDays = 14  // Keep for backwards compatibility
        task2.lastCompletedDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        task2.isEnabled = true
        
        let task3 = MaintenanceTask(context: context)
        task3.id = UUID()
        task3.name = "Check CYA"
        task3.intervalValue = 1
        task3.intervalUnit = "month"
        task3.intervalDays = 30  // Keep for backwards compatibility
        task3.lastCompletedDate = Date()
        task3.isEnabled = false
        task3.notes = "Check at the beginning of each season"

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

        // MaintenanceTask entity
        let taskEntity = NSEntityDescription()
        taskEntity.name = "MaintenanceTask"
        taskEntity.managedObjectClassName = NSStringFromClass(MaintenanceTask.self)
        
        let taskId = NSAttributeDescription()
        taskId.name = "id"
        taskId.attributeType = .UUIDAttributeType
        
        let taskName = NSAttributeDescription()
        taskName.name = "name"
        taskName.attributeType = .stringAttributeType
        
        let taskInterval = NSAttributeDescription()
        taskInterval.name = "intervalDays"
        taskInterval.attributeType = .integer16AttributeType
        taskInterval.defaultValue = 7
        
        let taskIntervalValue = NSAttributeDescription()
        taskIntervalValue.name = "intervalValue"
        taskIntervalValue.attributeType = .integer16AttributeType
        taskIntervalValue.defaultValue = 1
        
        let taskIntervalUnit = NSAttributeDescription()
        taskIntervalUnit.name = "intervalUnit"
        taskIntervalUnit.attributeType = .stringAttributeType
        taskIntervalUnit.defaultValue = "day"
        
        let taskLastCompleted = NSAttributeDescription()
        taskLastCompleted.name = "lastCompletedDate"
        taskLastCompleted.attributeType = .dateAttributeType
        
        let taskEnabled = NSAttributeDescription()
        taskEnabled.name = "isEnabled"
        taskEnabled.attributeType = .booleanAttributeType
        taskEnabled.defaultValue = true
        
        let taskNotes = NSAttributeDescription()
        taskNotes.name = "notes"
        taskNotes.attributeType = .stringAttributeType
        taskNotes.isOptional = true
        
        taskEntity.properties = [
            taskId, taskName, taskInterval, taskIntervalValue, taskIntervalUnit, 
            taskLastCompleted, taskEnabled, taskNotes
        ]

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
        poolLogPh.isOptional = true

        let poolLogFc = NSAttributeDescription()
        poolLogFc.name = "fc"
        poolLogFc.attributeType = .doubleAttributeType
        poolLogFc.isOptional = true

        let poolLogTa = NSAttributeDescription()
        poolLogTa.name = "ta"
        poolLogTa.attributeType = .doubleAttributeType
        poolLogTa.isOptional = true

        let poolLogCh = NSAttributeDescription()
        poolLogCh.name = "ch"
        poolLogCh.attributeType = .doubleAttributeType
        poolLogCh.isOptional = true

        let poolLogCya = NSAttributeDescription()
        poolLogCya.name = "cya"
        poolLogCya.attributeType = .doubleAttributeType
        poolLogCya.isOptional = true

        let poolLogSalt = NSAttributeDescription()
        poolLogSalt.name = "saltPpm"
        poolLogSalt.attributeType = .doubleAttributeType
        poolLogSalt.isOptional = true

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

        model.entities = [taskEntity, poolLogEntity, chemicalEntity]
        return model
    }
}
