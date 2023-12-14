import Foundation

let defaultFilename = "input13.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func transposed(_ matrix: [[Int]]) -> [[Int]] {
  var out = Array(repeating: Array(repeating: 0, count: matrix.count), count: matrix[0].count)
  for y in 0..<matrix.count {
    for x in 0..<matrix[0].count {
      out[x][y] = matrix[y][x]
    }
  }
  return out
}

func findHorizontalMirrorPosition(_ valley: [[Int]], _ requiredDifferences: Int) -> Int? {
  // Don't try to be smart, just guess at the mirror position and check for symmetry around it.
  // Since both parts of the puzzle have exactly one solution per valley, we simply require that
  // there are either 0 differences (part 1) or 1 difference (part 2) from perfect symmetry to
  // accept the candidate mirror position.
  for mirrorY in 1..<valley.count {
    var numDifferences = 0
    let start = max(0, 2 * mirrorY - valley.count)
    for y in start..<mirrorY {
      let yMirrored = 2 * mirrorY - y - 1
      numDifferences += zip(valley[y], valley[yMirrored]).filter { $0 != $1 }.count
      if numDifferences > requiredDifferences {
        break
      }
    }
    if numDifferences == requiredDifferences {
      return mirrorY
    }
  }
  return nil
}

func findMirrorScore(valley: [[Int]], requiredDifferences: Int = 0) -> Int {
  if let scoreH = findHorizontalMirrorPosition(valley, requiredDifferences) {
    return 100 * scoreH
  }
  // Instead of looking for a vertical mirror, transpose the input and search for a horizontal one
  return 1 * findHorizontalMirrorPosition(transposed(valley), requiredDifferences)!
}

let valleys = loadInput().split(separator: "\n\n").map { block in
  block.split(separator: "\n").map { row in
    row.map { $0 == "#" ? 1 : 0 }
  }
}
let mirrors = valleys.map { findMirrorScore(valley: $0) }
let mirrorsWithSpeck = valleys.map { findMirrorScore(valley: $0, requiredDifferences: 1) }

print("Part 1:", mirrors.reduce(0, +))
print("Part 2:", mirrorsWithSpeck.reduce(0, +))
