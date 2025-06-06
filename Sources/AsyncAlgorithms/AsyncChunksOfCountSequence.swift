//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Async Algorithms open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@available(AsyncAlgorithms 1.0, *)
extension AsyncSequence {
  /// Creates an asynchronous sequence that creates chunks of a given `RangeReplaceableCollection` of a given count.
  @available(AsyncAlgorithms 1.0, *)
  
  public func chunks<Collected: RangeReplaceableCollection>(
    ofCount count: Int,
    into: Collected.Type
  ) -> AsyncChunksOfCountSequence<Self, Collected> where Collected.Element == Element {
    AsyncChunksOfCountSequence(self, count: count)
  }

  /// Creates an asynchronous sequence that creates chunks of a given count.
  @available(AsyncAlgorithms 1.0, *)
  
  public func chunks(ofCount count: Int) -> AsyncChunksOfCountSequence<Self, [Element]> {
    chunks(ofCount: count, into: [Element].self)
  }
}

/// An `AsyncSequence` that chunks elements into `RangeReplaceableCollection` instances of at least a given count.
@available(AsyncAlgorithms 1.0, *)
public struct AsyncChunksOfCountSequence<Base: AsyncSequence, Collected: RangeReplaceableCollection>: AsyncSequence
where Collected.Element == Base.Element {
  public typealias Element = Collected

  /// The iterator for a `AsyncChunksOfCountSequence` instance.
  @frozen
  public struct Iterator: AsyncIteratorProtocol {

    
    var base: Base.AsyncIterator

    
    let count: Int

    
    init(base: Base.AsyncIterator, count: Int) {
      self.base = base
      self.count = count
    }

    
    public mutating func next() async rethrows -> Collected? {
      guard let first = try await base.next() else {
        return nil
      }

      if count == 1 {
        return Collected(CollectionOfOne(first))
      }

      var result: Collected = .init()
      result.append(first)

      while let next = try await base.next() {
        result.append(next)
        if result.count == count {
          break
        }
      }
      return result
    }
  }

  
  let base: Base

  
  let count: Int

  
  init(_ base: Base, count: Int) {
    precondition(count > 0)
    self.base = base
    self.count = count
  }

  
  public func makeAsyncIterator() -> Iterator {
    Iterator(base: base.makeAsyncIterator(), count: count)
  }
}

@available(AsyncAlgorithms 1.0, *)
extension AsyncChunksOfCountSequence: Sendable where Base: Sendable, Base.Element: Sendable {}
@available(AsyncAlgorithms 1.0, *)
extension AsyncChunksOfCountSequence.Iterator: Sendable where Base.AsyncIterator: Sendable, Base.Element: Sendable {}
