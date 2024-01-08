import Foundation

let defaultFilename = "input25.txt"

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

class Network {
  let connections: [Int: Set<Int>]
  let numNodes: Int

  struct Edge: Hashable, Equatable {
    let from: Int
    let to: Int

    init(_ a: Int, _ b: Int) {
      from = min(a, b)
      to = max(a, b)
    }
  }

  init(data: String) {
    // Helper to map names to integer indices
    var indices = [String: Int]()
    let assignIndex: (String.SubSequence) -> Int = {
      let name = String($0)
      if let index = indices[name] { return index }
      let index = indices.count
      indices[name] = index
      return index
    }

    var connections = [Int: Set<Int>]()
    for connectionStr in data.split(separator: "\n") {
      let nodes = connectionStr.split(separator: " ")
      let source = assignIndex(nodes.first!.dropLast())
      nodes.dropFirst().forEach {
        let target = assignIndex($0)
        connections[source, default: Set()].insert(target)
        connections[target, default: Set()].insert(source)
      }
    }
    self.connections = connections
    numNodes = indices.count
  }

  // Find shortest path, respect and update already used edges
  // Using the shortest path reduces the risk of passing between the sub-networks multiple times.
  func findRoute(from: Int, to: Int, usedEdges: inout Set<Edge>) -> Bool {
    // Find shortest path using a breadth first search, keep track of ancestor nodes.
    var ancestors = Array(repeating: -1, count: numNodes)
    for node in connections[from]! { ancestors[node] = from }
    var queue = Queue(connections[from]!)
    while let pos = queue.popFront(), pos != to {
      for next in connections[pos]! {
        if ancestors[next] >= 0 || usedEdges.contains(Edge(pos, next)) {
          continue
        }
        ancestors[next] = pos
        queue.pushBack(next)
      }
    }
    if ancestors[to] == -1 {
      return false
    }
    // Follow chain of ancestors
    var pos = to
    while pos != from {
      let ancestor = ancestors[pos]
      usedEdges.insert(Edge(ancestor, pos))
      pos = ancestor
    }
    return true
  }

  private func searchHelper(from: Int, to: Int, avoidEdges: Set<Edge>) -> Int {
    var reachable = Set<Int>()
    var queue = Queue([from])
    while let pos = queue.popFront() {
      for next in connections[pos]! {
        if reachable.contains(next) || avoidEdges.contains(Edge(pos, next)) {
          continue
        }
        if next == to {
          return reachable.count
        }
        reachable.insert(next)
        queue.pushBack(next)
      }
    }
    return to >= 0 ? -1 : reachable.count
  }

  func areConnected(from: Int, to: Int, avoidEdges: Set<Edge>) -> Bool {
    return searchHelper(from: from, to: to, avoidEdges: avoidEdges) >= 0
  }

  func countNodes(from: Int, avoidEdges: Set<Edge>) -> Int {
    return searchHelper(from: from, to: -1, avoidEdges: avoidEdges)
  }

  func findThreeRoutes() -> (Int, Int, Set<Edge>) {
    while true {
      let a = connections.randomElement()!.key
      let b = connections.randomElement()!.key
      // Attempt to find 4 non-overlapping routes from A to B
      var usedEdges = Set<Edge>()
      let results = (1...4).map { _ in findRoute(from: a, to: b, usedEdges: &usedEdges) }
      // If 4 routes can be found, we have selected A and B in the same sub-network -> retry
      if results.last! {
        continue
      }
      // Otherwise, we're done
      return (a, b, usedEdges)
    }
  }

  func solve() -> Int {
    // Strategy (heuristic):
    // 1.) Pick 2 random points, hope that they are on different sub-networks (may need to retry a
    //     few times).  Call them A and B.
    // 2.) Find 3 routes from A to B that do not share any edges.  If finding a 4th such route is
    //     possible, the points are not in different sub-networks.  If less than 3 routes can be
    //     found, one of them moves back and forth between the sub-networks.
    // 3.) The 3 connections to cut must be part of these three routes.  This greatly limits the
    //     search space.  To identify exactly the 3 critical connections, try to replace each edge
    //     by an alternate route (again without re-using any edges).  Assumption: This fails exactly
    //     for the 3 crictical connections.

    // 1.) and 2.)
    let (a, b, usedEdges) = findThreeRoutes()
    // 3.)
    let criticalEdges = usedEdges.filter { edge in
      !areConnected(from: edge.from, to: edge.to, avoidEdges: usedEdges)
    }
    // Find subnetwork sizes to compute result
    let sizeA = countNodes(from: a, avoidEdges: criticalEdges)
    let sizeB = countNodes(from: b, avoidEdges: criticalEdges)
    return sizeA * sizeB
  }

}

let network = Network(data: loadInput())
print("Solution:", network.solve())
