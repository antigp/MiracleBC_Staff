//
//  UserInfo.swift
//  MiracleBC_Staff
//
//  Created by EVGENY ANTROPOV on 16.06.2019.
//  Copyright © 2019 Eugene Antropov. All rights reserved.
//

import SwiftUI
import Moya
import ObjectMapper
import Moya_ObjectMapper
import Combine
import Foundation

struct User: Mappable, Codable {
    
    var userId: String?
    
    // MARK: JSON
    init?(map: Map) {
        userId <- map["userId"]
        guard userId != nil else { return nil }
    }
    
    mutating func mapping(map: Map) {
        userId <- map["userId"]
    }
    
}

struct Identifier<Value>: Hashable {
    let string: String
}

struct UserInfo: Mappable, Identifiable {
    var id: Identifier<UserInfo> {
        return Identifier<UserInfo>(string: userName)
    }
    
    var userName: String!
    var phone: String!
    var discount: String?
    var orders: [Order] = []
    
    init(map: Map) {
        userName <- map["username"]
        phone <- map["phone"]
        orders <- map["orders"]
        discount <- map["discount"]
        
    }
    
    mutating func mapping(map: Map) {
        discount <- map["discount"]
        userName <- map["username"]
        phone <- map["phone"]
        orders <- map["orders"]
    }
}

struct Order: Mappable, Identifiable {
    var id: Identifier<Order> {
        return Identifier<Order>(string: orderId)
    }
    var orderId: String!
    var date: Date!
    var order: String!
    
    init?(map: Map) {
        orderId <- map["id"]
        date <- (map["date"], DateTransform())
        order <- map["order"]
    }
    
    mutating func mapping(map: Map) {
        orderId <- map["id"]
        date <- (map["date"], DateTransform())
        order <- map["order"]
    }
}


class UserInfoViewModel: BindableObject {
    let provider = MoyaProvider<UserActions>(plugins: [NetworkLoggerPlugin()])
    let didChange = PassthroughSubject<UserInfo?,Never>()
    let image: UIImage
    var parent: UserInfoView?
    
    var userInfo: UserInfo?{
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self.userInfo)
            }
        }
    }
    
    init(image: UIImage) {
        self.image = image
        fetch()
    }
    
    func fetch() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.userInfo = UserInfo(JSON: ["username": "Test", "phone": "123", "discount": "5", "orders": [ ["id": "1", "date": 1560629135.0, "order": "Капучино на миндальном молоке"], ["id": "2", "date": 1560626135.0, "order": "Капучино на кокосовом молоке Капучино на соевом молоке"]]])
//        }
//        
        //Делаем запрос на авторизацию
        provider.request(.authorization(image: image)) { (response) in
            switch response.result {
            case let .success(response):
                do {
                    let user = try response.mapObject(User.self)
                    // Делаем запрос на получение данных пользователя
                    self.provider.request(.userInfo(userId: user.userId ?? "")) { (response) in
                        switch response.result {
                        case let .success(response):
                            do {
                                self.userInfo = try response.mapObject(UserInfo.self)
                            } catch let error {
                                // Сервер вернул фигню
                                self.showError(text: error.localizedDescription)
                            }
                        case let .failure(error):
                            // Ошибка соеденения
                            self.showError(text: error.localizedDescription)
                        }
                    }
                } catch let error {
                    // Сервер вернул фигню
                    self.showError(text: error.localizedDescription)
                }
            case let .failure(error):
                // Ошибка соеденения
                self.showError(text: error.localizedDescription)
            }
        }
    }
    
    func showError(text: String){
        let alertVC = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(alertVC, animated: true, completion: nil)
    }
}

struct UserInfoView : View {
    var image: UIImage?
    @ObjectBinding var model: UserInfoViewModel
    @State var loading: Bool = true
    let dateFormatter = DateFormatter()
    
    init(image: UIImage?) {
        self.image = image
        self.model = UserInfoViewModel(image: image!)
        dateFormatter.dateStyle = .short
        self.model.parent = self
    }
    
    var body: some View {
        List {
            HStack {
                Image(uiImage: self.image ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: nil, height: 150, alignment: .center)
                    .background(Color.green)
                VStack {
                    if self.model.userInfo != nil {
                        Text("Имя: \(model.userInfo!.userName)")
                        Text("Телефон: \(model.userInfo!.phone)")
                        Text("Скидка: \(model.userInfo!.discount ?? "") %")
                    } else {
                        Text("Загрузка \(Date())")
                    }
                }
                Spacer()
                
            }
            if self.model.userInfo != nil {
                ForEach(model.userInfo!.orders) { order in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading) {
                            Text("Заказ #\(order.orderId)")
                            Text("От \(self.dateFormatter.string(from: order.date))")
                        }
                        Text(order.order)
                            .lineLimit(nil)
                    }
                }
            }
            Text($model.userInfo.value?.phone ?? "")
        }
    }
}
