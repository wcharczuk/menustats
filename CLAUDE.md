# Project: menustats

## Quick Reference
* Use the latest frameworks and target the latest operating system version.
* Language: Use the latest version of swift; as much as the codebase as possible should be in Swift
* Package management: Swift Package Manager

## General Style
The code should read as plainly as possible; avoid using esoteric Swift language features where possible. 

## Swift Specific Style
- Use Swift 6 strict concurrency
- Prefer `@Observable` over `ObservableObject`
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)
