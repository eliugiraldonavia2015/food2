import Foundation
import CoreData

@objc(AnalyticsEvent)
public class AnalyticsEvent: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var parameters: Data?
    @NSManaged public var priority: Int16
    @NSManaged public var status: String?
    @NSManaged public var timestamp: Date?
}

extension AnalyticsEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AnalyticsEvent> {
        return NSFetchRequest<AnalyticsEvent>(entityName: "AnalyticsEvent")
    }
}
