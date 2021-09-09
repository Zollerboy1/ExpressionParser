# ExpressionParser

A little package that provides a simple arithmetic expression hierarchy.

It can store arbitrarily nested expressions using numbers of `Double` precision,
the binary operators `+`, `-`, `*`, and `/`, the unary operators `+` and `-`,
and parentheses for grouping.

The expression structure can be parsed directly from a `String` or it can be de- and encoded via `Codable`.


## Installation

Add this line to the dependencies of your Swift Package:

```swift
.package(url: "https://github.com/Zollerboy1/ExpressionParser.git", from: "1.0.0")
```

and add the module `ExpressionParser` to your target's dependencies.


## Usage

You can just create an expression hierarchy from a string:

```swift
import ExpressionParser

let expressionString = "5+6*(2+3)"

let expression = try ParsedExpression(from: expressionString)

print(expression) // prints "5.0 + 6.0 * (2.0 + 3.0)"

print(expression.value) // prints "35.0"
```

You can also decode an expression using `Codable`, e.g. from JSON:

```swift
import ExpressionParser
import Foundation

let jsonString = """
[
    5,
    "2.5e-1 + 4",
    "1 / 3"
]
"""

let jsonData = jsonString.data(using: .utf8)!

let decoder = JSONDecoder()

let array = try! decoder.decode([ParsedExpression].self, from: jsonData)

print(array) // prints "[5.0, 0.25 + 4.0, 1.0 / 3.0]"

print(array.map(\.value)) // prints "[5.0, 4.25, 0.3333333333333333]"
```

As you can see, `ParsedExpression` will try to decode numbers as well as strings
from JSON (or every other format you have a `Decoder` for).
