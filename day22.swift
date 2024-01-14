import Foundation

let defaultFilename = "input22.txt"

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
  let z: Int

  init<T: StringProtocol>(_ data: T) {
    let n = data.split(separator: ",").compactMap { Int($0) }
    assert(n.count == 3)
    x = n[0]
    y = n[1]
    z = n[2]
  }
}

enum Axis {
  case X
  case Y
  case Z
}

struct Brick {
  let start: Pos
  let alignment: Axis
  let length: Int
  let height: Int

  init<T: StringProtocol>(_ data: T) {
    let positions = data.split(separator: "~").map { Pos($0) }
    assert(positions.count == 2)
    start = positions[0]
    if positions[1].x != start.x {
      alignment = .X
      length = positions[1].x - start.x + 1
      height = 1
    } else if positions[1].y != start.y {
      alignment = .Y
      length = positions[1].y - start.y + 1
      height = 1
    } else {
      alignment = .Z
      length = 1
      height = positions[1].z - start.z + 1
    }
    assert(height > 0)
    assert(length > 0)
  }
}

struct Grid<T: Equatable>: CustomStringConvertible, Equatable {
  private let width: Int
  private var data: [T]

  init(width: Int, height: Int, initialValue: T) {
    self.width = width
    data = Array(repeating: initialValue, count: width * height)
  }

  subscript(_ p: Pos) -> T {
    get { data[p.y * width + p.x] }
    set { data[p.y * width + p.x] = newValue }
  }

  // Allow accessing the grid using a brick and an offset along the brick's axis (X or Y)
  subscript(_ brick: Brick, _ offset: Int) -> T {
    get { data[index(brick, offset)] }
    set { data[index(brick, offset)] = newValue }
  }

  private func index(_ brick: Brick, _ offset: Int) -> Int {
    let x = brick.start.x + (brick.alignment == .X ? offset : 0)
    let y = brick.start.y + (brick.alignment == .Y ? offset : 0)
    return y * width + x
  }

  var description: String {
    (0..<data.count / width).map { "\(data[$0*width..<($0+1)*width])" }.joined(separator: "\n")
  }
}

func findSupportingBricks(_ bricks: [Brick]) -> [Set<Int>] {
  // Keep track of heights and of which blocks are on top
  var heightMap = Grid(width: 10, height: 10, initialValue: 0)
  var topBlock = Grid(width: 10, height: 10, initialValue: -1)
  var supportedBy = [Set<Int>]()
  supportedBy.reserveCapacity(bricks.count)
  // Simulate falling bricks.
  // Identify supporting bricks by checking height map for each segment of the current brick
  for (index, brick) in bricks.enumerated() {
    let maxZ = (0..<brick.length).map { heightMap[brick, $0] }.max()!
    var supportersOfCurrentBrick = Set<Int>()
    (0..<brick.length).forEach {
      if maxZ > 0 && maxZ == heightMap[brick, $0] {
        supportersOfCurrentBrick.insert(topBlock[brick, $0])
      }
      heightMap[brick, $0] = maxZ + brick.height
      topBlock[brick, $0] = index
    }
    supportedBy.append(supportersOfCurrentBrick)
  }
  return supportedBy
}

func partOne(_ allSupporters: [Set<Int>]) -> Int {
  let soleSupporters = Set(allSupporters.compactMap { $0.count == 1 ? $0.first! : nil })
  return bricks.count - soleSupporters.count
}

func partTwo(_ supporters: [Set<Int>]) -> Int {
  // Rearrange list of supporting bricks into a list of supported bricks
  var supported = Array(repeating: Set<Int>(), count: bricks.count)
  for (index, supportedBy) in supporters.enumerated() {
    supportedBy.forEach { supported[$0].insert(index) }
  }

  // Pretend to remove one brick at a time and find bricks that are no longer supported and will
  // therefore disintegrate.  Continue as long as there are unprocessed disintegrating blocks.
  return (0..<supported.count).map { removedIndex in
    var disintegrated = Set<Int>()
    var disintegrating = Set([removedIndex])
    while let next = disintegrating.popFirst() {
      disintegrated.insert(next)
      supported[next].forEach{
        if supporters[$0].isSubset(of: disintegrated) {
          disintegrating.insert($0)
        }
      }
    }
    return disintegrated.count - 1
  }.reduce(0, +)
}

// Generate bricks from input, immediately sort by z position
let bricks = loadInput().split(separator: "\n").map { Brick($0) }.sorted { $0.start.z < $1.start.z }
let supporters = findSupportingBricks(bricks)
print("Part 1:", partOne(supporters))
print("Part 2:", partTwo(supporters))
