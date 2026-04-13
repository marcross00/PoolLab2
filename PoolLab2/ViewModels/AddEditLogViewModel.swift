import Foundation
import CoreData

struct ChemicalRow: Identifiable {
    let id = UUID()
    var type: String = "chlorine"
    var amount: String = ""
    var unit: String = "oz"
}

@Observable
final class AddEditLogViewModel {
    var ph: String = ""
    var fc: String = ""
    var ta: String = ""
    var ch: String = ""
    var cya: String = ""
    var saltPpm: String = ""
    var notes: String = ""
    var date: Date = Date()
    var chemicalRows: [ChemicalRow] = []

    private var existingLog: PoolLog?
    private let context: NSManagedObjectContext

    static let chemicalTypes = ["acid", "chlorine", "salt", "other"]
    static let unitOptions = ["ml", "oz", "lbs", "gal", "cups"]

    init(context: NSManagedObjectContext, log: PoolLog? = nil) {
        self.context = context
        self.existingLog = log

        if let log {
            ph = log.ph == 0 ? "" : String(log.ph)
            fc = log.fc == 0 ? "" : String(log.fc)
            ta = log.ta == 0 ? "" : String(log.ta)
            ch = log.ch == 0 ? "" : String(log.ch)
            cya = log.cya == 0 ? "" : String(log.cya)
            saltPpm = log.saltPpm == 0 ? "" : String(log.saltPpm)
            notes = log.notes ?? ""
            date = log.wrappedDate

            chemicalRows = log.chemicalsArray.map { entry in
                var row = ChemicalRow(type: entry.wrappedType, unit: entry.wrappedUnit)
                row.amount = entry.amount == 0 ? "" : String(entry.amount)
                return row
            }
        }
    }

    func addChemicalRow() {
        chemicalRows.append(ChemicalRow())
    }

    func removeChemicalRows(at offsets: IndexSet) {
        chemicalRows.remove(atOffsets: offsets)
    }

    func save() -> Bool {
        let log = existingLog ?? PoolLog(context: context)

        if existingLog == nil {
            log.id = UUID()
        }

        log.date = date
        log.ph = Double(ph) ?? 0
        log.fc = Double(fc) ?? 0
        log.ta = Double(ta) ?? 0
        log.ch = Double(ch) ?? 0
        log.cya = Double(cya) ?? 0
        log.saltPpm = Double(saltPpm) ?? 0
        log.notes = notes.isEmpty ? nil : notes

        // Remove existing chemicals when editing
        if let existing = log.chemicals as? Set<ChemicalEntry> {
            for entry in existing {
                context.delete(entry)
            }
        }

        // Add new chemicals
        for row in chemicalRows {
            guard let amount = Double(row.amount), amount > 0 else { continue }
            let entry = ChemicalEntry(context: context)
            entry.id = UUID()
            entry.date = date
            entry.type = row.type
            entry.amount = amount
            entry.unit = row.unit
            entry.poolLog = log
        }

        do {
            try context.save()
            return true
        } catch {
            print("Failed to save: \(error.localizedDescription)")
            return false
        }
    }
}
