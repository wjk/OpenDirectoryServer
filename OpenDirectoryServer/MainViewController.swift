//
//  MainViewController.swift
//  OpenDirectoryServer
//
//  Created by William Kent on 5/24/19.
//  Copyright © 2019 William Kent. All rights reserved.
//

import Cocoa
import SVRUserManagement

internal final class MainViewController: NSViewController, NSSplitViewDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
		updateUI()
	}

	override var representedObject: Any? {
		didSet {
			updateUI()
		}
	}

	private var model: SVRDirectoryNode? {
		get {
			guard let representedObject = representedObject else {
				return nil
			}

			guard let model = representedObject as? SVRDirectoryNode else {
				fatalError("model not of type SVRDirectoryNode")
			}

			return model
		}
	}

	private func updateUI() {
		// TODO: Implement this
	}

	// MARK: NSSplitViewDelegate

	func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
		return false
	}

	func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
		if dividerIndex == 0 {
			return view.bounds.width / 4
		} else {
			return proposedMinimumPosition
		}
	}

	func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
		if dividerIndex == 0 {
			return view.bounds.width / 3
		} else {
			return proposedMaximumPosition
		}
	}
}
