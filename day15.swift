import Foundation

let defaultFilename = "input15.txt"

func loadInput() -> String {
  let filename = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultFilename
  do {
    return try String(contentsOfFile: filename)
  } catch {
    print("Could not load input from '\(filename)'.")
    exit(1)
  }
}

func hash<T>(_ data: T) -> Int where T: StringProtocol {
  var currentValue = 0
  for char in data {
    currentValue += Int(char.asciiValue!)
    currentValue *= 17
    currentValue %= 256
  }
  return currentValue
}

class Boxes {
  var contents: [[(String, Int)]]

  init() {
    contents = Array(repeating: [(String, Int)](), count: 256)
  }

  func process(instructions: [Substring.SubSequence]) {
    for instruction in instructions {
      if instruction.last! == "-" {
        removeLens(label: instruction.dropLast())
      } else {
        let tokens = instruction.split(separator: "=")
        addOrReplaceLens(label: tokens[0], focalLength: Int(tokens[1])!)
      }
      //print(boxes.filter { !$0.isEmpty })
    }
  }

  func score() -> Int {
    return contents.enumerated().map { boxIndex, content in
      (boxIndex + 1)
        * content.enumerated().map { slot, lensInfo in
          (slot + 1) * lensInfo.1
        }.reduce(0, +)
    }.reduce(0, +)
  }

  private func removeLens(label: String.SubSequence) {
    let boxIndex = hash(label)
    if let lensPos = (contents[boxIndex].firstIndex { $0.0 == label }) {
      contents[boxIndex].remove(at: lensPos)
    }
  }

  private func addOrReplaceLens(label: String.SubSequence, focalLength: Int) {
    let boxIndex = hash(label)
    let lensInfo = (String(label), focalLength)
    if let lensPos = (contents[boxIndex].firstIndex { $0.0 == label }) {
      contents[boxIndex][lensPos] = lensInfo
    } else {
      contents[boxIndex].append(lensInfo)
    }
  }
}

let instructions = loadInput().split(separator: "\n").first!.split(separator: ",")
print("Part 1:", instructions.map { hash($0) }.reduce(0, +))

let boxes = Boxes()
boxes.process(instructions: instructions)
print("Part 2:", boxes.score())
