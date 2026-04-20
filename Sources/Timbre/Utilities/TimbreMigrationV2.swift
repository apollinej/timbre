import Foundation
import SwiftData

enum TimbreMigrationV2 {
    private static let migrationKey = "timbre.migrationV2.speakerToPerson"

    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        do {
            try migrateSpeakersToPeople(context: context)
            try migrateTranscripts(context: context)
            try createDefaultWorkspace(context: context)
            try context.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            print("[TimbreMigrationV2] Migration failed: \(error)")
        }
    }

    private static func migrateSpeakersToPeople(
        context: ModelContext
    ) throws {
        let speakers = try context.fetch(FetchDescriptor<Speaker>())
        guard !speakers.isEmpty else { return }

        var speakerToPersonMap: [UUID: Person] = [:]
        var personsByName: [String: Person] = [:]

        for speaker in speakers {
            let name = speaker.effectiveName
            if let existing = personsByName[name.lowercased()] {
                // merge: add label as alias
                var aliases = existing.aliases
                if !aliases.contains(speaker.label) {
                    aliases.append(speaker.label)
                    existing.aliases = aliases
                }
                speakerToPersonMap[speaker.id] = existing
            } else {
                let person = Person(
                    canonicalName: name,
                    aliases: [speaker.label],
                    colorHex: speaker.colorHex
                )
                context.insert(person)
                personsByName[name.lowercased()] = person
                speakerToPersonMap[speaker.id] = person
            }
        }

        // Person records created — segments still link via speaker relationship
    }

    private static func migrateTranscripts(context: ModelContext) throws {
        // No-op: transcript property kept its original name.
    }

    private static func createDefaultWorkspace(
        context: ModelContext
    ) throws {
        let existing = try context.fetch(FetchDescriptor<Workspace>())
        guard existing.isEmpty else { return }
        let workspace = Workspace(name: "My Workspace")
        context.insert(workspace)
    }
}
