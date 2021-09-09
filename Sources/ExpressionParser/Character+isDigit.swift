//
//  Character+isDigit.swift
//  ExpressionParser
//
//  Created by Josef Zoller on 09.09.21.
//

extension Character {
    public var isDigit: Bool {
        if !self.isASCII { return false }

        let scalar = self.unicodeScalars.first!
        return scalar.properties.generalCategory == .decimalNumber
    }
}
