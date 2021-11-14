//
//  PageModel+CoreDataProperties.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2021/09/11.
//
//

import Foundation
import CoreData


extension PageModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageModel> {
        return NSFetchRequest<PageModel>(entityName: "PageModel")
    }

    @NSManaged public var id: UUID
    @NSManaged public var url: String
    @NSManaged public var lastModified: String?
    @NSManaged public var etag: String?
    @NSManaged public var registered: Date?
    @NSManaged public var changed: String
    @NSManaged public var checked: Bool
    @NSManaged public var body: String
    @NSManaged public var diffLines: [Int]

}

extension PageModel : Identifiable {
    
    static func toChanged(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return dateFormatter.string(from: Date())
    }
}
