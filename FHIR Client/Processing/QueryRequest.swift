//
//  QueryRequest.swift
//  FHIR Client
//
//  Created by Eric Martin on 11/27/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

class QueryRequest: NSObject, URLSessionDataDelegate {
  private var Configuration : URLSessionConfiguration
  private var Semaphore : DispatchSemaphore
  private var Session : URLSession?
  public var ResponseString = ""
  public var Response : URLResponse?
    
  init(semaphore: DispatchSemaphore) {
    self.Semaphore = semaphore
    
    self.Configuration = URLSessionConfiguration.init()
    self.Configuration = URLSessionConfiguration.ephemeral
    self.Configuration.waitsForConnectivity = true

    self.Session = nil
    self.Response = nil
    
    super.init()
    print("Initialized request object")
  }
  
  public func MakeRequest(endPoint: String) {
    print("Making a request")
    if (self.Session == nil) {
      print("Making a session")
      self.Session = URLSession.init(configuration: self.Configuration, delegate: self, delegateQueue: nil)
    }

    print("Setting up the URL request")
    let urlString = endPoint
    let url = URL(string: urlString)
    var request = URLRequest(url: url!);
    request.httpMethod = "GET"
    
    let task = self.Session?.dataTask(with: request)
    
    print("Resuming the task")
    task?.resume();
    print("Task was resumed")
    
  }
  
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    print("Got data")
    
    ResponseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

  }
  
  public func urlSession(_ datatask: URLSessionDataTask, didCompleteWithError: Error?) {
    print("Data task done, not part of protocol?")
  }
  
  public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    print("Became invalid")
  }
  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    print("Received challenge")
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
    print("Delayed request started")
  }

  public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
    print("Waiting for connectivity")
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
    print("Redirection will be performed")
  }
  
  public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    print("Challeged received with completion handler required")
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
    print("New body stream")
  }
  
  public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    print("Body sent")
  }
  
  public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    print("Session Metrics")
  }
  
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    print("Did complete")
    Response = task.response
    print("Notified we're done so signaling semaphore")
    Semaphore.signal()
    print("Semaphore signaled")
  }
  
}
