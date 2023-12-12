import Foundation

let defaultFilename = "input12.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

class Record {
  let n: Int
  let isBroken: [Bool]
  let isUnknown: [Bool]
  let groupSizes: [Int]

  init(from: String.SubSequence, multiplier: Int = 1) {
    let parts = from.split(separator: " ")
    let springs = String(repeating: parts[0] + "?", count: multiplier).dropLast()

    n = springs.count
    isBroken = springs.map { $0 == "#" }
    isUnknown = springs.map { $0 == "?" }
    groupSizes = [[Int]](
      repeating: parts[1].split(separator: ",").map { Int($0)! }, count: multiplier
    ).flatMap { $0 }
  }

  func countCombinations() -> Int {
    return process(springIndex: 0, groupIndex: 0)
  }

  // Cache known outcomes, parametrized by the current positions in the input data
  private struct State: Hashable {
    let springIndex: Int
    let groupIndex: Int
  }
  private var cache = [State: Int]()

  // Evaluate possible assignments for remaining unknown springs, using recursion and memoization.
  // Return number of valid assignments.
  private func process(springIndex: Int, groupIndex: Int) -> Int {
    let state = State(springIndex: springIndex, groupIndex: groupIndex)
    if let result = cache[state] {
      return result
    }

    if groupIndex == groupSizes.count {
      // Found all required broken springs.
      // A valid solution also requires that the remaining ones are not broken.
      let isValid = springIndex >= n || (springIndex..<n).allSatisfy { !isBroken[$0] }
      return isValid ? 1 : 0
    }
    if springIndex + groupSizes[groupIndex] > n {
      return 0
    }
    let groupStart = (springIndex..<n).first { isUnknown[$0] || isBroken[$0] } ?? n
    let groupEnd = groupStart + groupSizes[groupIndex]
    if groupEnd > n {
      return 0
    }

    // Consider next spring to be broken
    var resultForBroken = 0
    if isBroken[groupStart] || isUnknown[groupStart] {
      let isValidGroup =
        (groupStart..<groupEnd).allSatisfy { isBroken[$0] || isUnknown[$0] }
        && (groupEnd == n || !isBroken[groupEnd])
      if isValidGroup {
        resultForBroken = process(springIndex: groupEnd + 1, groupIndex: groupIndex + 1)
      }
    }

    // Consider next spring to be not broken
    var resultForNotBroken = 0
    if !isBroken[groupStart] || isUnknown[groupStart] {
      resultForNotBroken = process(springIndex: groupStart + 1, groupIndex: groupIndex)
    }

    let result = resultForBroken + resultForNotBroken
    cache[state] = result
    return result
  }
}

func countCombinations(multiplier: Int = 1) -> Int {
  let records = loadInput().split(separator: "\n").map { Record(from: $0, multiplier: multiplier) }
  return records.map { $0.countCombinations() }.reduce(0, +)
}

print("Part 1:", countCombinations())
print("Part 2:", countCombinations(multiplier: 5))
