//
//  search.swift
//  YAOV2EX
//
//  Created by Yiqin Yao on 27/11/2016.
//  Copyright © 2016 Yiqin Yao. All rights reserved.
//

import Foundation

class Search {
    
    private var dataTask: URLSessionDataTask? = nil
    
    func performSearch(forTopic topic: String) {
        if topic == "hot.json" || topic == "latest.json"
        {
            dataTask?.cancel()
            let url = v2exURL(searchTopic: topic)
            let session = URLSession.shared
            dataTask = session.dataTask(with: url){ data, response, error in
                if let error = error as? NSError, error.code == -999 {
                    return
                }
                if let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200,
                    let jsonData = data {
                        print("Success \(jsonData)")
                }
            }
            dataTask?.resume()
        }
        else
        {
        print("Not Valid!")
        }
    }
    
    private func v2exURL(searchTopic: String) -> URL {
        let urlString = String(format: "https://www.v2ex.com/api/topics/%@", searchTopic)
        let url = URL(string: urlString)
        print("URL: \(url!)")
        return url!
    }

}
