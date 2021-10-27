//
//  APIStore.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

/// Observable wrapper for Uploadcare
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class APIStore: ObservableObject {
	public var uploadcare: Uploadcare?

	public init(uploadcare: Uploadcare? = nil) {
		self.uploadcare = uploadcare
	}
}
#endif
