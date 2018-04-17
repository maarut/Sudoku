//
//  AppDelegate.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import SudokuEngine
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var mainViewModel: MainViewModel!
    var gameSerialiser = GameSerialiser(withFileName: "net.maarut.Sudoku++.savedState")
    var window: UIWindow?
    var timer: Timer!
    
    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow.buildWindow()
        let rootVC = MainViewController(nibName: nil, bundle: nil)
        let viewModel = loadViewModel()
        rootVC.viewModel = viewModel
        self.mainViewModel = viewModel
        window!.rootViewController = rootVC
        window!.makeKeyAndVisible()
        timer = Timer.scheduledTimer(
            timeInterval: 30, target: self, selector: #selector(save), userInfo: nil, repeats: true)
        GADMobileAds.configure(withApplicationID: kAdMobAppId)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        mainViewModel.startTimer()
        timer = Timer.scheduledTimer(
            timeInterval: 30, target: self, selector: #selector(save), userInfo: nil, repeats: true)
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        save()
        mainViewModel.stopTimer()
        try! gameSerialiser.save(mainViewModel)
        timer.invalidate()
        timer = nil
    }

    func loadViewModel() -> MainViewModel
    {
        if let previousGame: MainViewModel = gameSerialiser.load() {
            return previousGame
        }
        return MainViewModel(withSudokuBoard: SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!)
    }
    
    @objc func save()
    {
        do {
            try gameSerialiser.save(mainViewModel)
        }
        catch let error as NSError {
            NSLog("\(error.localizedDescription)\n\(error.description)")
        }
    }
}

