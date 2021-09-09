//
//  Operator.swift
//  ExpressionParser
//
//  Created by Josef Zoller on 09.09.21.
//

public enum Operator: Character {
    case addition = "+"
    case subtraction = "-"
    case multiplication = "*"
    case division = "/"

    func apply(to a: Double, and b: Double) -> Double {
        switch self {
        case .addition:
            return a + b
        case .subtraction:
            return a - b
        case .multiplication:
            return a * b
        case .division:
            return a / b
        }
    }

    func apply(to a: Double) -> Double {
        switch self {
        case .addition:
            return a
        case .subtraction:
            return -a
        default:
            fatalError()
        }
    }
}
