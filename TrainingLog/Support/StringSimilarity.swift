//
//  StringSimilarity.swift
//  TrainingLog
//

import Foundation

extension String {

    /// Classic Levenshtein edit distance: the minimum number of
    /// single-character insertions, deletions, or substitutions needed
    /// to turn one string into the other. Case-insensitive. Used to
    /// nudge the user ("Did you mean X?") before they create a custom
    /// exercise that's really just a typo or pluralization of one that
    /// already exists — e.g. "Bicep Curl" vs. "Bicep Curls" is a
    /// distance of 1, not a different exercise.
    func levenshteinDistance(to other: String) -> Int {
        let a = Array(lowercased())
        let b = Array(other.lowercased())

        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var previousRow = Array(0...b.count)
        var currentRow = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            currentRow[0] = i
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    currentRow[j] = previousRow[j - 1]
                } else {
                    currentRow[j] = 1 + Swift.min(
                        previousRow[j - 1],
                        previousRow[j],
                        currentRow[j - 1]
                    )
                }
            }
            previousRow = currentRow
        }

        return previousRow[b.count]
    }
}
