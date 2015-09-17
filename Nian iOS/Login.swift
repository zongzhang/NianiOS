//
//  YRAboutViewController.swift
//  JokeClient-Swift
//
//  Created by YANGReal on 14-6-5.
//  Copyright (c) 2014年 YANGReal. All rights reserved.
//

import UIKit


class LoginViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet var loginButton:UIImageView!
    @IBOutlet var loginButtonBorder:UIView!
    @IBOutlet var inputEmail:UITextField!
    @IBOutlet var inputPassword:UITextField!
    @IBOutlet var holder:UIView!
    @IBOutlet var forgetPwdLabel: UILabel!
    
    func setupViews(){
        self.viewBack()
        let navView = UIView(frame: CGRectMake(0, 0, globalWidth, 64))
        navView.backgroundColor = BarColor
        self.view.addSubview(navView)
        self.loginButton.layer.cornerRadius = 20
        self.loginButtonBorder.layer.cornerRadius = 25
        self.inputEmail.textColor = UIColor.blackColor()
        self.inputPassword.textColor = UIColor.blackColor()
        self.inputEmail.leftView = UIView(frame: CGRectMake(0, 0, 8, 40))
        self.inputEmail.rightView = UIView(frame: CGRectMake(0, 0, 20, 40))
        self.inputPassword.leftView = UIView(frame: CGRectMake(0, 0, 8, 40))
        self.inputPassword.rightView = UIView(frame: CGRectMake(0, 0, 20, 40))
        self.inputEmail.leftViewMode = UITextFieldViewMode.Always
        self.inputEmail.rightViewMode = UITextFieldViewMode.Always
        self.inputPassword.leftViewMode = UITextFieldViewMode.Always
        self.inputPassword.rightViewMode = UITextFieldViewMode.Always
        self.inputEmail.delegate = self
        self.inputPassword.delegate = self
        
        self.holder.setX(globalWidth/2-140)
        self.forgetPwdLabel.setX(globalWidth/2 - 100)
        
        let attributesDictionary = [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)]
        self.inputEmail.attributedPlaceholder = NSAttributedString(string: "邮箱", attributes: attributesDictionary)
        self.inputPassword.attributedPlaceholder = NSAttributedString(string: "密码", attributes: attributesDictionary)
        self.loginButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "loginAlert"))
        self.forgetPwdLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toForgetPwd:"))
        
        let titleLabel:UILabel = UILabel(frame: CGRectMake(0, 0, 200, 40))
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.text = "登录"
        titleLabel.textAlignment = NSTextAlignment.Center
        self.navigationItem.titleView = titleLabel
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard:"))
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.loginAlert()
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        self.inputEmail.becomeFirstResponder()
    }
    
    func loginAlert(){
        if self.inputEmail.text == "" || self.inputPassword.text == "" {
            shakeAnimation(self.holder)
        }else{
//            self.inputEmail.resignFirstResponder()
//            self.inputPassword.resignFirstResponder()
            
            self.navigationItem.rightBarButtonItems = buttonArray()
            let email = SAEncode(SAHtml(self.inputEmail.text!))
            let password = "n*A\(self.inputPassword.text!)"
            Api.postLogin(email, password: password.md5) { string in
                if string != nil {
                    if string! == "err" || string! == "NO" {
                        self.shakeAnimation(self.holder)
                        self.navigationItem.rightBarButtonItems = []
                    } else {
                        self.navigationItem.rightBarButtonItems = buttonArray()
                        let shell = (("\(password.md5)\(string!)n*A").lowercaseString).md5
                        let Sa:NSUserDefaults = NSUserDefaults.standardUserDefaults()
                        let username = SAPost("uid=\(string!)", urlString: "http://nian.so/api/username.php")
                        Sa.setObject(username, forKey:"user")
                        Sa.synchronize()
                        
                        let uidKey = KeychainItemWrapper(identifier: "uidKey", accessGroup: nil)
                        uidKey.setObject(string!, forKey: kSecAttrAccount)
                        uidKey.setObject(shell, forKey: kSecValueData)
                        
                        Api.requestLoad()
                        globalWillReEnter = 1
                        let mainViewController = HomeViewController(nibName:nil,  bundle: nil)
                        let navigationViewController = UINavigationController(rootViewController: mainViewController)
                        navigationViewController.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
                        navigationViewController.navigationBar.tintColor = UIColor.whiteColor()
                        navigationViewController.navigationBar.translucent = true
                        navigationViewController.navigationBar.barStyle = UIBarStyle.BlackTranslucent
                        navigationViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                        navigationViewController.navigationBar.clipsToBounds = true
                        
                        self.presentViewController(navigationViewController, animated: true, completion: {
                            self.navigationItem.rightBarButtonItems = []
                            self.inputEmail.text = ""
                            self.inputPassword.text = ""
                        })
                        Api.postDeviceToken() { string in
                        }
                        Api.postJpushBinding(){_ in }
                    }
                }
            }
        }
    }
    
    func toForgetPwd(sender: UITapGestureRecognizer) {
        self.navigationController?.pushViewController(ForgetPwd(nibName: "ForgetPwd", bundle: nil), animated: true)
    }

    func dismissKeyboard(sender:UITapGestureRecognizer){
        self.inputEmail.resignFirstResponder()
        self.inputPassword.resignFirstResponder()
    }

    func shakeAnimation(view:UIView){
        let viewLayer:CALayer = view.layer
        let position:CGPoint = viewLayer.position
        let x:CGPoint = CGPointMake(position.x + 3 , position.y)
        let y:CGPoint = CGPointMake(position.x - 3 , position.y)
        let animation:CABasicAnimation = CABasicAnimation(keyPath: "position")
        animation.fromValue = NSValue(CGPoint: x)
        animation.toValue = NSValue(CGPoint: y)
        animation.autoreverses = true
        animation.duration = 0.1
        animation.repeatCount = 2
        viewLayer.addAnimation(animation, forKey: nil)
    }
    
    func login(){
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
