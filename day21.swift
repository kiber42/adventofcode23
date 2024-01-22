import Foundation

let defaultFilename = "input21.txt"

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

  var neighbours: [Pos] { [Pos(x + 1, y), Pos(x - 1, y), Pos(x, y + 1), Pos(x, y - 1)] }

  var description: String { "(\(x)|\(y))" }
}

func loadGarden() -> ([[Bool]], Pos) {
  var start: Pos? = nil
  let garden = loadInput().split(separator: "\n").enumerated().map { y, row in
    row.enumerated().map { x, c in
      if c == "S" { start = Pos(x, y) }
      return c != "#"
    }
  }
  return (garden, start!)
}

func findReachable(garden: inout [[Bool]], start: Pos, maxSteps: Int) -> Set<Pos> {
  // Build two sets of reachable tiles, for odd/even number of steps
  var reachableNow = Set([start])
  var reachableOther = Set<Pos>()
  var newlyAdded = reachableNow
  for _ in 1...maxSteps {
    swap(&reachableNow, &reachableOther)
    // Mark recently reached plots as inaccessible.
    newlyAdded.forEach { garden[$0.y][$0.x] = false }
    // Select accessible neighbours of recently reached plots.
    // (The puzzles are designed such that we never reach a border, so we skip bounds checking.)
    newlyAdded = Set(newlyAdded.flatMap { $0.neighbours.filter { garden[$0.y][$0.x] } })
    if newlyAdded.isEmpty { break }
    reachableNow.formUnion(newlyAdded)
  }
  return reachableNow
}

func partOne() -> Int {
  var (garden, start) = loadGarden()
  return findReachable(garden: &garden, start: start, maxSteps: garden.count < 100 ? 6 : 64).count
}

func partTwo() -> Int {
  let maxSteps = 26_501_365

  // This part probably can be solved only because the actual input (not the example) has several
  // rows and columns that are free of rocks, namely those at the borders and in the center.  The
  // task becomes easier because the (original) garden tile has a square shape and the starting
  // point is in its center.

  let (original, start) = loadGarden()
  let tileSize = original.first!.count
  assert(tileSize == original.count) /* square garden */
  assert(start.x == start.y && 2 * start.x + 1 == tileSize) /* start is in center */

  // The total number of steps is just large enough that one ends up exactly at a border when
  // walking in a straight line from the start in any direction.

  if maxSteps % (2 * tileSize) != start.x { return -1 } /* can't solve example input */

  // We need to work out the number of "garden copies" that are reachable, and need to pay special
  // attention to copies near the border.

  // Let's look at a simplified example (the smallest one that has all relevant properties), using
  // 5 x 5 instances of the original garden tile:
  //
  // . d T d .
  // d D O D d
  // T O E O T
  // d D O D d
  // . d T d .
  //
  // The tiles marked T are the 4 tips of the resulting diamond shape.
  // D and d are diagonal tiles, either mostly covered (D) or barely covered (d).
  // O and E are fully covered tiles that are either an Odd or Even number of tiles away from the
  // starting tile.  (The original tile's side needs to have an odd length to allow the starting
  // point to be exactly in its center; this necessarily results in different sets of reachable
  // plots between neighbouring tiles).
  // Counts: 5 fully covered tiles (4 O, 1 E), 12 diagonals (8 d, 4 D), 4 tips.

  // If we extend this to 7 x 7, we find the following pattern:
  //
  // . . d T d . .
  // . d D E D d .
  // d D E O E D d
  // T E O E O E T
  // d D E O E D d
  // . d D E D d .
  // . . d T d . .
  //
  // Counts: 13 fully covered tiles (9 E, 4 O), 5 sets of diagonals (3 * 4d, 2 * 4D), 4 tips.

  // And for 9 x 9 (n = 4), we have 16 O, 9 E, 4 * 4d, 3 * 4D, 4 T.
  // . . . d T d . . .
  // . . d D O D d . .
  // . d D O E O D d .
  // d D O E O E O D d
  // T O E O E O E O T
  // d D O E O E O D d
  // . d D O E O D d .
  // . . d D O D d . .
  // . . . d T d . . .

  // Let's generalize to N x N (N odd) and define N = 2 * n + 1 for convenience.  The examples above
  // have N = 5, 7, 9 and n = 2, 3, 4.  Let's further group the diagonal tiles and tips, since they
  // always appear in multiples of 4 and there's no need to separate the sides of the diamond).
  // We find these counts: #O = n * n, #E: (n - 1) * (n - 1), #(4d) = n, #(4D) = n - 1, , #(4T) = 1
  // (E and O switch their roles depending whether n is even or odd. For the full input, it's even.)

  // Now we know everything we need to compute the total number of reachable plots.

  // Let's do this! :)

  // As above, we start with a 5 x 5 garden to establish the reachable plots for each type of tile.
  let numSteps = 2 * tileSize + start.x
  let newCenter = Pos(numSteps, numSteps)
  let gardenSize = 5
  let repeatedColumns = original.map { row in (1...gardenSize).flatMap { _ in row } }
  var repeatedGarden = Array(Array(repeating: repeatedColumns, count: gardenSize).joined())
  let reachable = findReachable(garden: &repeatedGarden, start: newCenter, maxSteps: numSteps)

  var plotsOnTile = [Pos: Int]()
  for plot in reachable {
    let tilePos = Pos(plot.x / tileSize - 2, plot.y / tileSize - 2)
    plotsOnTile[tilePos, default: 0] += 1
  }
  let O = plotsOnTile[Pos(1, 0)]!
  let E = plotsOnTile[Pos(0, 0)]!
  let d = [Pos(-2, -1), Pos(+2, -1), Pos(-2, +1), Pos(+2, +1)].map { plotsOnTile[$0]! }.reduce(0, +)
  let D = [Pos(-1, -1), Pos(-1, +1), Pos(+1, -1), Pos(+1, +1)].map { plotsOnTile[$0]! }.reduce(0, +)
  let T = [Pos(-2, 0), Pos(+2, 0), Pos(0, -2), Pos(0, +2)].map { plotsOnTile[$0]! }.reduce(0, +)

  // Compute the number of times each type of garden tile appears and put it all together!
  let n = maxSteps / tileSize
  return n * n * O + (n - 1) * (n - 1) * E + n * d + (n - 1) * D + T
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
