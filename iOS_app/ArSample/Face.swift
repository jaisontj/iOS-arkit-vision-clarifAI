//
//  Face.swift
//  clarifAiAr
//
//  Created by Jaison on 01/12/17.
//  Copyright © 2017 Hasura. All rights reserved.
//

import Foundation
import ARKit

class Face {
    var name: String?
    let isIdentifying = true
    let node: FaceNode
    var hidden: Bool {
        get{
            return node.opacity != 1
        }
    }
    var timestamp: TimeInterval {
        didSet {
            updated = Date()
        }
    }
    private(set) var updated = Date()
    
    init(name: String, node: FaceNode, timestamp: TimeInterval) {
        self.name = name
        self.node = node
        self.timestamp = timestamp
    }
    
    init(node: FaceNode, timestamp: TimeInterval) {
        self.node = node
        self.timestamp = timestamp
        self.name = nil
        
        //Fetch name from clarifAi
        ClarifAIHelper.sharedInstance.celebName(image: self.node.nodeImage) { (name, error) in
            if let name = name {
                HasuraApiHelper.sharedInstance.getCelebDob(name: name) { (dob, error) in
                    if let dob = dob {
                        self.node.textView.string = name + "-" + dob
                        self.name = name
                    } else {
                        print("Hasura API Failed")
                        print(error ?? "Unable to print error")
                        self.node.textView.string = name
                    }
                }
            } else {
                print("ClarifAi failed")
                print(error ?? "Unable to print error")
                self.node.textView.string = "Unidentified"
            }
            self.node.show()
            self.updated = Date()
        }
    }
}

extension Date {
    func isAfter(seconds: Double) -> Bool {
        let elapsed = Date.init().timeIntervalSince(self)
        
        if elapsed > seconds {
            return true
        }
        return false
    }
}

