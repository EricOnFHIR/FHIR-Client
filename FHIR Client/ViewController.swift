//
//  ViewController.swift
//  FHIR Client
//
//  Created by Eric Martin on 11/26/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, CompletionDelegate {
  var workCoordinator : WorkCoordinator?
  @IBOutlet weak var NumberOfAttempts : NSTextField!
  @IBOutlet weak var LoggingTable: NSTableView!
  fileprivate var loggingTimeThreads = [TimeThreadInformation]()
  fileprivate var loggingMessages = [String]()

  override func viewDidLoad() {
    super.viewDidLoad()
    workCoordinator = WorkCoordinator.init(completionDelegate: self)
    NumberOfAttempts.integerValue = 1

    self.LoggingTable.delegate = self
    self.LoggingTable.dataSource = self
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }

  @IBAction func QueryClicked(_ sender: Any) {
    
    let numberOfAttempts = NumberOfAttempts.integerValue
    print("Requested Attempts: \(numberOfAttempts)")
    for _ in 1...numberOfAttempts {
      doTheWork()
    }
    
  }
  
  func doTheWork() {
    workCoordinator!.doWork(endPoint: "http://localhost:4343/FHIRServer/Patient/3341/Allergy?_include=AllergyIntolerance:patient")
  }
  
  func responseReceived(worker: QueryWorker, response: HTTPURLResponse, data: String) {
    DispatchQueue.main.async {
      self.respondToResponse(time: Date.init(), worker: worker, response: response, data: data)
    }
    print("Received Callback on worker thread: \(Thread.current.name ?? "unknown")")
  }
  
  func respondToResponse(time: Date, worker: QueryWorker, response: HTTPURLResponse, data: String) {
    print("url: " + response.url!.absoluteString)
    print("mime type: " + response.mimeType!)
    print("status code: \(response.statusCode)")
    print("responseString: " + data)

    print("Received Callback on main thread: \(Thread.current.isMainThread)")
    
    loggingTimeThreads.append(TimeThreadInformation.init(time: time, thread: worker.name ?? "Unknown"))
    loggingMessages.append("\(response.statusCode)")
    
    LoggingTable.reloadData()
  }
  
  func logInformation(information : String) {
    DispatchQueue.main.async {
    }
  }
  
}

extension ViewController:NSTableViewDataSource {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return loggingTimeThreads.count
  }
  
}

extension ViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var cell : NSView?
    
    let column = tableColumn?.identifier.rawValue
    switch column {
    case "TimeThread":
      if let messageCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TimeThreadCell"), owner: nil) as? TimeThreadCellView {
        messageCell.ThreadLabel.stringValue = loggingTimeThreads[row].Thread
        messageCell.TimeLabel.stringValue = loggingTimeThreads[row].getTime()
        cell = messageCell
      }
      else {
        cell = nil
      }
      break
    case "Message":
      if let messageCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageCell"), owner: nil) as? NSTableCellView {
        messageCell.textField?.stringValue = loggingMessages[row]
        cell = messageCell
      }
      else {
        cell = nil
      }
      break
    default:
      cell = nil
      break;
    }

    return cell
  }
  
}

fileprivate class TimeThreadInformation : NSObject {
  var Time : Date
  var Thread : String
  
  init(time: Date, thread: String) {
    self.Time = time
    self.Thread = thread
    
    super.init()
  }
  
  func getTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    return dateFormatter.string(from: Time)
  }
  
}
