import Foundation

let defaultFilename = "input23.txt"

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
  let x: Int
  let y: Int

  init(_ x: Int, _ y: Int) {
    self.x = x
    self.y = y
  }

  func neighbour(_ dir: Direction) -> Pos {
    switch dir {
    case .Right: return Pos(x + 1, y)
    case .Down: return Pos(x, y + 1)
    case .Left: return Pos(x - 1, y)
    case .Up: return Pos(x, y - 1)
    }
  }

  var description: String { "(\(x)|\(y))" }
}

enum Direction: Character, CaseIterable {
  case Right = ">"
  case Down = "v"
  case Left = "<"
  case Up = "^"

  var opposite: Direction {
    switch self {
    case .Right: return .Left
    case .Down: return .Up
    case .Left: return .Right
    case .Up: return .Down
    }
  }
}

enum Tile {
  case Path
  case Forest
  case Slope(Direction)

  init(from: Character) {
    if from == "." {
      self = .Path
    } else if from == "#" {
      self = .Forest
    } else {
      self = .Slope(Direction(rawValue: from)!)
    }
  }
}

struct Route: Hashable {
  let from: Int
  let to: Int
}

struct Network {
  let connections: [Int: [Int]]
  let distances: [Route: Int]
}

struct NetworkBuilder {
  let mapData: [[Tile]]

  func run(fromIndex: Pos, ignoreSlopes: Bool) -> Network {
    var connections = [Int: Set<Int>]()
    var distances = [Route: Int]()
    var toProcess = [(fromIndex, Direction.Down)]
    var nodeIndices = [Pos: Int]()
    nodeIndices[fromIndex] = 0
    nodeIndices[Pos(mapData[0].count - 2, mapData.count - 1)] = 1

    // Traverse input in text form, move from node to node, convert to weighted graph.
    while let (pos, dir) = toProcess.popLast() {
      let node = findNextNode(from: pos, startDir: dir, ignoreSlopes: ignoreSlopes)

      let fromIndex = nodeIndices[pos]!
      var toIndex = nodeIndices[node.pos]
      if toIndex == nil {
        toIndex = nodeIndices.count
        nodeIndices[node.pos] = toIndex!
        toProcess.append(contentsOf: node.dirs.map { (node.pos, $0) })
      }
      connections[fromIndex, default: Set()].insert(toIndex!)
      distances[Route(from: fromIndex, to: toIndex!)] = node.distance
      // In part 2, the graph is undirected (both directions are always possible)
      if ignoreSlopes {
        connections[toIndex!, default: Set()].insert(fromIndex)
        distances[Route(from: toIndex!, to: fromIndex)] = node.distance
      }
    }
    return Network(connections: connections.mapValues { $0.sorted() }, distances: distances)
  }

  private struct Node {
    let distance: Int
    let pos: Pos
    let dirs: [Direction]
  }

  private func findNextNode(from: Pos, startDir: Direction, ignoreSlopes: Bool) -> Node {
    var lastDir = startDir
    var pos = from
    var distance = 0
    while true {
      pos = pos.neighbour(lastDir)
      distance += 1

      // Find valid directions for next step
      let options = Direction.allCases.filter { dir in
        let next = pos.neighbour(dir)
        if next.y <= 0 || next.y >= mapData.count || dir == lastDir.opposite { return false }
        switch mapData[next.y][next.x] {
        case .Path: return true
        case .Forest: return false
        case .Slope(let slopeDir): return ignoreSlopes || slopeDir == dir
        }
      }
      if options.count != 1 {
        // Reached a dead-end (=goal) or multiple possible next steps (node)
        return Node(distance: distance, pos: pos, dirs: options)
      }

      lastDir = options[0]
    }
  }
}

class Map {
  let network: Network

  init(_ data: String, ignoreSlopes: Bool) {
    let map = loadInput().split(separator: "\n").map { $0.map { Tile(from: $0) } }
    network = NetworkBuilder(mapData: map).run(fromIndex: Pos(1, 0), ignoreSlopes: ignoreSlopes)
  }

  func findLongestHike() -> Int {
    var longest = 0
    var toProcess = [(0, 0, Int64(1) << 0)]
    while let (totalDistance, from, visited) = toProcess.popLast() {
      for to in network.connections[from]! {
        let toBits = Int64(1) << to
        if visited & toBits != 0 { continue }
        let distance = network.distances[Route(from: from, to: to)]!
        if to == 1 {
          longest = max(longest, totalDistance + distance)
          break
        }
        toProcess.append((totalDistance + distance, to, visited + toBits))
      }
    }
    return longest
  }
}

func partOne() -> Int {
  Map(loadInput(), ignoreSlopes: false).findLongestHike()
}

func partTwo() -> Int {
  Map(loadInput(), ignoreSlopes: true).findLongestHike()
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
