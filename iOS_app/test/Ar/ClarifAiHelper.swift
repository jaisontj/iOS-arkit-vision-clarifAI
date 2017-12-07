//
//  ClarifAIHelper.swift
//  clarifAiAr
//
//  Created by Jaison on 30/11/17.
//  Copyright © 2017 Hasura. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class ClarifAIHelper {
    static let sharedInstance = ClarifAIHelper()
    
    func celebName(image: UIImage, completion: @escaping (String?, Error?) -> Void) {
        print("Clarif ai API call")
        guard let imageData: Data = UIImagePNGRepresentation(image) else {
            print ("Could not convert image to Data")
            completion(nil, NSError(domain: "", code: -1, userInfo: [
                "message": "Could not convert image to Data"
                ]))
            return
        }
        
        let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
        
        let requestParams: Parameters = [
            "inputs": [
                [
                    "data": [
                        "image": [
                            "base64": strBase64
                        ]
                    ]
                ]
            ]
        ]
        
        let requestHeaders: HTTPHeaders = [
            "Authorization": "Key a34ae125f08b489c843f1779f5bbbaae",
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(
            "https://api.clarifai.com/v2/models/e466caa0619f444ab97497640cefc4dc/outputs",
            method: .post,
            parameters: requestParams,
            encoding: JSONEncoding.default,
            headers: requestHeaders
            ).validate()
            .responseJSON { (response) in
                print("Clarif AI -> RESPONSE-----------------------------")
                switch response.result {
                case .failure(let error):
                    print(error)
                    completion(nil, error)
                    break
                case .success(let value):
                    print(value)
                    guard let json: [String: Any] = value as? [String: Any], let outputs = json["outputs"] as? [[String: Any]]  else {
                        print("unable to convert to json")
                        completion(nil, NSError(domain: "", code: -1, userInfo: [
                            "message": "Unable to convert to json"
                            ]))
                        return
                    }
                    
                    var matchedConcept: [String: Any]? = nil
                    
                    for output in outputs {
                        //search for a match of > 0.8
                        guard let data = output["data"] as? [String: Any], let regions = data["regions"] as? [[String: Any]] else {
                            print("unable to find any data/region key in output")
                            completion(nil, NSError(domain: "", code: -1, userInfo: [
                                "message": "Unable to find any data/region key in output"
                                ]))
                            return
                        }
                        for region in regions {
                            guard let regionData = region["data"] as? [String: Any],
                                let face = regionData["face"] as? [String: Any],
                                let identity = face["identity"] as? [String: Any],
                                let concepts = identity["concepts"] as? [[String: Any]] else {
                                    print("Unable to find concepts in response")
                                    completion(nil, NSError(domain: "", code: -1, userInfo: [
                                        "message": "Unable to find concepts in response"
                                        ]))
                                    return
                            }
                            
                            for concept in concepts {
                                if let matchValue = concept["value"] as? Float {
                                    if matchedConcept == nil {
                                        matchedConcept = concept
                                    } else {
                                        let previousMatchedValue = matchedConcept!["value"] as! Float
                                        if (previousMatchedValue < matchValue) {
                                            matchedConcept = concept
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if let matchedConcept = matchedConcept {
                        if let matchValue = matchedConcept["value"] as? Float {
                            //Returns only if matched value is > 0.8
                            if matchValue > 0.8 {
                                completion(matchedConcept["name"] as? String, nil)
                                return
                            }
                        }
                    }
                    completion(nil, nil)
                    break
                }
        }
    }
    
}

