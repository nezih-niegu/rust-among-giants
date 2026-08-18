import Foundation
import CoreFoundation
let fn = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "../../data/json_input.json"
let data = try! Data(contentsOf: URL(fileURLWithPath: fn))
let json = try! JSONSerialization.jsonObject(with: data)

let kCFBooleanTypeID = CFBooleanGetTypeID()

func count(_ v: Any) -> (Int64,Int64,Int64,Int64,Int64,Int64) {
    var o:Int64=0,a:Int64=0,s:Int64=0,n:Int64=0,b:Int64=0,nl:Int64=0
    if let dict = v as? [String: Any] {
        o = 1
        for val in dict.values {
            let r = count(val); o+=r.0;a+=r.1;s+=r.2;n+=r.3;b+=r.4;nl+=r.5
        }
    } else if let arr = v as? [Any] {
        a = 1
        for val in arr {
            let r = count(val); o+=r.0;a+=r.1;s+=r.2;n+=r.3;b+=r.4;nl+=r.5
        }
    } else if v is String { s = 1 }
    else if v is NSNull { nl = 1 }
    else if CFGetTypeID(v as CFTypeRef) == kCFBooleanTypeID { b = 1 }
    else if v is NSNumber { n = 1 }
    return (o,a,s,n,b,nl)
}
let r = count(json)
print("objects=\(r.0) arrays=\(r.1) strings=\(r.2) numbers=\(r.3) bools=\(r.4) nulls=\(r.5)")
