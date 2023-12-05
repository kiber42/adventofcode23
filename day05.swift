import Foundation

let defaultFilename = "input05.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

struct Conversion {
  let sourceRange: Range<Int>
  let offset: Int
}

func parseSeedsAndMaps() -> ([Int], [[Conversion]]) {
  let blocks = loadInput().split(separator: "\n\n")
  let seeds = blocks.first!.split(separator: " ").compactMap { Int($0) }
  let maps = blocks.dropFirst().map {
    $0.split(separator: "\n").dropFirst().map { line in
      let n = line.split(separator: " ").map { Int(String($0))! }
      return Conversion(sourceRange: n[1]..<n[1] + n[2], offset: n[0] - n[1])
    }
  }
  return (seeds, maps)
}

func findLocation(seed: Int, _ maps: [[Conversion]]) -> Int {
  var current = seed
  for map in maps {
    if let conversion = map.first(where: { $0.sourceRange.contains(current) }) {
      current += conversion.offset
    }
  }
  return current
}

func findMinLocation(seeds: [Int], _ maps: [[Conversion]]) -> Int {
  return seeds.map { findLocation(seed: $0, maps) }.min()!
}

func updateRanges(ranges: [Range<Int>], _ map: [Conversion]) -> [Range<Int>] {
  var unprocessedRanges = ranges
  var processedRanges = [Range<Int>]()
  while let range = unprocessedRanges.popLast() {
    if let conversion = map.first(where: { range.overlaps($0.sourceRange) }) {
      // The overlapping part of the two ranges is shifted
      let start = max(range.startIndex, conversion.sourceRange.startIndex)
      let end = min(range.endIndex, conversion.sourceRange.endIndex)
      processedRanges.append(start + conversion.offset..<end + conversion.offset)
      // Parts outside conversion range are not shifted by this conversion, but another one might
      // apply, so consider them as unprocessed.
      if conversion.sourceRange.startIndex > range.startIndex {
        unprocessedRanges.append(range.startIndex..<conversion.sourceRange.startIndex)
      }
      if range.endIndex > conversion.sourceRange.endIndex {
        unprocessedRanges.append(conversion.sourceRange.endIndex..<range.endIndex)
      }
    } else {
      processedRanges.append(range)
    }
  }
  return processedRanges
}

func findMinLocation(seedRanges: [Range<Int>], _ maps: [[Conversion]]) -> Int {
  var ranges = seedRanges
  for map in maps {
    ranges = updateRanges(ranges: ranges, map)
  }
  return ranges.map { $0.startIndex }.min()!
}

let (seeds, maps) = parseSeedsAndMaps()
let seedRanges = stride(from: 0, to: seeds.count, by: 2).map {
  seeds[$0]..<seeds[$0] + seeds[$0 + 1]
}

print("Part 1:", findMinLocation(seeds: seeds, maps))
print("Part 2:", findMinLocation(seedRanges: seedRanges, maps))
