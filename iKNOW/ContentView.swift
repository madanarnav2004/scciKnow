//
//  ContentView.swift
//  iKNOW
//
//  Created by arnav on 09/04/23.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var responseText = ""
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            TextField("Enter your search query", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchText) { newValue in
                    isAnimating = true
                    getResponseFromOpenAI(query: newValue) { response in
                        DispatchQueue.main.async {
                            responseText = response ?? "Sorry, something went wrong."
                            isAnimating = false
                        }
                    }
                }
            
            Text(responseText)
                .padding()
            
            Spacer()
        }
        .padding(.top, 40)
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .animation(.spring())
        .blur(radius: isAnimating ? 10 : 0)
        .overlay(
            isAnimating ?
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                    .padding() :
                nil
        )
    }
    
    func getResponseFromOpenAI(query: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/engines/davinci-codex/completions") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters = ["prompt": query, "max_tokens": 50, "n": 1, "stop": ["\n"]] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let choices = responseJSON?["choices"] as? [[String: Any]], let text = choices.first?["text"] as? String {
                    completion(text)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
