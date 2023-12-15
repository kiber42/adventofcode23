import Foundation

let defaultFilename = "input14.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

enum Rock: Character {
  case Round = "O"
  case Cube = "#"
}

class Dish: CustomStringConvertible {
  var rocks: [[Rock?]]

  init() {
    rocks = loadInput().split(separator: "\n").map { $0.map { Rock(rawValue: $0) } }
  }

  var description: String {
    return rocks.map { String($0.map { $0?.rawValue ?? "." }) }.joined(separator: "\n")
  }

  func score() -> Int {
    rocks.reversed().enumerated().map {
      let load = $0 + 1
      let row = $1
      return load * row.filter { $0 == .Round }.count
    }.reduce(0, +)
  }

  func rollNorth() {
    roll(0, -1)
  }

  func rollWest() {
    roll(-1, 0)
  }

  func rollSouth() {
    roll(0, +1)
  }

  func rollEast() {
    roll(+1, 0)
  }

  func doCycle() {
    rollNorth()
    rollWest()
    rollSouth()
    rollEast()
  }

  private func roll(_ dx: Int, _ dy: Int) {
    while true {
      var changed = false
      for y in max(0, -dy)..<rocks.count - max(0, dy) {
        for x in max(0, -dx)..<rocks[y].count - max(0, dx) {
          if rocks[y][x] == .Round && rocks[y + dy][x + dx] == nil {
            rocks[y][x] = nil
            rocks[y + dy][x + dx] = .Round
            changed = true
          }
        }
      }
      if !changed { break }
    }
  }
}

func partOne() -> Int {
  let dish = Dish()
  dish.rollNorth()
  return dish.score()
}

func partTwo() -> Int {
  let dish = Dish()
  var numCycles = 0
  let maxCycles = 1_000_000_000
  // Keep track of already seen constellations to detect cyclic behaviour.
  // Different constellations can have the same score, so just comparing scores is not good enough.
  // The cycle appears sufficiently early that we can simply store each seen full constellation.
  var seen = [Int: [[[Rock?]]]]()
  var seenAfter = [Int: [Int]]()
  while numCycles < maxCycles {
    dish.doCycle()
    numCycles += 1
    let score = dish.score()
    print(numCycles, score)
    if let seenIndex = seen[score]?.firstIndex(of: dish.rocks) {
      let missingCycles = maxCycles - numCycles
      let repeatStart = seenAfter[score]![seenIndex]
      let period = numCycles - repeatStart
      // Advance cycle count by a suitable number of periods
      numCycles += (missingCycles / period) * period
      print("Detected cycle starting at", repeatStart, "with length", period)      
      break
    } else {
      seen[score, default: []].append(dish.rocks)
      seenAfter[score, default: []].append(numCycles)
    }
  }
  // Perform the remaining iterations without caching
  while (numCycles < maxCycles) {    
    dish.doCycle()
    numCycles += 1
  }
  return dish.score()
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
