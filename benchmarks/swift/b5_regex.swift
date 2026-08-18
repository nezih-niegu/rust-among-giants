import Foundation
let fn = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "../../data/regex_input.txt"
let pattern = try! NSRegularExpression(pattern: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
let content = try! String(contentsOfFile: fn, encoding: .utf8)
var count = 0
content.enumerateLines { line, _ in
    let range = NSRange(line.startIndex..., in: line)
    if pattern.firstMatch(in: line, range: range) != nil { count += 1 }
}
print(count)
