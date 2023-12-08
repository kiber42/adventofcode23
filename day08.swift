import Foundation

let defaultFilename = "input08.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Node {
  let id: Int
  let left: Int
  let right: Int

  init(from: String.SubSequence) {
    let tokens = from.split(separator: " ")
    id = Node.findOrAssignNumber(tokens[0])
    left = Node.findOrAssignNumber(tokens[2].dropFirst().dropLast())
    right = Node.findOrAssignNumber(tokens[3].dropLast())
  }

  func process(_ instruction: Character) -> Int {
    return instruction == "L" ? left : right
  }

  static var numbers = [String: Int]()

  // For performance, map all node names to indices and work with those
  private static func findOrAssignNumber(_ str: String.SubSequence) -> Int {
    let s = String(str)
    if let n = numbers[s] {
      return n
    }
    let n = numbers.count
    numbers[s] = n
    return n
  }
}

class Network {
  let instructions: [Character]
  let nodes: [Int: Node]

  init(instructions: String.SubSequence, nodeData: [String.SubSequence]) {
    self.instructions = instructions.map { $0 }
    self.nodes = Dictionary(
      uniqueKeysWithValues: nodeData.map {
        let node = Node(from: $0)
        return (node.id, node)
      })
  }

  func countNumberOfSteps(start: Int, goals: Set<Int>) -> Int {
    // Process instructions and update position until a goal position is reached
    var steps = 0
    var pos = start
    while !goals.contains(pos) {
      let instruction = instructions[steps % instructions.count]
      pos = nodes[pos]!.process(instruction)
      steps += 1
    }
    return steps
  }
}

func partOne(_ network: Network) -> Int {
  if let aaa = Node.numbers["AAA"] {
    let zzz = Node.numbers["ZZZ"]!
    return network.countNumberOfSteps(start: aaa, goals: Set([zzz]))
  }
  return 0
}

func gcd(_ a: Int, _ b: Int) -> Int {
  var a = a, b = b
  while b > 0 {
    (a, b) = (b, a % b)
  }
  return a
}

func lcm(_ a: Int, _ b: Int) -> Int {
  return a * b / gcd(a, b)
}

func partTwo(_ network: Network) -> Int {
  // First, consider all trajectories from **A to **Z individually
  let starts = Node.numbers.compactMap { $0.key.last! == "A" ? $0.value : nil }
  let goals = Set(Node.numbers.compactMap { $0.key.last! == "Z" ? $0.value : nil })
  let stepCounts = starts.map { network.countNumberOfSteps(start: $0, goals: goals) }

  // To determine the earliest time that all ghost camels are at a goal position simultaneously,
  // compute the lowest common multiple of the individual step counts.
  // This works because the puzzle input is designed such that the camels basically "start over"
  // once they move beyond their goal.  Otherwise, things would become a little more messy, but
  // the basic idea should still work.
  return stepCounts.reduce(1, lcm)
}

let blocks = loadInput().split(separator: "\n\n").map { $0.split(separator: "\n") }
let network = Network(instructions: blocks[0][0], nodeData: blocks[1])
print("Part 1:", partOne(network))
print("Part 2:", partTwo(network))
