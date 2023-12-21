import Foundation

let defaultFilename = "input20.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func gcd(_ a: Int, _ b: Int) -> Int {
  var a = a
  var b = b
  while b > 0 { (a, b) = (b, a % b) }
  return a
}

func lcm(_ a: Int, _ b: Int) -> Int { a * b / gcd(a, b) }

// Poor man's double-ended queue implementation
struct Queue<T> {
  private var data: [T]
  private var index = 0

  init(_ data: [T]) { self.data = data }

  mutating func popFront() -> T? {
    if index >= data.count {
      return nil
    }
    index += 1
    return data[index - 1]
  }

  mutating func pushBack(_ element: T) {
    if index > 1_000_000 {
      data.removeFirst(index)
      index = 0
    }
    data.append(element)
  }
}

enum Pulse {
  case Low
  case High
}

protocol IModule {
  func process(pulse: Pulse, source: Int) -> Pulse?
}

class Broadcaster: IModule {
  func process(pulse: Pulse, source: Int) -> Pulse? { return pulse }
}

class FlipFlop: IModule {
  var state = false

  func process(pulse: Pulse, source: Int) -> Pulse? {
    // Ignore high pulses; flip state on low pulse
    if pulse == .High { return nil }
    state = !state
    return state ? .High : .Low
  }
}

class Conjunction: IModule {
  var lowInputs: Set<Int>

  init(connected: [Int]) {
    // Initially, remember low from all inputs
    lowInputs = Set(connected)
  }

  func process(pulse: Pulse, source: Int) -> Pulse? {
    // If all connected inputs sent high as their last pulse, send low pulse; otherwise high
    if pulse == .High {
      lowInputs.remove(source)
      return lowInputs.isEmpty ? .Low : .High
    }
    lowInputs.insert(source)
    return .High
  }
}

class Network {
  let modules: [IModule]
  let inputs: [[Int]]
  let outputs: [[Int]]

  var cycle = 0
  var pulseCounts = [Pulse.Low: 0, Pulse.High: 0]

  init(_ data: [String.SubSequence]) {
    // Parse into intermediate structure using module names as strings
    var typesAndOutputs = [String: (Character, [String])]()
    var names = ["broadcaster"]
    var indices = [names[0]: 0]
    for line in data {
      let parts = line.split(separator: " -> ")
      let name = String(parts[0].split(separator: " ").first!.replacing("%", with: "").replacing("&", with: ""))
      typesAndOutputs[name] = (parts[0].first!, parts[1].split(separator: ", ").map { String($0) })
      if name != "broadcaster" {
        indices[name] = indices.count
        names.append(name)
      }
    }

    let outputs = (0..<indices.count).map { typesAndOutputs[names[$0]]!.1.map { indices[$0] ?? 1000 } }
    let inputs = (0..<indices.count).map { target in
      outputs.enumerated().compactMap { source, outputs in outputs.contains(target) ? source : nil }
    }

    self.modules = (0..<indices.count).map { index in
      switch typesAndOutputs[names[index]]!.0  {
        case "b": return Broadcaster()
        case "%": return FlipFlop()
        case "&": return Conjunction(connected: inputs[index])
        default: exit(1)
      }
    }
    self.inputs = inputs
    self.outputs = outputs
  }

  // Send low pulse to broadcast node.
  // Updates pulse counts and returns indices of monitored nodes that received a low pulse.
  @discardableResult
  func broadcast(toMonitor: Set<Int> = Set()) -> Set<Int> {
    var queue = Queue([(-1, 0, Pulse.Low)])
    var receivedLow = Set<Int>()
    cycle += 1
    while let (source, index, pulse) = queue.popFront() {
      pulseCounts[pulse]! += 1
      if pulse == .Low && toMonitor.contains(index) {
        receivedLow.insert(index)
      }
      if index >= modules.count {
        // Sending to unconnected module, don't process further
        continue
      }
      if let outputPulse = modules[index].process(pulse: pulse, source: source) {
        outputs[index].forEach { queue.pushBack((index, $0, outputPulse)) }
      }
    }
    return receivedLow
  }
}

func partOne() -> Int {
  let network = Network(loadInput().split(separator: "\n"))
  while network.cycle < 1000 { network.broadcast() }
  return network.pulseCounts.values.reduce(1, *)
}

func partTwo() -> Int {
  // The input seems to be constructed such that the rx node has one Conjunction input.
  // Assume that all inputs to this Conjuction can be treated as independent.
  // Determine their cycle length and compute the lowest common multiple.
  let network = Network(loadInput().split(separator: "\n"))
  let toRx = network.outputs.firstIndex(of: [1000])
  if toRx == nil {
    // Happens for example input
    return -1
  }
  let secondLevelInputs = Set(network.inputs[toRx!])
  assert(network.modules[toRx!] is Conjunction)
  assert(secondLevelInputs.allSatisfy { network.modules[$0] is Conjunction })

  // Keep broadcasting until all inputs to the final Conjunction module each received a low pulse.
  // The input is constructed such that these pulses arrive in regular intervals.
  var cycleLength = [Int: Int]()
  while cycleLength.count < secondLevelInputs.count {
    let receivedLow = network.broadcast(toMonitor: secondLevelInputs)
    receivedLow.forEach { cycleLength[$0] = network.cycle }
  }
  return cycleLength.values.reduce(1, lcm)
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
