import Foundation

let defaultFilename = "input06.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func numberOfOptions(time: Int, distance: Int) -> Int {
  // Distance travelled for given total time T and button press time t:
  // (T - t) * t
  // This must be larger than the current record distance.
  // Solve the quadratic equation for t to find the two times where we would match
  // the current record distance, then count (integer) number of options in between.
  let p = Double(time) / 2
  let root = sqrt(p * p - Double(distance))
  let t1 = ceil(p - root + 1e-6)
  let t2 = floor(p + root - 1e-6)
  return Int(t2 - t1 + 1)
}

func partOne(_ records : [String.SubSequence]) -> Int {
  let numbers = records.map{ $0.split(separator: " ").compactMap{ Int($0) } }
  let options = zip(numbers[0], numbers[1]).map{ numberOfOptions(time: $0.0, distance: $0.1) }
  return options.reduce(1, *)
}

func partTwo(_ records : [String.SubSequence]) -> Int {
  let numbers = records.map{ $0.replacing(" ", with: "").split(separator: ":").compactMap{ Int($0) }.first! }
  return numberOfOptions(time: numbers[0], distance: numbers[1])
}

let records = loadInput().split(separator: "\n")
print("Part 1:", partOne(records))
print("Part 2:", partTwo(records))
