//
//  Mock.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 28/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

public protocol Mock
{
    associatedtype MockMethod: RawRepresentable, Equatable
    var identifier: String { get }
    
    func stub<T>(_: MockMethod, andReturn: T?)
    func stub<T>(_: MockMethod, withBlock: @escaping (Any?...) -> T?)
    func stub<T>(_: MockMethod, andReturn: T)
    func stub<T>(_: MockMethod, withBlock: @escaping (Any?...) -> T)
    func stub<T>(_: MockMethod, andReturn: T?, times: Int, thenReturn: T?)
    func stub<T>(_: MockMethod, andReturn: T, times: Int, thenReturn: T)
    func stub<T>(_: MockMethod, andIterateThroughReturnValues: [T])
    func stub<T>(_: MockMethod, andIterateThroughReturnValues: [T?])
    func stub<T>(_: MockMethod, andReturn: T, expectingArguments: AnyEquatable?...)
    func stub<T>(_: MockMethod, andReturn: T?, expectingArguments: AnyEquatable?...)
    func unstub(_: MockMethod)
    
    func registerInvocation(_: MockMethod, args: Any?...)
    func registerInvocation<T>(_: MockMethod, args: Any?..., returning: T?) -> T?
    func registerInvocation<T>(_: MockMethod, args: Any?..., returning: T) -> T
    func registerInvocation<T>(_: MockMethod, args: Any?..., returning: @escaping (Any?...) -> T?) -> T?
    func registerInvocation<T>(_: MockMethod, args: Any?..., returning: @escaping (Any?...) -> T) -> T
    
    func resetMock()
    
    func expect(_: MockMethod, withArgs: AnyEquatable?...)
    func verify(_ line: UInt, _ file: StaticString)
}

public struct AnyEquatable: Equatable
{
    public let base: Any?
    private let equatableImp: (Any?) -> Bool
    
    public init<T: Equatable>(base: [T])
    {
        self.base = base
        self.equatableImp = { rhs in
            if let rhs = rhs as? [T] { return base == rhs }
            return false
        }
    }
    
    public init<T: Equatable>(base: [T?])
    {
        self.base = base
        self.equatableImp = { rhs in
            if let rhs = rhs as? [T?] { return base.elementsEqual(rhs, by: ==) }
            return false
        }
    }
    
    public init<T: Equatable>(base: T?)
    {
        self.base = base
        self.equatableImp = { rhs in
            if let rhs = rhs as? T? { return base == rhs }
            return false
        }
    }
    
    public init(base: Any?, equatableImpl: @escaping (Any?) -> Bool = { _ in false })
    {
        self.base = base
        self.equatableImp = equatableImpl
    }
    
    public static func ==(lhs: AnyEquatable, rhs: AnyEquatable) -> Bool
    {
        return lhs.equatableImp(rhs.base) || rhs.equatableImp(lhs.base)
    }
}

public class IdentifierGenerator
{
    private static var counter = 0
    static func next<T>(for type: T.Type) -> String
    {
        defer { counter += 1 }
        return "\(type)-\(counter)"
    }
}

public struct MockInvocation<T: Mock>
{
    public let methodId: T.MockMethod
    
    public let arguments: [Any?]
}
