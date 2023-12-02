import Foundation

let defaultFilename = "input02.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func getID(_ game: String.SubSequence) -> Int {
  return Int(game.split(separator: ":").first!.split(separator: " ").last!)!
}

typealias RGB = (Int, Int, Int)

func getRequiredCounts(_ game: String.SubSequence) -> RGB {
  var r = 0
  var g = 0
  var b = 0
  let tokens = game.replacing(",", with: "").replacing(";", with: "").split(separator: " ")
  var lastNumber: Int? = nil
  for token in tokens {
    if let lastNumber {
      if token == "red" {
        r = max(r, lastNumber)
      } else if token == "green" {
        g = max(g, lastNumber)
      } else if token == "blue" {
        b = max(b, lastNumber)
      }
    }
    lastNumber = Int(token)
  }
  return (r, g, b)
}

func isValidGame(_ counts: RGB) -> Bool {
  return counts.0 <= 12 && counts.1 <= 13 && counts.2 <= 14
}

func power(_ counts: RGB) -> Int {
  return counts.0 * counts.1 * counts.2
}

let lines = loadInput().split(separator: "\n")
let games = lines.map { (getID($0), getRequiredCounts($0)) }
print("Part 1:", games.compactMap { (id, counts) in isValidGame(counts) ? id : nil }.reduce(0, +))
print("Part 2:", games.map { (_, counts) in power(counts) }.reduce(0, +))
