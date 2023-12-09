import Foundation

let defaultFilename = "input09.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func adjacent_difference(_ data: [Int]) -> [Int] {
  return zip(data.dropFirst(), data).map{$0 - $1}
}

func extrapolate(history: [Int]) -> Int {
  // The predicted value is the sum of all final values of each "derivative"
  var diff = history
  var accumulated = 0
  while (!diff.allSatisfy{$0 == 0}) {
    accumulated += diff.last!
    diff = adjacent_difference(diff)
  }
  return accumulated
}

let histories = loadInput().split(separator: "\n").map { $0.split(separator: " ").map { Int($0)! } }
let extrapolateForward = histories.map{ extrapolate(history: $0) }.reduce(0, +)
// There's nothing special about extrapolating backward, simply reverse the order of the input
let extrapolateBackward = histories.map{ extrapolate(history: $0.reversed()) }.reduce(0, +)

print("Part 1:", extrapolateForward)
print("Part 2:", extrapolateBackward)
