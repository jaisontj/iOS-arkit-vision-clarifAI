//
//  HasuraApiHelper.swift
//  ArSample
//
//  Created by Jaison on 19/12/17.
//  Copyright © 2017 Hasura. All rights reserved.
//

import Foundation
import Alamofire

class HasuraApiHelper {
    
    static let sharedInstance = HasuraApiHelper()
    
    static let CLUSTER_NAME = "dualism63"
    
    func getCelebDob(name: String, callback: @escaping(String?, Error?) -> Void) {
        Alamofire.request("https://api." + HasuraApiHelper.CLUSTER_NAME + ".hasura-app.io/celeb_dob?name=" + name)
            .validate()
            .responseJSON { (response) in
                switch response.result {
                case .success(let value):
                    print(value)
                    guard let json: [String: Any] = value as? [String: Any], let birthday = json["birthday"] as? String else {
                        print("unable to convert to json")
                        callback(nil, NSError(domain: "", code: -1, userInfo: [
                            "message": "Unable to convert to json"
                            ]))
                        return
                    }
                    callback(birthday, nil)
                    break
                case .failure(let error):
                    callback(nil, error)
                    break
                }
        }
    }
}
