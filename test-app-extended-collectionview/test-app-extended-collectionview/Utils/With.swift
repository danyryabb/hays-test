func with<T: AnyObject>(_ object: T, update: (T) throws -> Void) rethrows -> T {
    try update(object)
    return object
}
