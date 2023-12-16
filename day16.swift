import Foundation

let defaultFilename = "input16.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

enum Tile: Character {
  case Empty = "."
  case Mirror1 = #"\"#
  case Mirror2 = "/"
  case SplitterH = "-"
  case SplitterV = "|"
}

struct Pos: Hashable {
  let x: Int
  let y: Int

  init(_ x: Int, _ y: Int) {
    self.x = x
    self.y = y
  }

  func step(dir: Direction) -> Pos {
    switch dir {
    case .Up: return Pos(x, y - 1)
    case .Down: return Pos(x, y + 1)
    case .Left: return Pos(x - 1, y)
    case .Right: return Pos(x + 1, y)
    }
  }
}

enum Direction {
  case Up
  case Down
  case Left
  case Right
}

struct Beam: Hashable {
  var pos: Pos
  var dir: Direction

  init(_ pos: Pos, _ dir: Direction) {
    self.pos = pos
    self.dir = dir
  }

  // Evaluate effect of tile on beam.
  // Returns new beam from beam splitter if applicable.
  mutating func process(_ tile: Tile) -> Beam? {
    switch tile {
    case .Empty:
      ()
    case .Mirror1:
      switch dir {
      case .Up: dir = .Left
      case .Down: dir = .Right
      case .Left: dir = .Up
      case .Right: dir = .Down
      }
    case .Mirror2:
      switch dir {
      case .Up: dir = .Right
      case .Down: dir = .Left
      case .Left: dir = .Down
      case .Right: dir = .Up
      }
    case .SplitterH:
      if dir == .Up || dir == .Down {
        dir = .Left
        return Beam(pos, .Right)
      }
    case .SplitterV:
      if dir == .Left || dir == .Right {
        dir = .Up
        return Beam(pos, .Down)
      }
    }
    return nil
  }

  mutating func advance() {
    pos = pos.step(dir: dir)
  }
}

class Grid {
  let data: [[Tile]]
  let maxX, maxY: Int

  init(_ input: String) {
    data = input.split(separator: "\n").map { $0.map { Tile(rawValue: $0)! } }
    maxX = data[0].count
    maxY = data.count
  }

  // Trace beam through contraption, return number of energized (=visited) tiles
  func process(start: Beam) -> Int {
    var beams = [start]
    var processed = Set<Beam>()
    while var beam = beams.popLast() {
      while let tile = grid(at: beam.pos), processed.insert(beam).inserted {
        if let newBeam = beam.process(tile) {
          beams.append(newBeam)
        }
        beam.advance()
      }
    }
    return Set(processed.map{ $0.pos }).count
  }

  func findMaxEnergized() -> Int {
    let startingBeams =
      (0..<maxX).map { Beam(Pos($0, 0), .Down) }
      + (0..<maxY).map { Beam(Pos(0, $0), .Right) }
      + (0..<maxX).map { Beam(Pos($0, maxY - 1), .Up) }
      + (0..<maxY).map { Beam(Pos(maxX - 1, $0), .Left) }
    return startingBeams.map { process(start: $0) }.max()!
  }

  private func grid(at: Pos) -> Tile? {
    0 <= at.x && 0 <= at.y && at.x < maxX && at.y < maxY ? data[at.y][at.x] : nil
  }
}

let grid = Grid(loadInput())
print("Part 1:", grid.process(start: Beam(Pos(0, 0), .Right)))
print("Part 2:", grid.findMaxEnergized())
