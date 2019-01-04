//
//  CompletionDelegate.swift
//  FHIR Client
//
//  Created by Eric Martin on 12/17/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

protocol CompletionDelegate: class {
  func responseReceived(worker : QueryWorker, response: HTTPURLResponse, data: String)
}
