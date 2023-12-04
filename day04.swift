import Foundation

let defaultFilename = "input04.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

let cards = loadInput().split(separator: "\n")

var numMatches = [Int]()
for card in cards {
  let numbers = card.split(separator: "|").map {
    Set($0.split(separator: " ").compactMap { Int($0) })
  }
  numMatches.append(numbers[0].intersection(numbers[1]).count)
}
let scores = numMatches.map { 1 << ($0 - 1) }

var numCards = Array(repeating: 1, count: cards.count)
for (i, overlap) in numMatches.enumerated() {
  for j in i + 1..<i + 1 + overlap {
    if j < numCards.count {
      numCards[j] += numCards[i]
    }
  }
}

print("Part 1:", scores.reduce(0, +))
print("Part 2:", numCards.reduce(0, +))
