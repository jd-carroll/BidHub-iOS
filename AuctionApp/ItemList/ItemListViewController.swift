//
//  ItemListViewController.swift
//  AuctionApp
//

import UIKit
import SVProgressHUD
import CSNotificationView
import Haneke

extension String {
    subscript (i: Int) -> String {
        return String(Array(self.characters)[i])
    }
}

class ItemListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,ItemTableViewCellDelegate, BiddingViewControllerDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var items:[Item] = [Item]()
    var timer:NSTimer?
    var filterType: FilterType = .All
    var sizingCell: ItemTableViewCell?
    var bottomContraint:NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        SVProgressHUD.setForegroundColor(UIColor(red: 100/225, green: 128/225, blue: 67/225, alpha: 1.0))
        SVProgressHUD.setRingThickness(2.0)
        
        
        let colorView:UIView = UIView(frame: CGRectMake(0, -1000, view.frame.size.width, 1000))
        colorView.backgroundColor = UIColor.whiteColor()
        tableView.addSubview(colorView)

        //Refresh Control
        let refreshView = UIView(frame: CGRect(x: 0, y: 10, width: 0, height: 0))
        tableView.insertSubview(refreshView, aboveSubview: colorView)

        refreshControl.tintColor = UIColor(red: 100/225, green: 128/225, blue: 67/225, alpha: 1.0)
        refreshControl.addTarget(self, action: #selector(ItemListViewController.reloadItems), forControlEvents: .ValueChanged)
        refreshView.addSubview(refreshControl)
        
        
        sizingCell = tableView.dequeueReusableCellWithIdentifier("ItemTableViewCell") as? ItemTableViewCell

        tableView.estimatedRowHeight = 392
        tableView.rowHeight = UITableViewAutomaticDimension

        self.tableView.alpha = 0.0
        reloadData(false, initialLoad: true)

        let user = PFUser.currentUser()
        print("Logged in as: \(user.email)", terminator: "")
        
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ItemListViewController.pushRecieved(_:)), name: "pushRecieved", object: nil)
        timer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: #selector(ItemListViewController.reloadItems), userInfo: nil, repeats: true)
        timer?.tolerance = 10.0
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer?.invalidate()
    }
    
    
    func pushRecieved(notification: NSNotification){
        
        if let aps = notification.object?["aps"] as? [NSObject: AnyObject]{
            if let alert = aps["alert"] as? String {
                CSNotificationView.showInViewController(self, tintColor: UIColor.whiteColor(), font: UIFont(name: "Avenir-Light", size: 14)!, textAlignment: .Center, image: nil, message: alert, duration: 5.0)
                
            }
        }
        reloadData()
        
        
    }
    
    //Hack for selectors and default parameters
    func reloadItems(){
        reloadData()
    }
    
    func reloadData(silent: Bool = true, initialLoad: Bool = false) {
        if initialLoad {
            SVProgressHUD.show()
        }
        DataManager().sharedInstance.getItems{ (items, error) in
        
            if error != nil {
                //Error Case
                if !silent {
                    self.showError("Error getting Items")
                }
                print("Error getting items", terminator: "")
                
            }else{
                self.items = items
                self.filterTable(self.filterType)
            }
            self.refreshControl.endRefreshing()
            
            if initialLoad {
                SVProgressHUD.dismiss()
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.tableView.alpha = 1.0
                })
            }
            
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemTableViewCell", forIndexPath: indexPath) as! ItemTableViewCell
        
        return configureCellForIndexPath(cell, indexPath: indexPath)
    }
    
    func configureCellForIndexPath(cell: ItemTableViewCell, indexPath: NSIndexPath) -> ItemTableViewCell {
        let item = items[indexPath.row];

        cell.itemImageView.hnk_setImageFromURL(NSURL(string: item.imageUrl)!)

        cell.itemProgramNumberLabel.text = "\(item.programNumber)"
        cell.itemTitleLabel.text = item.title
        cell.itemArtistLabel.text = item.artist
        cell.itemMediaLabel.text = item.media
        cell.itemSizeLabel.text = item.size
        cell.itemDescriptionLabel.text = item.itemDesctiption
        cell.itemFmvLabel.text = item.fairMarketValue
        
        if item.quantity > 1 {
            var bidsString = item.currentPrice.map({bidPrice in "$\(bidPrice)"}).joinWithSeparator(", ")
            if bidsString.characters.count == 0 {
                bidsString = "(none yet)"
            }
            
            cell.itemDescriptionLabel.text =
                "\(item.quantity) available! Highest \(item.quantity) bidders win. Current highest bids are \(bidsString)" +
                "\n\n" + cell.itemDescriptionLabel.text!
        }
        cell.delegate = self;
        cell.item = item
        
        var price: Int?
        var lowPrice: Int?

        switch (item.winnerType) {
        case .Single:
            price = item.currentPrice.first
        case .Multiple:
            price = item.currentPrice.first
            lowPrice = item.currentPrice.last
        }
        
        let bidString = (item.numberOfBids == 1) ? "Bid":"Bids"
        cell.numberOfBidsLabel.text = "\(item.numberOfBids) \(bidString)"
        
        if let topBid = price {
            if let lowBid = lowPrice{
                if item.numberOfBids > 1{
                    cell.currentBidLabel.text = "$\(lowBid)-\(topBid)"
                }else{
                    cell.currentBidLabel.text = "$\(topBid)"
                }
            }else{
                cell.currentBidLabel.text = "$\(topBid)"
            }
        }else{
            cell.currentBidLabel.text = "$\(item.price)"
        }
        
        if !item.currentWinners.isEmpty && item.hasBid{
            if item.isWinning{
                cell.setWinning()
            }else{
                cell.setOutbid()
            }
        }else{
            cell.setDefault()
        }
        
        if(item.closeTime.timeIntervalSinceNow < 0.0){
            cell.dateLabel.text = "Sorry, bidding has closed"
            cell.bidNowButton.hidden = true
        }else{
            if(item.openTime.timeIntervalSinceNow < 0.0){
                //open
                cell.dateLabel.text = "Bidding closes \(item.closeTime.relativeTime().lowercaseString)."
                cell.bidNowButton.hidden = false
            }else{
                cell.dateLabel.text = "Bidding opens \(item.openTime.relativeTime().lowercaseString)."
                cell.bidNowButton.hidden = true
            }
        }
        
        return cell
    }
    
    //Cell Delegate
    func cellDidPressBid(item: Item) {
        let bidVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("BiddingViewController") as? BiddingViewController
        if let biddingVC = bidVC {
            biddingVC.delegate = self
            biddingVC.item = item
            addChildViewController(biddingVC)
            view.addSubview(biddingVC.view)
            biddingVC.didMoveToParentViewController(self)
        }
    }

    func cellImageTapped(item: Item) {
        let overlay : UIView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
        
        let url:NSURL = NSURL(string: item.imageUrl)!
        let imageView : UIImageView = UIImageView() // This includes your image in table view cell

        imageView.setImageWithURL(url)
        imageView.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height) // set up according to your requirements
        imageView.contentMode = .ScaleAspectFit
        
        
        let doneBtn : UIButton = UIButton(frame: CGRectMake((self.view.frame.size.width - 53), 30, 48, 48)) // set up according to your requirements
        doneBtn.setImage(UIImage(named: "close.png"), forState: UIControlState.Normal)
        doneBtn.addTarget(self, action: #selector(ItemListViewController.pressedClose(_:)), forControlEvents: .TouchUpInside)
        
        overlay.backgroundColor = UIColor.whiteColor()
        overlay.addSubview(imageView)
        overlay.addSubview(doneBtn)

        navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: true)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
        
        self.view.addSubview(overlay)
    }

    func pressedClose(sender: UIButton!) {
        navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: true)
        sender.superview?.removeFromSuperview()
    }
    
    @IBAction func logoutPressed(sender: AnyObject) {
        PFUser.logOut()
        performSegueWithIdentifier("logoutSegue", sender: nil)
    }
    
    @IBAction func segmentBarValueChanged(sender: AnyObject) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        let segment = sender as! UISegmentedControl
        switch(segment.selectedSegmentIndex) {
            case 0:
              filterTable(.All)
            case 1:
                filterTable(.NoBids)
            case 2:
                filterTable(.MyItems)
            default:
                filterTable(.All)
        }
    }
    
    func filterTable(filter: FilterType) {
        filterType = filter
        self.items = DataManager().sharedInstance.applyFilter(filter)
        self.tableView.reloadData()
    }
    
    func bidOnItem(item: Item, amount: Int) {
        
        SVProgressHUD.show()
        
        DataManager().sharedInstance.bidOn(item, amount: amount) { (success, errorString) -> () in
            if success {
                print("Woohoo", terminator: "")
                self.items = DataManager().sharedInstance.allItems
                self.reloadData()
                SVProgressHUD.dismiss()
            }else{
                self.showError(errorString)
                self.reloadData()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    
    func showError(errorString: String) {
        
        if let _: AnyClass = NSClassFromString("UIAlertController") {
            
            
            //make and use a UIAlertController
            let alertView = UIAlertController(title: "Error", message: errorString, preferredStyle: .Alert)

            let okAction = UIAlertAction(title: "Ok", style: .Default, handler: { (action) -> Void in
                print("Ok Pressed", terminator: "")
            })
            
            alertView.addAction(okAction)
            self.presentViewController(alertView, animated: true, completion: nil)
        }
        else {
            
            //make and use a UIAlertView
            
            let alertView = UIAlertView(title: "Error", message: errorString, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok")
            alertView.show()
        }
    }
    
    
    
    ///Search Bar
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filterTable(.All)
        }else{
            filterTable(.Search(searchTerm:searchText))
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.segmentBarValueChanged(segmentControl)
        searchBar.resignFirstResponder()
    }
    
    ///Bidding VC
    
    func biddingViewControllerDidBid(viewController: BiddingViewController, onItem: Item, amount: Int){
        viewController.view.removeFromSuperview()
        bidOnItem(onItem, amount: amount)
    }
    
    func biddingViewControllerDidCancel(viewController: BiddingViewController){
        viewController.view.removeFromSuperview()
    }
}

