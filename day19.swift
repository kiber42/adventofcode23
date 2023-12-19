import Foundation

let defaultFilename = "input19.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Check: CustomStringConvertible {
  let varIndex: Int
  let threshold: Int
  let isMaximum: Bool
  let targetWorkflow: Int
  static let varNames: [Character] = ["x", "m", "a", "s"]

  init(_ data: String.SubSequence, _ indices: [String: Int]) {
    let parts = data.split(separator: ":")
    if parts.count == 2 {
      varIndex = Check.varNames.firstIndex(of: parts[0].first!)!
      threshold = Int(parts[0].dropFirst(2))!
      isMaximum = parts[0].dropFirst().first! == "<"
      targetWorkflow = indices[String(parts[1])]!
    } else {
      // final workflow step is not a real check, it only states the fallback target
      varIndex = 0
      threshold = -1
      isMaximum = false
      targetWorkflow = indices[String(parts[0])]!
    }
  }

  var description: String {
    "\(Check.varNames[varIndex]) \(isMaximum ? "<" : ">") \(threshold) -> \(targetWorkflow)"
  }
}

struct MachinePart {
  let values: [Int]
  let score: Int

  init(_ data: String.SubSequence) {
    let cleaned = data.filter { $0 == "," || Int(String($0)) != nil }
    values = cleaned.split(separator: ",").compactMap { Int($0) }
    assert(values.count == 4)
    score = values.reduce(0, +)
  }

  func passes(check: Check) -> Bool {
    (check.isMaximum && values[check.varIndex] < check.threshold)
      || (!check.isMaximum && values[check.varIndex] > check.threshold)
  }
}

class Workflows {
  let entries: [[Check]]
  let indices: [String: Int]

  init(_ data: [String.SubSequence]) {
    let names = data.map { $0.split(separator: "{").first! }
    var indices = names.enumerated().reduce(into: [String: Int]()) {
      dict, item in
      dict[String(item.1)] = item.0
    }
    indices["A"] = -1
    indices["R"] = -2
    self.indices = indices
    entries = data.map {
      let cleaned = $0[$0.index(after: $0.firstIndex(of: "{")!)..<$0.lastIndex(of: "}")!]
      return cleaned.split(separator: ",").map { Check($0, indices) }
    }
  }
}

func partOne(workflows: Workflows, partData: [Substring.SubSequence]) -> Int {
  let start = workflows.indices["in"]!
  let accepted = workflows.indices["A"]!

  // Process each part from list, classify as accepted or rejected
  return partData.map {
    let part = MachinePart($0)
    var index = start
    while index >= 0 {
      index = workflows.entries[index].first { part.passes(check: $0) }!.targetWorkflow
    }
    return index == accepted ? part.score : 0
  }.reduce(0, +)
}

struct InputSegment: CustomStringConvertible {
  let ranges: [ClosedRange<Int>]

  init() {
    ranges = Array(repeating: 1...4000, count: 4)
  }

  private init(_ base: InputSegment, modifiedIndex: Int, modifiedRange: ClosedRange<Int>) {
    ranges = base.ranges.enumerated().map { index, range in
      index == modifiedIndex ? modifiedRange : range
    }
  }

  func insideOutside(check: Check) -> (InputSegment?, InputSegment?) {
    let r = ranges[check.varIndex]
    if (check.isMaximum && r.last! < check.threshold)
      || (!check.isMaximum && r.first! > check.threshold)
    {
      // fully inside
      return (self, nil)
    }
    if (check.isMaximum && r.first! >= check.threshold)
      || (!check.isMaximum && r.last! <= check.threshold)
    {
      // fully outside
      return (nil, self)
    }
    let modified =
      check.isMaximum
      ? [r.first!...check.threshold - 1, check.threshold...r.last!]
      : [check.threshold + 1...r.last!, r.first!...check.threshold]
    return (
      InputSegment(self, modifiedIndex: check.varIndex, modifiedRange: modified[0]),
      InputSegment(self, modifiedIndex: check.varIndex, modifiedRange: modified[1])
    )
  }

  var count: Int {
    ranges.map { $0.count }.reduce(1, *)
  }

  var description: String {
    ranges.map { "\($0.first!)...\($0.last!)" }.joined(separator: ",")
  }
}

func partTwo(workflows: Workflows) -> Int {
  let start = workflows.indices["in"]!
  let accepted = workflows.indices["A"]!

  // Process one segment of parts, count how many are accepted.
  // The segment will be split into subsegments, and any not processed subsegments will be returned
  // so that they can be processed later on.
  let countAcceptedOneSegment: (InputSegment) -> (Int, [InputSegment]) = {
    var index = start
    var segment = $0
    var subsegments = [InputSegment]()
    while index >= 0 {
      for check in workflows.entries[index] {
        let (inside, outside) = segment.insideOutside(check: check)
        if let inside {
          if let outside {
            // take care of this part later
            subsegments.append(outside)
          }
          segment = inside
          index = check.targetWorkflow
          // this workflow step is completed, move on to next
          break
        }
      }
    }
    return (index == accepted ? segment.count : 0, subsegments)
  }

  // Process segments and split into subsegments until each subsegment is fully accepted or rejected
  var toProcess = [InputSegment()]
  var sumAccepted = 0
  while let segment = toProcess.popLast() {
    let (numAccepted, subsegments) = countAcceptedOneSegment(segment)
    sumAccepted += numAccepted
    toProcess.append(contentsOf: subsegments)
  }
  return sumAccepted
}

let blocks = loadInput().split(separator: "\n\n").map { $0.split(separator: "\n") }
let workflows = Workflows(blocks[0])

print("Part 1:", partOne(workflows: workflows, partData: blocks[1]))
print("Part 2:", partTwo(workflows: workflows))
