//
//  ParsedExpression.swift
//  ExpressionParser
//
//  Created by Josef Zoller on 09.09.21.
//

import Foundation

public struct ParsedExpression: Expression {
    private class Lexer {
        enum Error {
            case invalidCharacter
            case noDigitAfterDecimalPoint
            case noDigitAfterE
        }

        enum TokenType: Equatable, CustomStringConvertible {
            case leftParen, rightParen
            case op(Operator)
            case number(Double)
            case error(Error)
            case endOfString

            var description: String {
                switch self {
                case .leftParen:
                    return "a left parenthesis"
                case .rightParen:
                    return "a right parenthesis"
                case let .op(op):
                    return "an operator '\(op.rawValue)'"
                case let .number(value):
                    return "a number (\(value))"
                case .error:
                    return "an error"
                case .endOfString:
                    return "the end of the string"
                }
            }
        }

        typealias Token = (type: TokenType, position: Int)

        let string: String
        var start: String.Index
        var position: String.Index

        init(withInput string: String) {
            self.string = string
            self.start = string.startIndex
            self.position = string.startIndex
        }

        func nextToken() -> Token {
            while !self.isAtEnd {
                self.start = self.position

                let character = self.advance()

                switch character {
                case " ", "\t":
                    continue
                case "(":
                    return self.getToken(withType: .leftParen)
                case ")":
                    return self.getToken(withType: .rightParen)
                case "+", "-", "*", "/":
                    return self.getToken(withType: .op(.init(rawValue: character)!))
                default:
                    if character.isDigit {
                        return self.matchNumber()
                    }

                    return self.getError(.invalidCharacter)
                }
            }

            return self.getToken(withType: .endOfString)
        }


        private var isAtEnd: Bool { self.position == self.string.endIndex }

        private var peek: Character { self.string[self.position] }

        @discardableResult
        private func advance() -> Character {
            let character = self.peek
            self.string.formIndex(after: &self.position)
            return character
        }

        private func match(expected: Character) -> Bool {
            if self.isAtEnd || self.peek != expected { return false }

            self.advance()
            return true
        }

        private func getToken(withType type: TokenType, atPosition position: String.Index? = nil) -> Token {
            (type, self.string.distance(from: self.string.startIndex, to: position ?? self.start))
        }

        private func getError(_ error: Error, atPosition position: String.Index? = nil) -> Token {
            (.error(error), self.string.distance(from: self.string.startIndex, to: position ?? self.start))
        }

        private func matchNumber() -> Token {
            enum State {
                case begin
                case integer
                case beginDecimal
                case decimal
                case beginExponent
                case beginSignedExponent
                case decimalWithExponent
            }

            var current = self.start
            var currentState = State.begin

            var character: Character { self.string[current] }

            loop: while current < self.string.endIndex {
                switch currentState {
                case .begin:
                    assert(character.isDigit)
                    currentState = .integer
                case .integer:
                    if character.isDigit { break }

                    if character == "." {
                        currentState = .beginDecimal
                        break
                    }

                    if character.lowercased() == "e" {
                        currentState = .beginExponent
                        break
                    }

                    break loop
                case .beginDecimal:
                    if character.isDigit {
                        currentState = .decimal
                        break
                    }

                    break loop
                case .decimal:
                    if character.isDigit { break }

                    if character == "e" {
                        currentState = .beginExponent
                        break
                    }

                    break loop
                case .beginExponent:
                    if character == "+" || character == "-" {
                        currentState = .beginSignedExponent
                        break
                    }

                    fallthrough
                case .beginSignedExponent:
                    if character.isDigit {
                        currentState = .decimalWithExponent
                        break
                    }

                    break loop
                case .decimalWithExponent:
                    if character.isDigit { break }

                    break loop
                }

                self.string.formIndex(after: &current)
            }

            if currentState == .beginDecimal {
                return self.getError(.noDigitAfterDecimalPoint, atPosition: current)
            } else if currentState == .beginExponent || currentState == .beginSignedExponent {
                return self.getError(.noDigitAfterE, atPosition: current)
            }

            self.position = current

            return self.getToken(withType: .number(Double(self.string[self.start..<self.position])!))
        }
    }


    private class Parser {
        private enum Error: LocalizedError {
            case lexerError(Lexer.Error, Int)
            case expectedExpression(Lexer.Token)
            case expectedRightParen(Lexer.Token)
            case expectedExpressionEnd(Lexer.Token)
            case unexpected

            var errorDescription: String? {
                switch self {
                case let .lexerError(error, position):
                    switch error {
                    case .invalidCharacter:
                        return "Use of invalid character at index \(position)."
                    case .noDigitAfterDecimalPoint:
                        return "Expected a digit after the decimal point at index \(position)."
                    case .noDigitAfterE:
                        return "Expected a digit in the floating point exponent at index \(position)."
                    }
                case let .expectedExpression((type, position)):
                    return "Expected an expression at index \(position), but got \(type) instead."
                case let .expectedRightParen((type, position)):
                    return "Expected a right parenthesis at index \(position), but got \(type) instead."
                case let .expectedExpressionEnd((type, position)):
                    return "Expected the end of the expression at index \(position), but got \(type) instead."
                case .unexpected:
                    return "Encountered unexpected error while parsing expression."
                }
            }
        }

        let lexer: Lexer
        var currentToken: Lexer.Token

        init(withLexer lexer: Lexer) {
            self.lexer = lexer
            self.currentToken = lexer.nextToken()
        }

        func parseExpression() throws -> Expression {
            let expression = try self.parseAdditionPrecedenceExpression()

            guard self.isAtEnd else { throw Error.expectedExpressionEnd(self.currentToken) }

            return expression
        }


        private func parseAdditionPrecedenceExpression() throws -> Expression {
            var expression = try self.parseMultiplicationPrecedenceExpression()

            while let matched = try self.match({
                if case let .op(op) = $0 {
                    return op == .addition || op == .subtraction
                }

                return false
            }), case let .op(op) = matched.type {
                let right = try self.parseMultiplicationPrecedenceExpression()

                expression = BinaryOperatorExpression(left: expression, right: right, op: op)
            }

            return expression
        }

        private func parseMultiplicationPrecedenceExpression() throws -> Expression {
            var expression = try self.parsePrefixExpression()

            while let matched = try self.match({
                if case let .op(op) = $0 {
                    return op == .multiplication || op == .division
                }

                return false
            }), case let .op(op) = matched.type {
                let right = try self.parsePrefixExpression()

                expression = BinaryOperatorExpression(left: expression, right: right, op: op)
            }

            return expression
        }

        private func parsePrefixExpression() throws -> Expression {
            if let matched = try self.match({
                if case let .op(op) = $0 {
                    return op == .addition || op == .subtraction
                }

                return false
            }), case let .op(op) = matched.type {
                let expression = try self.parsePrefixExpression()

                return PrefixOperatorExpression(expression: expression, op: op)
            }

            return try self.parsePrimaryExpression()
        }

        private func parsePrimaryExpression() throws -> Expression {
            if let matched = try self.match({
                if case .number = $0 {
                    return true
                }

                return false
            }), case let .number(value) = matched.type {
                return NumberExpression(value: value)
            }

            return try self.parseGroupedExpression()
        }

        private func parseGroupedExpression() throws -> Expression {
            guard try self.match(.leftParen) != nil else {
                throw Error.expectedExpression(self.currentToken)
            }

            let expression = try self.parseAdditionPrecedenceExpression()

            guard try self.match(.rightParen) != nil else {
                throw Error.expectedRightParen(self.currentToken)
            }

            return GroupingExpression(nestedExpression: expression)
        }


        private func match(_ token: Lexer.TokenType) throws -> Lexer.Token? {
            try self.match { $0 == token }
        }

        private func match(_ checkToken: (Lexer.TokenType) -> Bool) throws -> Lexer.Token? {
            if self.check(checkToken) {
                return try self.advance()
            }

            return nil
        }

        @discardableResult
        private func advance() throws -> Lexer.Token {
            if self.isAtEnd { throw Error.unexpected }

            let token = self.currentToken

            self.currentToken = self.lexer.nextToken()

            if !self.isAtEnd, case let .error(error) = self.currentToken.type {
                throw Error.lexerError(error, self.currentToken.position)
            }

            return token
        }

        private func check(_ checkToken: (Lexer.TokenType) -> Bool) -> Bool {
            if self.isAtEnd { return false }

            return checkToken(self.currentToken.type)
        }

        private var isAtEnd: Bool { self.currentToken.type == .endOfString }
    }


    public let expression: Expression

    public var value: Double { self.expression.value }


    internal init(expression: Expression) {
        self.expression = expression
    }


    public init(from string: String) throws {
        let lexer = Lexer(withInput: string)

        let parser = Parser(withLexer: lexer)

        self.expression = try parser.parseExpression()
    }


    public var description: String { "\(self.expression)" }
}

extension ParsedExpression: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            try self.init(from: string)
        } else {
            let value = try container.decode(Double.self)
            self.init(expression: NumberExpression(value: value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let numberExpression = self.expression as? NumberExpression {
            try container.encode(numberExpression.value)
        } else {
            try container.encode(self.description)
        }
    }
}
