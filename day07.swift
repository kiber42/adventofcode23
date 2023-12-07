import Foundation

let defaultFilename = "input07.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func cardRank(_ card: Character) -> Int {
  switch card {
  case "A": return 14
  case "K": return 13
  case "Q": return 12
  case "J": return 11
  case "T": return 10
  case "*": return 1
  default: return Int(String(card))!
  }
}

enum Type: Int {
  case FiveOfAKind = 7
  case FourOfAKind = 6
  case FullHouse = 5
  case ThreeOfAKind = 4
  case TwoPairs = 3
  case OnePair = 2
  case HighCard = 1
}

func getType(hand: String.SubSequence) -> Type {
  var counts = [Character: Int]()
  for card in hand {
    counts[card, default: 0] += 1
  }
  let numCardTypes = counts.count
  let numJokers = counts["*"] ?? 0
  let highestCount = counts.values.max()!
  switch numCardTypes {
  case 1: return .FiveOfAKind
  case 2: return numJokers > 0 ? .FiveOfAKind : highestCount == 4 ? .FourOfAKind : .FullHouse
  case 3:
    if numJokers >= 2 {  // **XXY or ***XY
      return .FourOfAKind
    } else if numJokers == 1 {  // *XXXY or *XXYY
      return highestCount == 3 ? .FourOfAKind : .FullHouse
    } else {  // XXXYZ or XXYYZ
      return highestCount == 3 ? .ThreeOfAKind : .TwoPairs
    }
  case 4: return numJokers > 0 ? .ThreeOfAKind : .OnePair  // **XYZ, *XXYZ, AABCD
  case 5: return numJokers > 0 ? .OnePair : .HighCard
  default: assert(false)
  }
}

struct Round {
  let type: Type
  let typeAndCardRanks: (Int, Int, Int, Int, Int, Int)
  let bid: Int

  init(from: String.SubSequence, withJokers: Bool = false) {
    let parts = from.split(separator: " ")
    let hand = withJokers ? parts[0].replacing("J", with: "*") : parts[0]
    type = getType(hand: hand)
    let r = hand.map { cardRank($0) }
    assert(r.count == 5)
    typeAndCardRanks = (type.rawValue, r[0], r[1], r[2], r[3], r[4])
    bid = Int(parts[1])!
  }
}

func rankAndScore(rounds: [Round]) -> Int {
  let ranked = rounds.sorted { $0.typeAndCardRanks < $1.typeAndCardRanks }
  return ranked.enumerated().map { rank, round in (rank + 1) * round.bid }.reduce(0, +)
}

let lines = loadInput().split(separator: "\n")
let rounds = lines.map { Round(from: $0) }
let roundsWithJokers = lines.map { Round(from: $0, withJokers: true) }

print("Part 1:", rankAndScore(rounds: rounds))
print("Part 2:", rankAndScore(rounds: roundsWithJokers))
