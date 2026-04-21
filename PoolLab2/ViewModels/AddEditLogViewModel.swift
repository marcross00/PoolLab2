import Foundation
import CoreData
import SwiftUI

@Observable
@MainActor
class AddEditLogViewModel {
    var date: Date
    var ph: String
    var fc: String
    var ta: String
    var ch: String
    var cya: String
    var saltPpm: String
    var notes: String
    var chemicalRows: [ChemicalRow]
    
    private let context: NSManagedObjectContext
    private let existingLog: PoolLog?
    
    static let chemicalTypes = [
        "acid",
        "chlorine",
        "salt",
        "ta increaser",
        "ph increaser",
        "calcium",
        "cya",
        "algaecide",
        "clarifier",
        "shock"
    ]
    
    static let unitOptions = [
        "ml",
        "oz",
        "lb",
        "gal",
        "cups",
        "tablets",
        "bags"
    ]
    
    init(context: NSManagedObjectContext, log: PoolLog?) {
        self.context = context
        self.existingLog = log
        
        if let log {
            self.date = log.date ?? Date()
            self.ph = log.phValue.map { String($0) } ?? ""
            self.fc = log.fcValue.map { String($0) } ?? ""
            self.ta = log.taValue.map { String($0) } ?? ""
            self.ch = log.chValue.map { String($0) } ?? ""
            self.cya = log.cyaValue.map { String($0) } ?? ""
            self.saltPpm = log.saltPpmValue.map { String($0) } ?? ""
            self.notes = log.notes ?? ""
            
            self.chemicalRows = log.chemicalsArray.map { chemical in
                ChemicalRow(
                    id: chemical.id ?? UUID(),
                    type: chemical.type ?? "chlorine",
                    amount: String(chemical.amount),
                    unit: chemical.unit ?? "oz"
                )
            }
        } else {
            self.date = Date()
            self.ph = ""
            self.fc = ""
            self.ta = ""
            self.ch = ""
            self.cya = ""
            self.saltPpm = ""
            self.notes = ""
            self.chemicalRows = []
        }
    }
    
    func addChemicalRow() {
        chemicalRows.append(ChemicalRow(type: "acid", amount: "", unit: "ml"))
    }
    
    func removeChemicalRows(at offsets: IndexSet) {
        chemicalRows.remove(atOffsets: offsets)
    }
    
    @discardableResult
    func save() -> Bool {
        let log = existingLog ?? PoolLog(context: context)
        
        if existingLog == nil {
            log.id = UUID()
        }
        
        log.date = date
        log.ph = Double(ph).map { NSNumber(value: $0) }
        log.fc = Double(fc).map { NSNumber(value: $0) }
        log.ta = Double(ta).map { NSNumber(value: $0) }
        log.ch = Double(ch).map { NSNumber(value: $0) }
        log.cya = Double(cya).map { NSNumber(value: $0) }
        log.saltPpm = Double(saltPpm).map { NSNumber(value: $0) }
        log.notes = notes.isEmpty ? nil : notes
        
        // Remove existing chemicals if editing
        if let existingLog {
            existingLog.chemicalsArray.forEach { context.delete($0) }
        }
        
        // Add chemical entries
        for row in chemicalRows {
            guard let amount = Double(row.amount), amount > 0 else { continue }
            
            let chemical = ChemicalEntry(context: context)
            chemical.id = row.id
            chemical.date = date
            chemical.type = row.type
            chemical.amount = amount
            chemical.unit = row.unit
            chemical.poolLog = log
        }
        
        do {
            try context.save()
            return true
        } catch {
            print("Error saving log: \(error)")
            return false
        }
    }
}

struct ChemicalRow: Identifiable, Equatable {
    let id: UUID
    var type: String
    var amount: String
    var unit: String
    
    init(id: UUID = UUID(), type: String, amount: String, unit: String) {
        self.id = id
        self.type = type
        self.amount = amount
        self.unit = unit
    }
}
