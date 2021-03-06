//
//  Item.swift
//  AuctionApp
//

import UIKit

enum ItemWinnerType {
    case Single
    case Multiple
}

class Item: PFObject, PFSubclassing {
    
    @NSManaged var name:String
    @NSManaged var price:Int
    
    var priceIncrement:Int {
        get {
            if let priceIncrementUW = self["priceIncrement"] as? Int {
                return priceIncrementUW
            }else{
                return 5
            }
        }
    }
    
    var currentPrice:[Int] {
        get {
            if let array = self["currentPrice"] as? [Int] {
                return array
            }else{
                return [Int]()
            }
        }
        set {
            self["currentPrice"] = newValue
        }
    }
    
    var currentWinners:[String] {
        get {
            if let array = self["currentWinners"] as? [String] {
                return array
            }else{
                return [String]()
            }
        }
        set {
            self["currentWinners"] = newValue
        }
    }

    var allBidders:[String] {
        get {
            if let array = self["allBidders"] as? [String] {
                return array
            }else{
                return [String]()
            }
        }
        set {
            self["allBidders"] = newValue
        }
    }
    
    var numberOfBids:Int {
        get {
            if let numberOfBidsUW = self["numberOfBids"] as? Int {
                return numberOfBidsUW
            }else{
                return 0
            }
        }
        set {
            self["numberOfBids"] = newValue
        }
    }

    
    var donorName:String {
        get {
            if let donor =  self["donorname"] as? String{
                return donor
            }else{
                return ""
            }
        }
        set {
            self["donorname"] = newValue
        }
    }

    var artist:String {
        get {
            if let artistName =  self["artist"] as? String{
                return artistName
            }else{
                return ""
            }
        }
        set {
            self["artist"] = newValue
        }
    }
    
    var programNumber:Int {
        get {
            if let programNumberString =  self["programNumber"] as? Int{
                return programNumberString
            }else{
                return -1
            }
        }
        set {
            self["programNumber"] = newValue
        }
    }
    
    var title:String {
        get {
            if let titleString =  self["title"] as? String{
                return titleString
            }else{
                return ""
            }
        }
        set {
            self["title"] = newValue
        }
    }
    
    var media:String {
        get {
            if let mediaType =  self["media"] as? String{
                return mediaType
            }else{
                return ""
            }
        }
        set {
            self["media"] = newValue
        }
    }
    
    var size:String {
        get {
            if let sizeString =  self["size"] as? String{
                return sizeString
            }else{
                return ""
            }
        }
        set {
            self["size"] = newValue
        }
    }
    
    var imageUrl:String {
        get {
            if let imageURLString = self["imageurl"] as? String {
                return imageURLString
            }else{
                return ""
            }
        }
        set {
            self["imageurl"] = newValue
        }
    }

    var itemDesctiption:String {
        get {
            if let desc = self["description"] as? String {
                return desc
            }else{
                return ""
            }
        }
        set {
            self["description"] = newValue
        }
    }

    var fairMarketValue:String {
        get {
            if let fmv = self["fmv"] as? String {
                return "Fair Market Value: " + fmv
            }else{
                return ""
            }
        }
        set {
            self["fmv"] = newValue
        }
    }
    
    var quantity: Int {
        get {
            if let quantityUW =  self["qty"] as? Int{
                return quantityUW
            }else{
                return 0
            }
        }
        set {
            self["qty"] = newValue
        }
    }

    var openTime: NSDate {
        get {
            if let open =  self["opentime"] as? NSDate{
                return open
            }else{
                return NSDate()
            }
        }
    }
    
    var closeTime: NSDate {
        get {
            if let close =  self["closetime"] as? NSDate{
                return close
            }else{
                return NSDate()
            }
        }
    }
    
    var winnerType: ItemWinnerType {
        get {
            if quantity > 1 {
                return .Multiple
            }else{
                return .Single
            }
        }
    }

    var minimumBid: Int {
        get {
            if !currentPrice.isEmpty {
                return currentPrice.minElement()!
            }else{
                return price
            }
        }
    }
    
    var isWinning: Bool {
        get {
            let user = PFUser.currentUser()
            return currentWinners.contains(user.email)
        }
    }
    
    
    var hasBid: Bool {
        get {
            let user = PFUser.currentUser()
            return allBidders.contains(user.email)
        }
    }
    
    override class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            self.registerSubclass()
        }
    }
    
    class func parseClassName() -> String! {
        return "Item"
    }
}


