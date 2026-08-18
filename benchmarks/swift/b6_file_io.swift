import Foundation
let CHUNK = 1024 * 1024, CHUNKS = 4096
let fname = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "../../data/fileio_test_swift.tmp"
let buf = Data(repeating: 65, count: CHUNK) // 'A'
// Write
FileManager.default.createFile(atPath: fname, contents: nil)
let wh = FileHandle(forWritingAtPath: fname)!
for _ in 0..<CHUNKS { wh.write(buf) }
wh.synchronizeFile()
wh.closeFile()
// Read
let rh = FileHandle(forReadingAtPath: fname)!
var total = 0
while true { let d = rh.readData(ofLength: CHUNK); if d.isEmpty { break }; total += d.count }
rh.closeFile()
print(total)
try! FileManager.default.removeItem(atPath: fname)
