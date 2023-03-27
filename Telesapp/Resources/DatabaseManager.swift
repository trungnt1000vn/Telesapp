//
//  DatabaseManager.swift
//  Telesapp
//
//  Created by Trung on 15/03/2023.
//

import Foundation
import FirebaseDatabase


final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

}
extension DatabaseManager{
    public func userExists(with email:String,completion:@escaping((Bool)-> Void)){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard  snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    
    ///Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void){
        database.child(user.safeEmail).setValue(["first name": user.firstName,
                                                 "last_name": user.lastName], withCompletionBlock:{ error , _ in
            guard error == nil else{
                print("failed to write to database")
                completion(false)
                return
            }
            /*
             users => [
                [
                    "name":
                    "safe_email":
                ]
             
             ]
             */
            self.database.child("users").observeSingleEvent(of: .value, with: {
                snapshot in
                    if var usersCollection = snapshot.value as? [[String:String]]{
                        //append to user dictionary
                        let newElement: [[String:String]] = [
                            [
                             "name": user.firstName + " " + user.lastName,
                             "email": user.safeEmail
                            ]
                        ]
                        usersCollection.append(contentsOf: newElement)
                        self.database.child("users").setValue(usersCollection,withCompletionBlock: { error , _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                    else{
                        //create that array
                        let newCollection: [[String:String]] = [
                            ["name": user.firstName + " " + user.lastName,
                             "email": user.safeEmail
                            ]
                        ]
                        self.database.child("users").setValue(newCollection,withCompletionBlock: { error , _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
            })
            
            completion(true)
        })
    }
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: {
            snapshot in
            guard let value = snapshot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    public enum DatabaseError: Error{
        case failedToFetch
    }
}

/// MARK : - Sending Messages / conversations
extension DatabaseManager {
    /*
     
     
     Conversation => [
        [
            "conversation_id":
            "other_user_email":
            "lastest_message"" => {
            "date": Date()
            "latest_message": "message"
            "is_read": true/false
     }
        ]
     
     ]
     */
    
    /// Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage : Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let ref = database.child("\"(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard let userNode = snapshot.value as? [String: Any] else{
                    completion(false)
                    print("User not found")
                    return
            }
            if var conversations = userNode["conversations"] as? [[String: Any]]{
                // conversation array exists for current user
                // you should append
            }
            else {
                let newConversationData = [
                    "id": "",
                    "other_user_email": "",
                    
                ]
            }
        })
    }
    /// Fetch and returns all conversations for the user with passed in email
    public func getAllConverssations(for email: String, completion: @escaping (Result<String,Error>) -> Void){
        
    }
    
    /// Get all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String,Error>) -> Void){
        
    }
    
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message,completion: @escaping(Bool) -> Void){
        
    }
}



struct ChatAppUser{
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String{
        return "\(safeEmail)_profile_picture.png"
    }
}
