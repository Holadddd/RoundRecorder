//
//  AtomicValue.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/17.
//

import Foundation

class AtomicValue<T> {

    private var _value: T
    private var accessQueue: DispatchQueue!

    init (value: T) {
        _value = value
        let address = Unmanaged.passUnretained(self).toOpaque()
        let label = "accessQueue.\(type(of: self)).\(address)"
        accessQueue = DispatchQueue(label: label)
    }
}

// MARK: Get/Set with synchronization in current queue

extension AtomicValue {
    func waitSet(lockValueAccessWhile closure: ((_ currentValue: T) -> T)?) {
        accessQueue.sync { [weak self] in
            guard let self = self, let value = closure?(self._value) else { return }
            self._value = value
        }
    }

    func waitGet(lockValueAccessWhile closure: ((_ currentValue: T) -> Void)?) {
        accessQueue.sync { [weak self] in
            guard let self = self else { return }
            closure?(self._value)
        }
    }

    func waitUpdate(lockValueAccessWhile closure: ((_ currentValue: inout T) -> Void)?) {
        accessQueue.sync { [weak self] in
            guard let self = self else { return }
            closure?(&self._value)
        }
    }

    func waitMap<V>(lockValueAccessWhile closure: ((_ currentValue: T) -> V)?) -> NotQueueSafeValue<V> {
        var value: V!
        waitGet { value = closure?($0) }
        return NotQueueSafeValue(notQueueSafeValue: value)
    }

    // Be careful with func waitGet() -> NotQueueSafeValue<T>. It is ONLY for WRITE (SAVE).
    // BAD CODE: atomicValue.waitGet().notQueueSafeValue.doSometing().
    //      it is possible that atomicValue._value could be changed while func doSometing() is performing
    // GOOD CODE: atomicValue.waitGet { $0.doSometing() }.
    //      atomicValue._value will never changed while func doSometing() is performing

    struct NotQueueSafeValue<T> { let notQueueSafeValue: T }

    func waitGet() -> NotQueueSafeValue<T> {
        var value: T!
        waitGet { value = $0 }
        return NotQueueSafeValue(notQueueSafeValue: value)
    }

    func waitSet(value: T) { waitSet { _ in return value } }
}

// MARK: Get/Set in current queue

extension AtomicValue {
    func set(waitAccessIn queue: DispatchQueue, closure: ((_ currentValue: T) -> T)?) {
        queue.async { [weak self] in self?.waitSet(lockValueAccessWhile: closure) }
    }

    func get(waitAccessIn queue: DispatchQueue, closure: ((_ currentValue: T) -> Void)?) {
        queue.async { [weak self] in self?.waitGet(lockValueAccessWhile: closure) }
    }

    func update(waitAccessIn queue: DispatchQueue, closure: ((_ currentValue: inout T) -> Void)?) {
        queue.async { [weak self] in self?.waitUpdate(lockValueAccessWhile: closure) }
    }
}
