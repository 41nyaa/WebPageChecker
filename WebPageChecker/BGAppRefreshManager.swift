//
//  BGAppRefreshManager.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2021/09/14.
//

import Foundation
import BackgroundTasks
import UserNotifications

final class BGAppRefreshManager {
    private let identifier = "com.app.WebPageChecker.refresh"
    var time: String = ""
    var viewModel: PageViewModel
    
    init(pagevm: PageViewModel) {
        self.viewModel = pagevm
    }
    
    func register() {
        let registResult = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
             self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        if !registResult {
            print("BGTaskScheduler.shared.register error")
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        let interval = UserDefaults.standard.integer(forKey: "interval")
        request.earliestBeginDate = Date(timeIntervalSinceNow: Double(interval) * 60)
        do {
          try BGTaskScheduler.shared.submit(request)
            DispatchQueue.main.async {
                self.viewModel.setCheckedTime(status: "Start by BackgroundRefresh at ")
                self.viewModel.objectWillChange.send()
            }
                // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.WebPageChecker.refresh"]
        } catch {
            print("BGTaskScheduler.shared.submit \(error.localizedDescription)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        print("handleAppRefresh")
        scheduleAppRefresh()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        var operations: [Operation] = []
        for (index, page) in self.viewModel.pages.enumerated() {
            let operation = DLPageOperation(url: page.url)
            operation.completionBlock = {
                if case let .success(data) = operation.result {
                    if self.viewModel.isChanged(previous: page, data: data) {
                        let diffLines = self.viewModel.diff(before: page.body, after: data.body)
                        DispatchQueue.main.async {
                            self.viewModel.notify(message: page.url + " has beend updated.")
                            self.viewModel.update(id: page.id, data: data, diffLines: diffLines)
                        }
                    }
                }
                if index == (self.viewModel.pages.count - 1) {
                    DispatchQueue.main.async {
                        self.viewModel.setCheckedTime(status: "Checked by BackgroundRefresh at ")
                        self.viewModel.objectWillChange.send()
                    }
                }
                task.setTaskCompleted(success: true)
            }
            operations.append(operation)
        }

        task.expirationHandler = {
            queue.cancelAllOperations()
            DispatchQueue.main.async {
                self.viewModel.setCheckedTime(status: "Canceled by BackgroundRefresh at ")
                self.viewModel.objectWillChange.send()
            }
        }

        queue.addOperations(operations, waitUntilFinished: false)
     }

}
