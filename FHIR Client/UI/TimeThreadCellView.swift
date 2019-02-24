//
//  TimeThreadCellView.swift
//  FHIR Client
//
//  Created by Eric Martin on 1/6/19.
//  Copyright © 2019 Eric Martin. All rights reserved.
//

import Cocoa

class TimeThreadCellView: NSTableCellView {

  @IBOutlet weak var ThreadLabel: NSTextField!
  @IBOutlet weak var TimeLabel: NSTextField!
  @IBOutlet weak var DurationLabel: NSTextField!
  override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
