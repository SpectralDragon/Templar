//
//  ViewController.swift
//  CoreDataExample
//
//  Created by Vladislav Prusakov on 06/10/2018.
//  Copyright © 2018 Vladislav Prusakov. All rights reserved.
//

import UIKit

struct MyObject: Persistable, Codable {
    
    typealias Object = MyCodableObject
    
    let name: String
    let desc: String
    let count: String
    var users: [User?]
    
    struct User: Persistable, Codable {
        
        typealias Object = Users
        
        let name: String
        let age: Int
    }
}

class ViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        addObjectToCoreData()
        print("-------------------")
        objectFromStruct()
    }

    
    func addObjectToCoreData() {
        let newObject = MyCodableObject(context: context)
        newObject.name = "\(Date())"
        newObject.desc = "Kuku"
        newObject.count = "Count"
        
        let user = Users(context: context)
        user.name = "Vlad"
        user.age = 21
        newObject.addToUsers(user)
        //        newObject.users = user
        
        do {
            let decoder = ManagedObjectDecoder()
            decoder.includesRelationships = false
            let value = try decoder.decode(MyObject.self, object: newObject)
            print(value)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func objectFromStruct() {
        let object = MyObject(name: "Валера", desc: "Нету", count: "0", users: [MyObject.User(name: "Наташа", age: 45)])
        
        do {
            let encoder = ManagedObjectEncoder()
            let value = try encoder.encode(object, in: self.context)
            print(value)
        } catch {
            print(error.localizedDescription)
        }
    }

}

