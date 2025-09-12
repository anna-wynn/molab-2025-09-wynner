import Cocoa // keep this?
import Foundation // Apple foundation framework

let artPalette: [Character] = ["❤️", "🧡", "💛", "💚", "🩵", "💙", "💜"]
let width = 10 // column/line
let height = 5 // number of lines

// now I want to pick a raondom character from myPalette
func randomChar() -> Character {
    return artPalette.randomElement()!
}

// building a line of random heart emojis from above
func makeLine(length: Int) -> String {
    var line = ""
    for _ in 0..<length {    // this is my for loop, and this counts from 0 to the legnth - 1
        line.append(randomChar())  // adds a random character
    }
    return line
}

// now i am going to print some random colored hearts loll
func makeBlock(rows: Int, cols: Int) {
    for _ in 0..<rows {  //this is the outer for-oop for each row
        print(makeLine(length: cols))
    }
}

// drawing 3 blocks wchich is separated by blank lines to make it aesthetically appealing???
makeBlock(rows: height, cols: width)
print("")  // these are them blank linesss
makeBlock(rows: height, cols: width)
print("") // another blank line
makeBlock(rows: height, cols: width)








// Error Log
// in line 4, I initially typed out [Character] with a lower case and it showed me an error saying "cannot find type.." and this shows that swift is very case sensitive, coding in general is too.
// in line 24, i made a the grave mistake of making a typo in which xcode reminded me that the direction of the arrows mattered as well, instead of typing this operator: ..<, i typed ..> which xcode said cannot find this operator in scope.

// Sources that I've used include: Xcode console and Apple docs (Strings & Characters)
// fundamentals from 100 days of SwiftUI
