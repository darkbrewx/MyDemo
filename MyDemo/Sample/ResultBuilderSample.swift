//
//  ResultBuilderSample.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/10/13.
//

import Foundation
import SwiftUI

struct resultTestView: View {
    @NumbersBuilder
    var numbersMadeViaBuilder: [Int] {
        1
        2
        3
        if false {
            "4"
        }

        for i in 5...7 {
            i
        }
    }
    var body: some View {
        Text("\(numbersMadeViaBuilder)")
    }
}

#Preview {
    resultTestView()
}

@resultBuilder
public struct NumbersBuilder {

    // MARK: - Required

    // MARK: combine multiple values
    public static func buildBlock(_ components: Int...) -> [Int] {
        print("components: \(components)")
        return components
    }

    // MARK: combine multiple values incrementally (Higher priority than buildBlock)
    // Handles the first element - converts single value to accumulator type
    public static func buildPartialBlock(first: Int) -> [Int] {
        print("Partial: \(first)")
        return [first]
    }

    // Handles subsequent elements - merges each new value into accumulated result
    // Called N-1 times for N elements
    public static func buildPartialBlock(accumulated: [Int], next: Int) -> [Int] {
        print("Partial accumulated: \(accumulated), next: \(next)")
        return accumulated + [next]
    }

    // MARK: - Optional

    // MARK: expression: convert types
    public static func buildExpression(_ expression: Int) -> Int {
        print("expression: \(expression)")
        return expression
    }

    public static func buildExpression(_ expression: String) -> Int {
        Int(expression) ?? 5
    }

    // MARK: handle if statement
    // if without else
    public static func buildOptional(_ component: [Int]?) -> Int {
        print("buildOptional: \(component)")
        return component?.first ?? 0
    }

    // if with else(true path)
    public static func buildEither(first component: [Int]) -> Int {
        print("Either first: \(component)")
        return component.first ?? 0
    }

    // if with else(false path)
    public static func buildEither(second component: [Int]) -> Int {
        print("Either second: \(component)")
        return component.first ?? 0
    }

    // #if(build target condition)
    public static func buildLimitedAvailability(_ component: [Int]) -> [Int] {
        component
    }

    // MARK: handle for-in loop
    public static func buildArray(_ components: [[Int]]) -> Int {
        print("array: \(components)")
        return components.flatMap { $0 } .reduce(0) { $0 + $1 } // for-inの中身全部足した合計を返す
    }

    // MARK: final result
    public static func buildFinalResult(_ component: [Int]) -> [Int] {
        var new = component
        new.append(100)
        print("final: \(new)")
        return new
    }
}


