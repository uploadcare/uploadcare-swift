//
//  ViewController.swift
//  DemoApp
//
//  Created by Sergey Armodin on 12.01.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import UIKit
import Uploadcare

class ViewController: UIViewController {
	
	private lazy var uploadcare: Uploadcare = {
		// Define your Public Key here
		let publicKey = ""
		return Uploadcare(withPublicKey: publicKey)
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
	}


}

