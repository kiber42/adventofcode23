import Foundation

let defaultFilename = "input03.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Pos: Hashable {
  let x, y: Int

  init(_ x: Int, _ y: Int) {
    self.x = x
    self.y = y
  }
}

// Our "Rectangle" describes the position of a number and is always 1 row high
struct Rectangle {
  let x, y, w: Int

  init(_ left: Int, _ top: Int, _ width: Int) {
    x = left
    y = top
    w = width
  }

  func neighbours() -> [Pos] {
    return [Pos(x - 1, y), Pos(x + w, y)]
      + (x - 1...x + w).flatMap { x in [Pos(x, y - 1), Pos(x, y + 1)] }
  }
}

typealias Schematic = [[Character]]
typealias NumberInRectangle = (Int, Rectangle)

func loadSchematic() -> Schematic {
  let lines = loadInput().split(separator: "\n")
  let numCols = lines.first!.count
  // Add a border of "." to avoid border checking
  let emptyRow = Array(repeating: Character("."), count: numCols + 2)
  return [emptyRow] + lines.map { Array(".\($0).") } + [emptyRow]
}

// Scan input line by line to find numbers and their extends
func locateNumbers(schematic: Schematic) -> [NumberInRectangle] {
  var numbers = [NumberInRectangle]()
  for (y, row) in schematic.enumerated() {
    var current = ""
    for (x, char) in row.enumerated() {
      if Int(String(char)) != nil {
        current.append(char)
      } else if !current.isEmpty {
        let len = current.count
        numbers.append((Int(current)!, Rectangle(x - len, y, len)))
        current = ""
      }
    }
  }
  return numbers
}

// Scan symbols around numbers, sum up part numbers and group all numbers for each gear
func analyzeSymbols(schematic: Schematic, numbers: [NumberInRectangle]) -> (Int, [[Int]]) {
  var gears = [Pos: [Int]]()
  var sumOfPartNumbers = 0
  for (number, rect) in numbers {
    var isPartNumber = false
    for pos in rect.neighbours() {
      let char = schematic[pos.y][pos.x]
      if char == "." || Int(String(char)) != nil {
        continue
      }
      isPartNumber = true
      if char == "*" {
        gears[pos, default: []].append(number)
      }
    }
    if isPartNumber {
      sumOfPartNumbers += number
    }
  }
  return (sumOfPartNumbers, [[Int]](gears.values))
}

let schematic = loadSchematic()
let numbers = locateNumbers(schematic: schematic)
let (sumOfPartNumbers, numbersPerGear) = analyzeSymbols(schematic: schematic, numbers: numbers)
let sumOfGearRatios = numbersPerGear.map { $0.count == 2 ? $0[0] * $0[1] : 0 }.reduce(0, +)
print("Part 1:", sumOfPartNumbers)
print("Part 2:", sumOfGearRatios)
