import Foundation

let defaultFilename = "input24.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Vector3: Equatable {
  let x: Int
  let y: Int
  let z: Int

  init(_ x: Int, _ y: Int, _ z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }

  static func + (_ a: Vector3, _ b: Vector3) -> Vector3 {
    return Vector3(a.x + b.x, a.y + b.y, a.z + b.z)
  }

  static func - (_ a: Vector3, _ b: Vector3) -> Vector3 {
    return Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
  }

  static func * (_ v: Vector3, _ s: Int) -> Vector3 {
    return Vector3(s * v.x, s * v.y, s * v.z)
  }
}

struct Trajectory {
  let r0: Vector3
  let v: Vector3

  init(r0: Vector3, v: Vector3) {
    self.r0 = r0
    self.v = v
  }

  init(_ data: String.SubSequence) {
    let n = data.replacing(",", with: "").split(separator: " ").compactMap { Int($0) }
    assert(n.count == 6)
    r0 = Vector3(n[0], n[1], n[2])
    v = Vector3(n[3], n[4], n[5])
  }

  func pos(t: Int) -> Vector3 {
    return r0 + v * t
  }
}

func intersection2D(_ a: Trajectory, _ b: Trajectory) -> (Double, Double)? {
  // Solve system of equations:
  // O1 + t * D1 = O2 + u * D2
  // Define Delta = O2 - O1. Isolate and eliminate t:
  // u * D2 + Delta = t * D1
  // (u * D2.X + Delta.X) / D1.X = (u * D2.Y + Delta.Y) / D1.Y
  // Solve for u and simplify
  // u * (D2.X / D1.X - D2.Y / D1.Y) = Delta.Y / D1.Y - Delta.X / D1.X
  // u = (Delta.Y * D1.X - Delta.X * D1.Y) / (D2.X * D1.Y - D1.X * D2.Y)

  let det = a.v.y * b.v.x - a.v.x * b.v.y
  if det == 0 { return nil }  // parallel lines

  let deltaX = b.r0.x - a.r0.x
  let deltaY = b.r0.y - a.r0.y

  let u = Double(deltaY * a.v.x - deltaX * a.v.y) / Double(det)
  let t = Double(deltaY * b.v.x - deltaX * b.v.y) / Double(det)
  let inFuture = u > 0 && t > 0
  let intersection = (Double(a.r0.x) + t * Double(a.v.x), Double(a.r0.y) + t * Double(a.v.y))
  return inFuture ? intersection : nil
}

func partOne() -> Int {
  let paths = loadInput().split(separator: "\n").map { Trajectory($0) }
  let low = paths.count < 100 ? 7.0 : 200000000000000.0
  let high = paths.count < 100 ? 27.0 : 400000000000000.0

  var collisions = 0
  for i in 0..<paths.count {
    for j in i + 1..<paths.count {
      if let (x, y) = intersection2D(paths[i], paths[j]) {
        if x >= low && y >= low && x <= high && y <= high { collisions += 1 }
      }
    }
  }
  return collisions
}

func partTwo() -> Int {
  let hailstones = loadInput().split(separator: "\n").map { Trajectory($0) }

  // Pick three "random" hailstones, this is sufficient to determine the stone trajectory (6 DOFs).
  // Each hailstone adds 2 constraints (the position of the hit has 3 DOFs, but we don't know the
  // time at which we hit it).  Therefore we need 3 hailstones as constraints.

  // Note: The below approach will not find the solution if the x component of the stone velocity
  //       matches that of one of the first two selected hailstones.  If this happens, pick other
  //       hailstones as constraints.
  assert(hailstones.count >= 3)
  let a = hailstones[0]
  let b = hailstones[1]
  let c = hailstones[2]

  // Instead of solving the full system (too much linear algebra for my taste, not fun to do in
  // vanilla Swift), we guess two unknowns and solve the simpler remaining system.  The hit times
  // can be very large, while the stone velocity has to be of the same order of magnitude as the
  // hailstone velocities.  We guess the x and y components of the stone velocity, compute the
  // remaining stone trajectory using the first two hailstones (A and B), and confirm our guesses
  // by testing if we also hit hailstone C.

  for vx in -500...500 {
    for vy in -500...500 {
      // Some amount of lin. alg. is necessary I'm afraid.
      // Use Wolfram Alpha or similar if you want, because there isn't anything interesting here.
      // Hitting A at t1 means that: a.r0 + t1 * a.v = stone.r0 + t1 * v
      // =>  t1 = (a.r0 - stone.r0).x / (v - a.v).x
      // and t1 = (a.r0 - stone.r0).y / (v - a.v).y
      // =>  (a.r0 - stone.r0).x * (v - a.v).y / (v - a.v).x - a.r0.y = -stone.r0.y
      // Similarly for B at t2:
      // =>  (b.r0 - stone.r0).x * (v - b.v).y / (v - b.v).x - b.r0.y = -stone.r0.y
      // Define k1 = (v - a.v).y / (v - a.v).x
      // and    k2 = (v - b.v).y / (v - b.v).x
      // And find the following compact formula:
      // stone.r0.x = (a.r0.y - b.r0.y - a.r0.x * k1 + b.r0.x * k2) / (k2 - k1)
      if vx == a.v.x || vx == b.v.x { continue }
      let k1 = Double(vy - a.v.y) / Double(vx - a.v.x)
      let k2 = Double(vy - b.v.y) / Double(vx - b.v.x)
      if k1 == k2 { continue }
      let r0x = Int(
        (Double(a.r0.y) - Double(b.r0.y) - Double(a.r0.x) * k1 + Double(b.r0.x) * k2) / (k2 - k1))

      let t1 = (a.r0.x - r0x) / (vx - a.v.x)
      let t2 = (b.r0.x - r0x) / (vx - b.v.x)
      if t1 == t2 { continue }
      let r0y = a.r0.y + (a.v.y - vy) * t1
      let vz = (b.pos(t: t2) - a.pos(t: t1)).z / (t2 - t1)
      let r0z = a.r0.z + (a.v.z - vz) * t1
      let stone = Trajectory(r0: Vector3(r0x, r0y, r0z), v: Vector3(vx, vy, vz))

      // Check if we also hit hailstone C. Be careful to avoid division by zero.
      let t3 =
        vx != c.v.x
        ? (c.r0.x - r0x) / (vx - c.v.x)
        : vy != c.v.y ? (c.r0.y - r0y) / (vy - c.v.y) : (c.r0.z - r0z) / (vz - c.v.z)
      if c.pos(t: t3) == stone.pos(t: t3) {
        return r0x + r0y + r0z
      }
    }
  }
  return -1
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
