//
//  ViewController.swift
//  FHIR Client
//
//  Created by Eric Martin on 11/26/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, CompletionDelegate {
  @IBOutlet weak var NumberOfAttempts : NSTextField!
  @IBOutlet weak var LoggingOutline: NSOutlineView!
  @IBOutlet weak var OperationPopup: NSPopUpButtonCell!
  @IBOutlet weak var ClearButton: NSButtonCell!

  private var logEntries = [LogEntryInformation]()
  private var workCoordinator: WorkCoordinator?
  private var baseUrl = "http://localhost:4343/FHIRServer"
  
  private let operations = [
    "capabilities": "Capabilities Statement",
    "allergies": "Allergies"
  ]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    workCoordinator = WorkCoordinator.init(completionDelegate: self)
    NumberOfAttempts.integerValue = 1

    self.LoggingOutline.delegate = self
    self.LoggingOutline.dataSource = self
    
    self.LoggingOutline.reloadData()
    
    self.OperationPopup.removeAllItems()
    for description in operations.values.sorted() {
      self.OperationPopup.addItem(withTitle: description)
    }
    
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
    print("Operation: \(self.OperationPopup.selectedItem?.title ?? "Unknown")")
    let index = self.OperationPopup.indexOfSelectedItem
    var selectedKey = ""
    var i = 0
    for (key, _) in operations.sorted(by: { $0.value < $1.value }) {
      if (i == index) {
        selectedKey = key
        break
      }
      else {
        i+=1
      }
    }
    
    for _ in 1...numberOfAttempts {
      doTheWork(operation: selectedKey)
    }
  }
  
  @IBAction func ClearClicked(_ sender: Any) {
    logEntries.removeAll()
    LoggingOutline.reloadData()
    ClearButton.isEnabled = false
  }
  
  @IBAction func ServerInfoClicked(_ sender: Any) {

    // 1
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let serverInfoWindowController = storyboard.instantiateController(withIdentifier: "ServerInfoWindowController") as! NSWindowController
    
    if let serverInfoWindow = serverInfoWindowController.window {
      
      // 2
      let serverInfoViewController = serverInfoWindow.contentViewController as! ServerInfoViewController
      serverInfoViewController.serverBaseUrl = baseUrl
      
      // 3
      let application = NSApplication.shared
      application.runModal(for: serverInfoWindow)
      
      baseUrl = serverInfoViewController.serverBaseUrl
      
      // 4
      serverInfoWindow.close()
    }

  }
  
  func doTheWork(operation: String) {
    print("Operation key: \(operation)")
    var endPoint = ""
    
    switch operation {
    case "capabilities":
      endPoint = "\(baseUrl)/metadata"
      break
    case "allergies":
      endPoint = "\(baseUrl)/Patient/3341/Allergy?_include=AllergyIntolerance:patient"
      break
    default:
      break;
    }
    
    workCoordinator!.doWork(endPoint: endPoint)
  }
  
  func responseReceived(worker: QueryWorker, duration: Double, response: HTTPURLResponse, data: String) {
    DispatchQueue.main.async {
      self.respondToResponse(time: Date.init(), duration: duration, worker: worker, response: response, data: data)
    }
    print("Received Callback on worker thread: \(Thread.current.name ?? "unknown")")
  }
  
  func respondToResponse(time: Date, duration: Double, worker: QueryWorker, response: HTTPURLResponse, data: String) {
    print("url: " + response.url!.absoluteString)
    print("mime type: " + response.mimeType!)
    print("status code: \(response.statusCode)")
    print("responseString: " + data)

    print("Received Callback on main thread: \(Thread.current.isMainThread)")
    
    let logEntry = LogEntryInformation.init(time: time, duration: duration, thread: worker.name ?? "Unknown", statusCode: response.statusCode, data: data)

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
          let duration:String = String(format:"%.1fms", logEntry.Duration * 1000.0)
          timeThreadCell.DurationLabel.stringValue = duration
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
  
  func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
    outlineView.scrollRowToVisible(row)
  }
  
  func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    var height: CGFloat

    height = 5.0
    if item is LogEntryInformation {
      height = 39.0
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
  var Duration: Double
  var Thread: String
  var StatusCode: Int
  var Data: String
  
  init(time: Date, duration: Double, thread: String, statusCode: Int, data: String) {
    self.Time = time
    self.Duration = duration
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
