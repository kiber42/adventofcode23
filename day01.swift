import Foundation

let defaultFilename = "input01.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func testDigit(_ s: String.SubSequence) -> Int? {
  if let digit = Int(String(s.first ?? "x")) {
    return digit
  }
  if s.starts(with: "one") {
    return 1
  }
  if s.starts(with: "two") {
    return 2
  }
  if s.starts(with: "three") {
    return 3
  }
  if s.starts(with: "four") {
    return 4
  }
  if s.starts(with: "five") {
    return 5
  }
  if s.starts(with: "six") {
    return 6
  }
  if s.starts(with: "seven") {
    return 7
  }
  if s.starts(with: "eight") {
    return 8
  }
  if s.starts(with: "nine") {
    return 9
  }
  return nil
}

let lines = loadInput().split(separator: "\n")

let calibrationValues1 = lines.map { line in
  let nums = line.compactMap { Int(String($0)) }
  return nums.isEmpty ? 0 : nums.first! * 10 + nums.last!
}
let calibrationValues2 = lines.map { line in
  let digits = (0..<line.count).compactMap { pos in testDigit(line.dropFirst(pos)) }
  return digits.first! * 10 + digits.last!
}

print("Part 1:", calibrationValues1.reduce(0, +))
print("Part 2:", calibrationValues2.reduce(0, +))
