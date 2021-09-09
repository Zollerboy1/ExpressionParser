//
//  Expression.swift
//  ExpressionParser
//
//  Created by Josef Zoller on 09.09.21.
//

public protocol Expression: CustomStringConvertible {
    var value: Double { get }
}

public struct BinaryOperatorExpression: Expression {
    public let left, right: Expression
    public let op: Operator

    public var value: Double { self.op.apply(to: self.left.value, and: self.right.value) }

    public var description: String { "\(self.left) \(self.op.rawValue) \(self.right)" }
}

public struct PrefixOperatorExpression: Expression {
    public let expression: Expression
    public let op: Operator

    public var value: Double { self.op.apply(to: self.expression.value) }

    public var description: String { "\(self.op.rawValue)\(self.expression)" }
}

public struct NumberExpression: Expression {
    public let value: Double

    public var description: String { "\(self.value)" }
}

public struct GroupingExpression: Expression {
    public let nestedExpression: Expression

    public var value: Double { self.nestedExpression.value }

    public var description: String { "(\(self.nestedExpression))" }
}
