//
//  MockImpl.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 04/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import Dispatch
import XCTest



private let semaphore = DispatchQueue(label: "Mock Sync Queue")
private var allStubs = [String: [String: [StubImplementation]]]()
private var allInvocations = [String: [AnyInvocation]]()
private var allExpectations = [String: [AnyInvocation]]()

private func stubIdentifier<T: RawRepresentable>(_ method: T) -> String
{
    return "method-\(method.rawValue)"
}

private enum StubArgument
{
    case any
    case specific([AnyEquatable?])
}


private struct StubImplementation
{
    let args: StubArgument
    let block: Any
    init(args: StubArgument, block: Any)
    {
        self.args = args
        self.block = block
    }
    
}

private struct AnyInvocation
{
    private let _invocation: Any
    
    init<T: Mock>(_ invocation: MockInvocation<T>)
    {
        self._invocation = invocation
    }
    
    func invocation<T: Mock>() -> MockInvocation<T>
    {
        if let invocation = _invocation as? MockInvocation<T> {
            return invocation
        }
        fatalError("Mismatched type: Got \(type(of: _invocation)). Expected \(MockInvocation<T>.self)")
    }
}

extension Mock where Self: AnyObject
{
    public var identifier: String {
        get {
            let ptr = Unmanaged.passUnretained(self).toOpaque()
            let address = Int(bitPattern: ptr)
            return "\(type(of: self))-\(address)"
        }
    }
}

extension Mock
{
    var invocations: [MockInvocation<Self>] {
        get { return semaphore.sync { (allInvocations[identifier] ?? []).map { $0.invocation() } } }
    }
    
    var expectations: [MockInvocation<Self>] {
        get { return semaphore.sync { (allExpectations[identifier] ?? []).map { $0.invocation() } } }
    }
    
    func resetMock()
    {
        semaphore.sync {
            allStubs[identifier] = nil
            allInvocations[identifier] = nil
            allExpectations[identifier] = nil
        }
    }
    
    func unstub(_ method: MockMethod)
    {
        let key = stubIdentifier(method)
        semaphore.sync {
            allStubs[identifier]?[key] = nil
        }
    }
    
    func stub<T>(_ method: MockMethod, andReturn value: T?)
    {
        stub(method, withBlock: { _ in value })
    }
    
    func stub<T>(_ method: MockMethod, andReturn value: T)
    {
        stub(method, withBlock: { _ in value })
    }
    
    func stub<T>(_ method: MockMethod, andReturn first: T?, times: Int, thenReturn second: T?)
    {
        var count = 0
        stub(method, withBlock: { _ -> T? in
            defer { count += 1 }
            return count < times ? first : second
        })
    }
    
    func stub<T>(_ method: MockMethod, andReturn first: T, times: Int, thenReturn second: T)
    {
        var count = 0
        stub(method, withBlock: { _ -> T in
            defer { count += 1 }
            return count < times ? first : second
        })
    }
    
    func stub<T>(_ method: MockMethod, withBlock block: @escaping (Any?...) -> T?)
    {
        let methodId = stubIdentifier(method)
        semaphore.sync {
            var stubs = allStubs[identifier] ?? [:]
            stubs[methodId] = stubs[methodId] ?? [] + [StubImplementation(args: .any, block: block)]
            allStubs[identifier] = stubs
        }
    }
    
    func stub<T>(_ method: MockMethod, withBlock block: @escaping (Any?...) -> T)
    {
        let methodId = stubIdentifier(method)
        semaphore.sync {
            var stubs = allStubs[identifier] ?? [:]
            stubs[methodId] = stubs[methodId] ?? [] + [StubImplementation(args: .any, block: block)]
            allStubs[identifier] = stubs
        }
    }
    
    func stub<T>(_ method: MockMethod, andIterateThroughReturnValues values: [T])
    {
        var count = 0
        stub(method, withBlock: { _ -> T in
            defer { count = (count + 1) % values.count }
            return values[count]
        })
    }
    
    func stub<T>(_ method: MockMethod, andIterateThroughReturnValues values: [T?])
    {
        var count = 0
        stub(method, withBlock: { _ -> T? in
            defer { count = (count + 1) % values.count }
            return values[count]
        })
    }
    
    func stub<T>(_ method: MockMethod, andReturn value: T, expectingArguments args: AnyEquatable?...)
    {
        let methodId = stubIdentifier(method)
        let stub = StubImplementation(args: .specific(args), block: { (_: Any?...) -> T in value })
        semaphore.sync {
            var stubs = allStubs[identifier] ?? [:]
            stubs[methodId] = stubs[methodId] ?? [] + [stub]
            allStubs[identifier] = stubs
        }
    }
    
    func stub<T>(_ method: MockMethod, andReturn value: T?, expectingArguments args: AnyEquatable?...)
    {
        let methodId = stubIdentifier(method)
        let stub = StubImplementation(args: .specific(args), block: { (_: Any?...) -> T? in value })
        semaphore.sync {
            var stubs = allStubs[identifier] ?? [:]
            stubs[methodId] = (stubs[methodId] ?? []) + [stub]
            allStubs[identifier] = stubs
        }
    }
    
    func registerInvocation(_ method: MockMethod, args: Any?...)
    {
        logInvocation(method, args: args)
    }
    
    func registerInvocation<T>(_ method: MockMethod, args: Any?..., returning value: T) -> T
    {
        return registerInvocation(method, args: args, returning: { _ in value })
    }
    
    func registerInvocation<T>(_ method: MockMethod, args: Any?..., returning value: T?) -> T?
    {
        return registerInvocation(method, args: args, returning: { _ in value })
    }
    
    func registerInvocation<T>(_ method: MockMethod, args: Any?..., returning block: @escaping (Any?...) -> T?) -> T?
    {
        return registerInvocation(method, args: args, returning: block)
    }
    
    func registerInvocation<T>(_ method: MockMethod, args: Any?..., returning block: @escaping (Any?...) -> T) -> T
    {
        return registerInvocation(method, args: args, returning: block)
    }
    
    func expect(_ method: MockMethod, withArgs args: AnyEquatable?...)
    {
        let expecation = [AnyInvocation(MockInvocation<Self>(
            methodId: method, arguments: args))]
        semaphore.sync {
            let expecations = allExpectations[identifier] ?? []
            allExpectations[identifier] = expecations + expecation
        }
    }
    
    func verify(_ line: UInt = #line, _ file: StaticString = #file)
    {
        let es = expectations
        var invs = invocations
        for expecation in es {
            if let idx = invs.index(where: { $0.methodId == expecation.methodId } ) {
                let invocation = invs[idx]
                invs.remove(at: idx)
                guard invocation.arguments.count == expecation.arguments.count else {
                    XCTFail("Invocation of \(expecation.methodId) has differing arguments. " +
                        "Expected: \(expecation.arguments). Received \(invocation.arguments)")
                    continue
                }
                for (i, e) in zip(invocation.arguments, expecation.arguments) {
                    let invocationArg = AnyEquatable(base: i)
                    let equatableArg = e as! AnyEquatable
                    XCTAssertEqual(equatableArg, invocationArg,
"Argument for invocation \(String(describing: invocationArg.base)) does not match expectation " +
"\(String(describing: equatableArg.base))", file: file, line: line)
                }
            }
            else {
                XCTFail("Invocation of \(expecation.methodId) not received")
            }
        }
    }
    
    private func registerInvocation<T>(_ method: MockMethod, args: [Any?],
        returning block: @escaping (Any?...) -> T) -> T
    {
        logInvocation(method, args: args)
        if let stub = findStub(for: method, args: args) {
            guard let typedStub = stub.block as? ([Any?]) -> T else {
                fatalError("Mismatched invocation type: Got \(type(of: stub.block)). Expected \((([Any?]) -> T).self)")
            }
            return typedStub(args)
        }
        return block(args)
    }
    
    private func registerInvocation<T>(_ method: MockMethod, args: [Any?],
        returning block: @escaping (Any?...) -> T?) -> T?
    {
        logInvocation(method, args: args)
        if let stub = findStub(for: method, args: args) {
            guard let typedStub = stub.block as? ([Any?]) -> T? else {
                fatalError("Mismatched invocation type: Got \(type(of: stub.block)). Expected \((([Any?]) -> T?).self)")
            }
            return typedStub(args)
        }
        return block(args)
    }
    
    private func findStub(for method: MockMethod, args: [Any?]) -> StubImplementation?
    {
        let stubsForObject = semaphore.sync { allStubs[identifier]?[stubIdentifier(method)] }
        for stub in stubsForObject ?? [] {
            switch stub.args {
            case .specific(let stubArgs):
                guard stubArgs.count == args.count else { continue }
                var allArgsEqual = true
                for (invArg, stubArg) in zip(args, stubArgs) {
                    let equatableInvArg = AnyEquatable(base: invArg)
                    if stubArg != equatableInvArg {
                        allArgsEqual = false
                        break
                    }
                }
                if allArgsEqual { return stub }
                break
            case .any:
                break
            }
        }
        return (stubsForObject ?? []).first(where: {
            switch $0.args {
            case .any:          return true
            case .specific(_):  return false
            }
        })
    }
    
    private func logInvocation(_ method: MockMethod, args: [Any?])
    {
        let invocation = [AnyInvocation(MockInvocation<Self>(methodId: method, arguments: args))]
        
        semaphore.sync {
            if let previousInvocations = allInvocations[identifier] {
                allInvocations[identifier] = previousInvocations + invocation
            }
            else {
                allInvocations[identifier] = invocation
            }
        }
    }
}

