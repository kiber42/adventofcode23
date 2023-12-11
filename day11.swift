import Foundation

let defaultFilename = "input11.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Pos: Hashable, CustomStringConvertible {
  let x, y: Int

  init(_ x: Int, _ y: Int) {
    self.x = x
    self.y = y
  }

  var description: String {
    "(\(x),\(y))"
  }
}

func manhattanDistance(_ a: Pos, _ b: Pos) -> Int {
  return abs(a.x - b.x) + abs(a.y - b.y)
}

struct GalaxyChart {
  let galaxies: [Pos]
  private let expansionsX: [Int: Int]
  private let expansionsY: [Int: Int]

  init() {
    let chart = loadInput().split(separator: "\n")
    galaxies = chart.enumerated().flatMap { y, row in
      row.enumerated().compactMap { $0.1 == "#" ? Pos($0.0, y) : nil }
    }

    expansionsX = GalaxyChart.computeExpansion(nonEmptyPositions: galaxies.map { $0.x })
    expansionsY = GalaxyChart.computeExpansion(nonEmptyPositions: galaxies.map { $0.y })
  }

  func galaxyPositions(expansionFactor: Int) -> [Pos] {
    let scale = expansionFactor - 1
    return galaxies.map { p in
      Pos(p.x + scale * expansionsX[p.x]!, p.y + scale * expansionsY[p.y]!)
    }
  }

  func galaxyDistances(expansionFactor: Int) -> [Int] {
    let positions = galaxyPositions(expansionFactor: expansionFactor)
    return positions.enumerated().flatMap { i, galaxy1 in
      positions.dropFirst(i + 1).map { galaxy2 in
        manhattanDistance(galaxy1, galaxy2)
      }
    }
  }

  // For each non-empty column/row, compute number of empty columns/rows coming before it
  private static func computeExpansion(nonEmptyPositions: [Int]) -> [Int: Int] {
    let positions = Set(nonEmptyPositions).sorted()
    return zip(positions, positions.dropFirst()).reduce(into: [Int: Int]()) {
      let (pos, next) = $1
      let spaceInBetween = next - pos - 1
      $0[pos] = $0[pos, default: 0]
      $0[next] = $0[pos]! + spaceInBetween
    }
  }
}

let chart = GalaxyChart()
let totalDistance = { chart.galaxyDistances(expansionFactor: $0).reduce(0, +) }

print("Part 1:", totalDistance(2))
print("Part 2:", totalDistance(1_000_000))
print("Example  x10 -> \(totalDistance(10))")
print("Example x100 -> \(totalDistance(100))")
