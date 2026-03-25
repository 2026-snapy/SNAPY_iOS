//
//  UserDTO.swift
//  JeepChak
//
//  Created by GPT on 1/10/26.
//

import Foundation


struct UserMeDTO: Codable {
    let username: Int
    let handle: String
    let firstName: String
    let lastName: String
    let createdAt: String?
    let updatedAt: String?
}

//{
//"username": "강백호",
//"handle": "kangbaekho",
//"email": "[kbh081004@gmail.com](mailto:kbh081004@gmail.com)",
//"phone": "01023844982",
//"password": "hellohellohello"
//}

