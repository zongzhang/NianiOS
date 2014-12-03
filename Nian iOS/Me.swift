//
//  YRJokeTableViewController.swift
//  JokeClient-Swift
//
//  Created by YANGReal on 14-6-5.
//  Copyright (c) 2014年 YANGReal. All rights reserved.
//

import UIKit

class MeViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    let identifier = "me"
    var tableView:UITableView?
    var dataArray = NSMutableArray()
    var page :Int = 0
    var Id:String = ""
    
    func noticeShare(noti:NSNotification){
        self.tableView!.headerBeginRefreshing()
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        setupViews()
        setupRefresh()
        SAReloadData()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "noticeShare", object:nil)
    }
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "noticeShare:", name: "noticeShare", object: nil)
    }
    
    func setupViews()
    {
        
        var navView = UIView(frame: CGRectMake(0, 0, globalWidth, 64))
        navView.backgroundColor = BarColor
        self.view.addSubview(navView)
        
        self.tableView = UITableView(frame:CGRectMake(0, 64, globalWidth, globalHeight - 64 - 49))
        self.tableView!.delegate = self;
        self.tableView!.dataSource = self;
        self.tableView!.backgroundColor = BGColor
        self.tableView!.separatorStyle = UITableViewCellSeparatorStyle.None
        var nib = UINib(nibName:"MeCell", bundle: nil)
        
        self.tableView!.registerNib(nib, forCellReuseIdentifier: identifier)
        self.tableView!.tableHeaderView = UIView(frame: CGRectMake(0, 0, globalWidth, 10))
        self.tableView!.tableFooterView = UIView(frame: CGRectMake(0, 0, globalWidth, 20))
        self.view.addSubview(self.tableView!)
    }
    
    
    func loadData(){
        var url = urlString()
        SAHttpRequest.requestWithURL(url,completionHandler:{ data in
            if data as NSObject != NSNull(){
                if ( data["total"] as Int ) < 30 {
                    self.tableView!.setFooterHidden(true)
                }
                var arr = data["items"] as NSArray
                for data : AnyObject  in arr{
                    self.dataArray.addObject(data)
                }
                self.tableView!.reloadData()
                self.tableView!.footerEndRefreshing()
                self.page++
            }
        })
    }
    func SAReloadData(){
        self.page = 0
        var url = urlString()
        self.tableView!.setFooterHidden(false)
        SAHttpRequest.requestWithURL(url,completionHandler:{ data in
            if data as NSObject != NSNull(){
                if ( data["total"] as Int ) < 30 {
                    self.tableView!.setFooterHidden(true)
                }
                var arr = data["items"] as NSArray
                self.dataArray.removeAllObjects()
                for data : AnyObject  in arr{
                    self.dataArray.addObject(data)
                }
                self.tableView!.reloadData()
                self.tableView!.headerEndRefreshing()
                self.page++
            }
        })
    }
    
    
    func urlString()->String{
        var Sa:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var safeuid = Sa.objectForKey("uid") as String
        var safeshell = Sa.objectForKey("shell") as String
        return "http://nian.so/api/me.php?page=\(page)&uid=\(safeuid)&shell=\(safeshell)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as? MeCell
        var index = indexPath.row
        var data = self.dataArray[index] as NSDictionary
        cell!.data = data
        cell!.avatarView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "userclick:"))
        
        if indexPath.row == self.dataArray.count - 1 {
            cell!.viewLine.hidden = true
        }else{
            cell!.viewLine.hidden = false
        }
        
        return cell!
    }
    
    func userclick(sender:UITapGestureRecognizer){
        var UserVC = PlayerViewController()
        UserVC.Id = "\(sender.view!.tag)"
        self.navigationController!.pushViewController(UserVC, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        var index = indexPath.row
        var data = self.dataArray[index] as NSDictionary
        return  MeCell.cellHeightByData(data)
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var index = indexPath.row
        var data = self.dataArray[index] as NSDictionary
        var cid = data.stringAttributeForKey("cid")
        var uid = data.stringAttributeForKey("cuid")
        var user = data.stringAttributeForKey("cname")
        var lastdate = data.stringAttributeForKey("lastdate")
        var dreamtitle = data.stringAttributeForKey("dreamtitle")
        var content = data.stringAttributeForKey("content")
        var dream = data.stringAttributeForKey("dream")
        var type = data.stringAttributeForKey("type")
        var step = data.stringAttributeForKey("step")
        
        var DreamVC = DreamViewController()
        var UserVC = PlayerViewController()
        var BBSVC = BBSViewController()
        var StepVC = SingleStepViewController()
        if type == "0" {    //在你的梦想留言
            StepVC.Id = step
            self.navigationController!.pushViewController(StepVC, animated: true)
        }else if type == "1" {  //在某个梦想提及你
            StepVC.Id = step
            self.navigationController!.pushViewController(StepVC, animated: true)
        }else if type == "2" {  //赞了你的梦想
            DreamVC.Id = dream
            self.navigationController!.pushViewController(DreamVC, animated: true)
        }else if type == "3" {  //关注了你
            UserVC.Id = uid
            self.navigationController!.pushViewController(UserVC, animated: true)
        }else if type == "4" {  //参与了你的话题
            BBSVC.Id = dream
            BBSVC.flow = 1
            BBSVC.getContent = "1"
            self.navigationController!.pushViewController(BBSVC, animated: true)
        }else if type == "5" {  //在某个话题提及你
            BBSVC.Id = dream
            BBSVC.flow = 1
            BBSVC.getContent = "1"
            self.navigationController!.pushViewController(BBSVC, animated: true)
            //BBS要倒叙
        }else if type == "6" {  //为你更新了梦想
            DreamVC.Id = dream
            self.navigationController!.pushViewController(DreamVC, animated: true)
            //头像不对哦
        }else if type == "7" {  //添加你为小伙伴
            DreamVC.Id = dream
            self.navigationController!.pushViewController(DreamVC, animated: true)
        }else if type == "8" {  //赞了你的进展
            StepVC.Id = step
            self.navigationController!.pushViewController(StepVC, animated: true)
        }
    }
    
    
    func setupRefresh(){
        self.tableView!.addHeaderWithCallback({
            self.SAReloadData()
            })
        self.tableView!.addFooterWithCallback({
            self.loadData()
            })
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController!.interactivePopGestureRecognizer.enabled = false
    }
    
}
