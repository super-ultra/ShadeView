//
//  Protocol+Utils.swift
//  Pods-ShadeView_Example
//
//  Created by Ilya Lobanov on 29/11/2018.
//

import Foundation

internal extension Protocol {

    func getInstanceMethods() -> Set<Selector> {
        return getInstanceMethods(isRequired: true).union(getInstanceMethods(isRequired: false))
    }
    
    func getInstanceMethods(isRequired: Bool) -> Set<Selector> {
        var count: UInt32 = 0

        let descriptions = protocol_copyMethodDescriptionList(self, isRequired, true, &count)

        defer {
            free(descriptions)
        }

        var result = Set<Selector>()

        for i in 0..<count {
            if let s = descriptions?[Int(i)].name {
                result.insert(s)
            }
        }
        
        return result
    }
    
}
