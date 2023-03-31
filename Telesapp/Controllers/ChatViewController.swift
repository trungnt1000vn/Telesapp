//
//  ChatViewController.swift
//  Telesapp
//
//  Created by Trung on 23/03/2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
struct Message: MessageType{
    public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
}
extension MessageKind {
    var messageKindString: String {
        switch  self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType{
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController{
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private let conversationId: String?
    
    public var isNewConversation = false
    
    public let otherUserEmail: String
    
    private var messages = [Message]()
    
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
      return Sender(photoURL: "",
             senderId: safeEmail,
             displayName: "Me")
    }
   
    
    init(with email: String,id : String?){
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
      
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    private func listenForMessages(id: String, shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: {
            [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                
                DispatchQueue.main.async {
                        self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom{
                        self?.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
                
                
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        })
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId{
            listenForMessages(id: conversationId,shouldScrollToBottom: true)
        }
    }
}
extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " " , with: "").isEmpty,
        let selfSender = self.selfSender ,
            let messageId = createMessageId() else{
            return
        }
        print("Sending: \(text)")
        let message = Message(sender: selfSender,
                              messageId: messageId ,
                              sentDate: Date(),
                              kind: .text(text))
        //Send Message
        if isNewConversation{
            //create conver in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success{
                    print ("Message sent")
                    self?.isNewConversation = false
                }
                else{
                    print("Failed to send")
                }
            })
        }
        else{
            guard let conversationId = conversationId,
            let name = self.title
            else{
                return
            }
            //append to existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationId,otherUserEmail: otherUserEmail,name :name, newMessage: message, completion: { success in
                if(success){
                    print("message sent")
                }
                else{
                    print("failed to sent")
                }
            })
            
        }
    }
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
    
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("Created message id : \(newIdentifier)")
        return newIdentifier
    }
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender{
            return sender
        }
        
        fatalError(" Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
