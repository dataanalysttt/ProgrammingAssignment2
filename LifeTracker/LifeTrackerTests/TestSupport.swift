import Foundation
import SwiftData
@testable import LifeTracker

enum TestSupport {
    @MainActor
    static func makeInMemoryContext() -> ModelContext {
        let configuration = ModelConfiguration(schema: ModelContainerFactory.schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ModelContainerFactory.schema, configurations: [configuration])
        return ModelContext(container)
    }
}
