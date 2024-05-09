//
//  NotificationModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.05.2024.
//

import Foundation

struct NotificationModel:Identifiable,Hashable {
    
    var id:String
    var numberOfReminders:String?
    var hasPermission:Bool?
    
}
