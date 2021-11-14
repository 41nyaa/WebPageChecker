//
//  PageViewModel.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2021/04/22.
//

import Foundation
import SwiftUI
import CoreData

final class PageViewModel: ObservableObject {
    private var context: NSManagedObjectContext!
    @Published var pages : [PageModel] = []
    @Published var checkedTime = UserDefaults.standard.string(forKey: "checkedTime")
    @Published var timer: Timer? = nil

    init() {
        let container = NSPersistentContainer(name: "WebPageChecker")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load CoreData stack: \(error)")
            }
            self.context = container.viewContext;
            do {
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PageModel")
                self.pages = try self.context.fetch(fetchRequest) as! [PageModel]
            } catch let error as NSError {
                fatalError("Failed to fetch. \(error), \(error.userInfo)")
            }
        }
    }

    func isRegistered(url : String) -> Bool {
        for page in self.pages {
            if page.url == url {
                return true
            }
        }
        return false
    }

    func add(url : String) {
        guard let page: PageModel =
            NSEntityDescription.insertNewObject(forEntityName: "PageModel", into: self.context) as? PageModel else {
                fatalError("Create CoreData Error.")
            }

        let operation = DLPageOperation(url: url)
        let dispatch = DispatchGroup()
        operation.completionBlock = {
            if case let .success(data) = operation.result {
                page.id = UUID()
                page.url = url
                page.body = data.body
                page.lastModified = data.lastModified
                page.etag = data.etag
                page.registered = Date()
                page.changed = PageModel.toChanged(date: page.registered!)
                page.checked = true
                
                self.pages.append(page)
            }
            dispatch.leave()
        }
        dispatch.enter()
        operation.start()
        dispatch.wait()
        save()
    }
    
    func delete(index: Int) {
        let page = pages[index]
        self.context.delete(page)
        save()
        pages.remove(at: index)
    }
    
    func update(id: UUID, data: DLPageData, diffLines: [Int]) {
        for (index, page) in self.pages.enumerated() {
            if page.id == id {
                self.pages[index].lastModified = data.lastModified
                self.pages[index].etag = data.etag
                self.pages[index].body = data.body
                self.pages[index].changed = PageModel.toChanged(date: data.changed)
                self.pages[index].checked = false
                self.pages[index].diffLines = diffLines
                break;
            }
        }
        save()
    }
    
    func beChecked(_ id: UUID) {
        for (index, page) in self.pages.enumerated() {
            if page.id == id {
                self.pages[index].checked = true
                break;
            }
        }
        save()
    }
    
    func save() {
        do {
            try context.save()
        } catch {
            fatalError("Failed to save Page: \(error)")
        }
        updateChangedCount()
    }
    
    private func updateChangedCount() {
        var count: Int = 0
        for page in pages {
            if !page.checked {
                count += 1
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func check() {
        for page in self.pages {
            let operation = DLPageOperation(url: page.url)
            operation.completionBlock = {
                if case let .success(data) = operation.result {
                    if self.isChanged(previous: page, data: data) {
                        let diffLines = self.diff(before: page.body, after: data.body)
                        DispatchQueue.main.async {
                            self.notify(message: page.url + " has beend updated.")
                            self.update(id: page.id, data: data, diffLines: diffLines)
                            self.objectWillChange.send()
                        }
                    }
                }
            }
            operation.start()
        }
        setCheckedTime(status: "Checked Manually at ")
    }
    
    func setCheckedTime(status: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let time = status + dateFormatter.string(from: Date())
        UserDefaults.standard.setValue(time, forKey: "checkedTime")
        self.checkedTime = time
    }
    
    func diff(before: String, after: String) -> [Int]{
        var diffLines: [Int] = []
        if before.count == 0{
            return diffLines
        }
        let beforeLines = before.split(separator: "\n")
        let afterLines = after.split(separator: "\n")
        for (index, afterLine) in afterLines.enumerated() {
            if beforeLines.count - 1 < index {
                diffLines.append(index)
                continue
            }
            if afterLine != beforeLines[index] {
                diffLines.append(index)
            }
        }
        return diffLines
    }
    
    func isChanged(previous: PageModel, data: DLPageData) -> Bool {
        if previous.lastModified != data.lastModified ||
            previous.etag        != data.etag         ||
            previous.body        != data.body {
            return true
        }
        return false
    }
    
    func notify(message: String) {
        let content = UNMutableNotificationContent()
        content.body = NSString.localizedUserNotificationString(forKey: message, arguments: nil)
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
             if let theError = error {
                print(theError)
             }
        }
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(UserDefaults.standard.integer(forKey: "interval")) * 60.0, repeats: true, block: self.timeout)
    }

    func cancelTimer() {
        guard let timer = self.timer else {
            return
        }
        timer.invalidate()
        self.timer = nil
    }

    func timeout(timer: Timer) {
        if self.timer != timer {
            return
        }
        DispatchQueue.main.async {
            self.setCheckedTime(status: "Checked by timer at ")
            self.objectWillChange.send()
        }
        self.check()
    }
}
