import Foundation

let defaultFilename = "input18.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Pos {
  let x: Int
  let y: Int

  func move(_ dir: Direction, _ steps: Int) -> Pos {
    switch dir
    {
    case .Right: return Pos(x: x + steps, y: y)
    case .Down: return Pos(x: x, y: y + steps)
    case .Left: return Pos(x: x - steps, y: y)
    case .Up: return Pos(x: x, y: y - steps)
    }
  }
}

enum Direction: Int {
  case Right = 0
  case Down = 1
  case Left = 2
  case Up = 3

  static func parse(_ c: Character) -> Direction {
    switch c {
    case "R": return .Right
    case "D": return .Down
    case "L": return .Left
    case "U": return .Up
    default: assert(false)
    }
  }
}

struct Instruction {
  let dir: Direction
  let steps: Int

  init(applyBugfixTo: String.SubSequence) {
    let tokens = applyBugfixTo.split(separator: " ")
    dir = Direction(rawValue: Int(tokens[2].dropLast().suffix(1))!)!
    steps = Int(tokens[2].dropFirst(2).prefix(5), radix: 16)!
  }

  init(from: String.SubSequence) {
    let tokens = from.split(separator: " ")
    dir = Direction.parse(tokens[0].first!)
    steps = Int(tokens[1])!
  }
}

func run(bugfix: Bool) -> Int {
  // Use instructions to build a list of the corners of the lava pool perimeter
  let instructions = loadInput().split(separator: "\n").map {
    bugfix ? Instruction(applyBugfixTo: $0) : Instruction(from: $0)
  }
  var pos = Pos(x: 0, y: 0)
  let vertices = instructions.map {
    pos = pos.move($0.dir, $0.steps)
    return pos
  }

  // Use Shoelace formula to compute contained area:
  // - Sum up the determinants of all pairs of adjacent points, multiply by 1/2
  //   (effectively breaking the polygon into a fan of triangles).
  // - Depending on the order (clockwise / counter-clockwise), the sign might be wrong.
  let pairs = (0..<vertices.count).map { (vertices[$0], vertices[($0 + 1) % vertices.count]) }
  let area = abs(pairs.map { $0.x * $1.y - $0.y * $1.x }.reduce(0, +)) / 2

  // Boundary points contribute only 1/2 in the Shoelace formula, but we want to count them as 1 and
  // therefore add 1/2 for each boundary point. Also, there is an overall difference of 4 between
  // the number of right turns and left turns in the perimeter.  Those four (net) positions only
  // contribute 1/4 each in the Shoelace formula, so we add another 1/4 for those (times 4 => 1).
  let boundaryLength = instructions.map { $0.steps }.reduce(0, +)
  return area + boundaryLength / 2 + 1
}

print("Part 1:", run(bugfix: false))
print("Part 2:", run(bugfix: true))
