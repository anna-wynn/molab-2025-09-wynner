import Cocoa

import Foundation //foundation library

let path = Bundle.main.path(forResource: "text.txt", ofType: nil)
let str = try String(contentsOfFile: path!, encoding: .utf8)
print(str)

func load(_ file : String) -> String {
    let path = Bundle.main.path(forResource: file, ofType: nil)
    let str = try? String(contentsOfFile: path!, encoding: .utf8)
    return str!
}

print(load("coffeemug.txt"))
print(load("icecream.txt"))
print(load("teabag.txt"))
print(load("teapot.txt"))
