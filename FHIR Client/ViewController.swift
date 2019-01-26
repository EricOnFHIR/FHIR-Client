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
  @IBOutlet weak var LoggingOutline: NSOutlineView!
  fileprivate var logEntries = [LogEntryInformation]()
  
  @IBOutlet weak var ClearButton: NSButtonCell!
  override func viewDidLoad() {
    super.viewDidLoad()
    workCoordinator = WorkCoordinator.init(completionDelegate: self)
    NumberOfAttempts.integerValue = 1

//    self.LoggingTable.delegate = self
//    self.LoggingTable.dataSource = self
    
    self.LoggingOutline.delegate = self
    self.LoggingOutline.dataSource = self
    
    self.LoggingOutline.reloadData()
    
    ClearButton.isEnabled = false
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
  
  @IBAction func ClearClicked(_ sender: Any) {
    logEntries.removeAll()
    LoggingOutline.reloadData()
    ClearButton.isEnabled = false
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
    
    let logEntry = LogEntryInformation.init(time: time, thread: worker.name ?? "Unknown", statusCode: response.statusCode, data: data)

    logEntries.append(logEntry)
    ClearButton.isEnabled = true
    
    LoggingOutline.reloadData()
  }
  
}

extension ViewController: NSOutlineViewDataSource {
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    //1
    if item is LogEntryInformation {
      return 1
    }
    //2
    return logEntries.count
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if let logEntryInformation = item as? LogEntryInformation {
      return logEntryInformation.Data
    }
    
    return logEntries[index]
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if item is LogEntryInformation {
      return true
    }
    
    return false
  }
}

extension ViewController: NSOutlineViewDelegate {
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    var cell : NSView?
    
    let column = tableColumn?.identifier.rawValue
    if let logEntry = item as? LogEntryInformation {
      switch column {
      case "TimeThreadOutlineColumn":
        if let timeThreadCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TimeThreadOutlineCell"), owner: nil) as? TimeThreadCellView {
          timeThreadCell.ThreadLabel.stringValue = logEntry.Thread
          timeThreadCell.TimeLabel.stringValue = logEntry.getTime()
          cell = timeThreadCell
        }
        else {
          cell = nil
        }
        break
      case "MessageOutlineColumn":
        if let messageCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageOutlineCell"), owner: nil) as? NSTableCellView {
          let statusDescription = HTTPURLResponse.localizedString(forStatusCode: logEntry.StatusCode)
          messageCell.textField?.stringValue = "\(logEntry.StatusCode): \(statusDescription)"
          cell = messageCell
        }
        else {
          cell = nil
        }
        break
      default:
        break
      }
    }
    else if let messageItem = item as? String {
      if (column == "MessageOutlineColumn") {
        if let messageItemCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageItemOutlineCell"), owner: nil) as? NSTableCellView {
          messageItemCell.textField?.stringValue = messageItem
          cell = messageItemCell
        }
        else {
          cell = nil
        }
      }
      else {
        cell = nil
      }
    }
    else {
      cell = nil
    }

    return cell
  }
  
  func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    var height: CGFloat

    height = 5.0
    if item is LogEntryInformation {
      height = 30.0
    }
    else if let messageItem = item as? String {

      if let column = outlineView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageOutlineColumn")) {
        let width = column.width
        
        let cell = NSCell.init(textCell: messageItem);
        cell.font = NSFont.init(name: "Courier New", size: 10.0)
        let unboundedColumnRect = NSRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
        height = cell.cellSize(forBounds: unboundedColumnRect).height + 5.0

      }

    }

    return height
  }
  
  func outlineViewColumnDidResize(_ notification: Notification) {
    if let outlineView = notification.object as? NSOutlineView {
      let indexSet = IndexSet(integersIn: 0...logEntries.count)
      outlineView.noteHeightOfRows(withIndexesChanged: indexSet)
    }
  }
  
}


fileprivate class LogEntryInformation: NSObject {
  var Time: Date
  var Thread: String
  var StatusCode: Int
  var Data: String
  
  init(time: Date, thread: String, statusCode: Int, data: String) {
    self.Time = time
    self.Thread = thread
    self.StatusCode = statusCode
    self.Data = data
    
    super.init()
  }
  
  func getTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    return dateFormatter.string(from: Time)
  }
  
}
