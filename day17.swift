import Foundation

let defaultFilename = "input17.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Queue<T> {
  private var data: [T]
  private var index = 0

  init<S>(_ data: S) where S: Sequence<T> { self.data = Array(data) }

  mutating func popFront() -> T? {
    if index >= data.count { return nil }
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

struct Pos: Hashable {
  let x: Int
  let y: Int

  func advance(_ dir: Direction, max: Pos, numSteps: Int = 1) -> Pos? {
    let p = Pos(x: x + dir.delta.x * numSteps, y: y + dir.delta.y * numSteps)
    return p.x >= 0 && p.x < max.x && p.y >= 0 && p.y < max.y ? p : nil
  }
}

enum Direction: Int {
  case Up = 0
  case Right = 1
  case Down = 2
  case Left = 3

  var delta: Pos {
    switch self {
    case .Up: return Pos(x: 0, y: -1)
    case .Right: return Pos(x: 1, y: 0)
    case .Down: return Pos(x: 0, y: 1)
    case .Left: return Pos(x: -1, y: 0)
    }
  }
  var turnRight: Direction { Direction(rawValue: (self.rawValue + 1) % 4)! }
  var turnLeft: Direction { Direction(rawValue: (self.rawValue + 3) % 4)! }
}

struct State: Hashable {
  let pos: Pos
  let dir: Direction
}

class CityMap {
  let heatMap: [Int]
  let extents: Pos

  init(_ input: String) {
    heatMap = input.compactMap { Int(String($0)) }
    let width = input.distance(from: input.startIndex, to: input.firstIndex(of: "\n")!)
    extents = Pos(x: width, y: heatMap.count / width)
    assert(heatMap.count == extents.x * extents.y)
  }

  private struct BestPathInfo {
    let heat: Int
    let ancestor: State?
  }

  func findColdestPath(moves: ClosedRange<Int>) -> Int {
    // We deal with the strange characteristics of the crucibles by defining one "turn" as follows:
    // First, move straight by a valid distance, then turn left or right.
    // In this way, we can only create valid paths.

    // Since the first turn might move right or down, we have two initial states.
    let initial = [
      State(pos: Pos(x: 0, y: 0), dir: .Right), State(pos: Pos(x: 0, y: 0), dir: .Down),
    ]
    var bestPath = initial.reduce(into: [State: BestPathInfo]()) {
      $0[$1] = BestPathInfo(heat: 0, ancestor: nil)
    }
    // Further explore currently reachable states, keep track of optimal way to reach any state
    // by referring back to the ancestor that results in the lowest heat
    var toProcess = Queue(initial)
    while let state = toProcess.popFront() {
      let nextDirs = [state.dir.turnLeft, state.dir.turnRight]
      var myHeat = bestPath[state]!.heat
      // Construct next reachables states by varying the number of steps and the direction in which
      // to turn at the end
      for numSteps in 1...moves.upperBound {
        if let nextPos = state.pos.advance(state.dir, max: extents, numSteps: numSteps) {
          myHeat += heatMap[extents.x * nextPos.y + nextPos.x]
          if numSteps < moves.lowerBound { continue }
          for nextDir in nextDirs {
            let nextState = State(pos: nextPos, dir: nextDir)
            if let currentBest = bestPath[nextState] {
              if myHeat >= currentBest.heat { continue }
            }
            // New reachable state / better path to known reachable state. (Re-)evaluate that state.
            bestPath[nextState] = BestPathInfo(heat: myHeat, ancestor: state)
            toProcess.pushBack(nextState)
          }
        } else {
          // Step would lead out of city, no need to move further in this direction
          break
        }
      }
    }
    // Check both acceptable final states
    let exit = Pos(x: extents.x - 1, y: extents.y - 1)
    return min(
      bestPath[State(pos: exit, dir: .Right)]?.heat ?? -1,
      bestPath[State(pos: exit, dir: .Down)]?.heat ?? -1)
  }
}

let city = CityMap(loadInput())
print("Part 1:", city.findColdestPath(moves: 1...3))
print("Part 2:", city.findColdestPath(moves: 4...10))
