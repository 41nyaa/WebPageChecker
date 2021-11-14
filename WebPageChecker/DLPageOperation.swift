//
//  Operations.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2021/09/11.
//

import Foundation
import CoreData

struct DLPageData {
    var body: String
    var lastModified: String
    var etag: String
    var changed: Date
}

class DLPageOperation: Operation {
    enum OperationError: Error {
        case cancelled
        case noupdate
    }

    private let url: String
    
    var result: Result<DLPageData, Error>?
    
    private var downloading = false
    private var downloadTask: URLSessionDataTask?
    
    init(url: String) {
        self.url = url
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return downloading
    }
    
    override var isFinished: Bool {
        return result != nil
    }
    
    override func cancel() {
        super.cancel()
        if let downloadTask = downloadTask {
            downloadTask.cancel()
        }
    }
    
    func finish(result: Result<DLPageData, Error>) {
        guard downloading else { return }
        
        willChangeValue(forKey: #keyPath(isExecuting))
        willChangeValue(forKey: #keyPath(isFinished))
        
        downloading = false
        self.result = result
        downloadTask = nil
        
        didChangeValue(forKey: #keyPath(isFinished))
        didChangeValue(forKey: #keyPath(isExecuting))
    }

    override func start() {
        willChangeValue(forKey: #keyPath(isExecuting))
        downloading = true
        didChangeValue(forKey: #keyPath(isExecuting))
        
        guard !isCancelled else {
            finish(result: .failure(OperationError.cancelled))
            return
        }

        let url = URL(string: self.url)!
        self.downloadTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = error {
                self.finish(result: .failure(OperationError.cancelled))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    let lastModified = self.getHeaderValue(response: httpResponse, name: "Last-Modified")
                    let etag = self.getHeaderValue(response: httpResponse, name: "ETag")
                    
                    if let data = data {
                        let body = String(decoding: data, as: UTF8.self)
                        self.finish(result: .success(DLPageData(body: body, lastModified: lastModified, etag: etag, changed: Date())))
                        return
                    }
                }
            }
            self.finish(result: .failure(OperationError.noupdate))
            return
        }
        self.downloadTask?.resume()
    }
    
    private func getHeaderValue(response: HTTPURLResponse, name: String) -> String
    {
        guard let value = response.allHeaderFields[name] as? String else {
            return ""
        }
        return value
    }
}
