import Foundation

let defaultFilename = "input10.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

enum Direction: CaseIterable {
  case Up
  case Down
  case Left
  case Right

  var opposite: Direction {
    switch self {
    case .Up: return .Down
    case .Down: return .Up
    case .Left: return .Right
    case .Right: return .Left
    }
  }
}

struct Pos: Hashable, Comparable {
  let x, y: Int

  init(_ x: Int, _ y: Int) {
    self.x = x
    self.y = y
  }

  func neighbour(dir: Direction) -> Pos {
    switch dir {
    case .Up: return Pos(x, y - 1)
    case .Down: return Pos(x, y + 1)
    case .Left: return Pos(x - 1, y)
    case .Right: return Pos(x + 1, y)
    }
  }

  // Sort by row, then by column
  static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.y < rhs.y || (lhs.y == rhs.y && lhs.x < rhs.x)
  }
}

extension Array {
  subscript(safe index: Index) -> Element? {
    0 <= index && index < count ? self[index] : nil
  }
}

enum Pipe: Character, CaseIterable {
  case Horizontal = "-"
  case Vertical = "|"
  case TopLeftCorner = "F"
  case TopRightCorner = "7"
  case BottomLeftCorner = "L"
  case BottomRightCorner = "J"

  var openings: [Direction] {
    switch self {
    case .Horizontal: return [.Left, .Right]
    case .Vertical: return [.Up, .Down]
    case .TopLeftCorner: return [.Down, .Right]
    case .TopRightCorner: return [.Down, .Left]
    case .BottomLeftCorner: return [.Up, .Right]
    case .BottomRightCorner: return [.Up, .Left]
    }
  }

  // Inefficient, but used only once
  static func from(openings: [Direction]) -> Pipe? {
    return Pipe.allCases.first { Set($0.openings) == Set(openings) }
  }
}

class Maze {
  let mainLoop: [(Pos, Pipe)]

  init(from: String) {
    // Parse input, add an empty border to avoid bounds checking
    let lines = from.split(separator: "\n")
    let pipes = lines.map { $0.map { Pipe(rawValue: $0) } }

    let (animalY, row) = lines.enumerated().first { y, row in row.contains("S") }!
    let animalX = row.distance(from: row.startIndex, to: row.firstIndex(of: "S")!)

    let (loop, animalPipe) = Maze.findMainLoop(pipes, Pos(animalX, animalY))
    mainLoop = loop.sorted().map { pos in (pos, pipes[pos.y][pos.x] ?? animalPipe) }
  }

  // Detect the loop the animal is sitting on.
  // Also determine the type of pipe at the animal's position.
  private static func findMainLoop(_ pipes: [[Pipe?]], _ animal: Pos) -> ([Pos], Pipe) {
    let pipeOpeningsAt: (Pos) -> [Direction] = { pipes[safe: $0.y]?[safe: $0.x]??.openings ?? [] }

    // The pipe shape at the animal's position is unknown, we may need to use trial & error.
    // Narrow down the possibilities by checking whether adjacent tiles would match.
    let startDirs = Direction.allCases.filter { dir in
      let pos = animal.neighbour(dir: dir)
      return pipeOpeningsAt(pos).contains(dir.opposite)
    }

    for startDir in startDirs {
      var pos = animal.neighbour(dir: startDir)
      var fromDir = startDir.opposite
      var loop = [animal]
      // Follow loop as far as possible. This terminates either because we're not on a loop or
      // because we reach the animal's position (there is no pipe there).
      while let nextDir = pipeOpeningsAt(pos).first(where: { $0 != fromDir }) {
        loop.append(pos)
        pos = pos.neighbour(dir: nextDir)
        fromDir = nextDir.opposite
      }
      if pos == animal {
        // The attempted starting direction worked out, found the main loop
        return (loop, Pipe.from(openings: [startDir, fromDir])!)
      }
    }
    // Uh oh
    assert(false)
  }

  class State {
    private enum PipeState {
      case None
      case ComingFromAbove
      case ComingFromBelow
    }

    private(set) var isInside = false
    private var pipeState = PipeState.None

    func update(_ pipe: Pipe) {
      // We process each row separately, from left to right.
      // Not all pipe types are permissible in each state.
      assert(
        (pipeState == .ComingFromAbove || pipeState == .ComingFromBelow)
          == (pipe == .Horizontal || pipe == .TopRightCorner || pipe == .BottomRightCorner),
        "Cannot handle pipe type \(pipe) in state \(pipeState)")

      // Check whether we traverse a boundary or
      // just moved along the side of the pipe without crossing it
      switch pipe {
      case .Vertical: isInside = !isInside
      case .Horizontal: ()
      case .TopLeftCorner: pipeState = .ComingFromBelow
      case .BottomLeftCorner: pipeState = .ComingFromAbove
      case .TopRightCorner:
        if pipeState == .ComingFromAbove {
          isInside = !isInside
        }
        pipeState = .None
      case .BottomRightCorner:
        if pipeState == .ComingFromBelow {
          isInside = !isInside
        }
        pipeState = .None
      }
    }
  }

  func countInsideFields() -> Int {
    var count = 0
    let state = State()
    var lastPos = Pos(0, 0)
    // Process all pipe parts that belong to the main loop one row at a time,
    // and keep track of whether we're currently inside or outside.
    // Count inside cells in between pipe segments
    for (pos, pipe) in mainLoop {
      if pos.y > lastPos.y {
        assert(!state.isInside, "Must be outside of loop at end of each row")
        lastPos = Pos(0, pos.y)
      }
      if state.isInside {
        let numCellsBetweenPipes = pos.x - lastPos.x - 1
        count += numCellsBetweenPipes
      }
      state.update(pipe)
      lastPos = pos
    }
    return count
  }
}

let maze = Maze(from: loadInput())
print("Part 1:", maze.mainLoop.count / 2)
print("Part 2:", maze.countInsideFields())
