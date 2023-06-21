# AddBuilderMacro

Adds a Builder with SwiftUI-like declarative chaining API.
Sets default values for most of the common data types, unless overriden (see `cat` property below).

This:

```swift
@AddBuilder()
struct Person {
  let name: String
  var middleName: String?
  let age: Int
  @AddBuilder(default: Cat(name: "Bob"))
  let cat: Cat
}

struct Cat {
  let name: String
}
```

Expands into:

```swift
struct Person {
  let name: String
  var middleName: String?
  let age: Int
  let cat: Cat
  
  struct Builder {
    var name: String = .init()
    var dateOfBirth: Date = Date(timeIntervalSince1970: 0)
    var height: Float = .init()
    var website: URL = URL(string: "/")!
    var cat: Cat = Cat(name: "Bob")
    
    func name(_ name: String) -> Self {
      var copy = self
      copy.name = name
      return copy
    }
    
    func dateOfBirth(_ dateOfBirth: Date) -> Self {
      var copy = self
      copy.dateOfBirth = dateOfBirth
      return copy
    }
    
    func height(_ height: Float) -> Self {
      var copy = self
      copy.height = height
      return copy
    }
    
    func website(_ website: URL) -> Self {
      var copy = self
      copy.website = website
      return copy
    }
    
    func cat(_ cat: Cat) -> Self {
      var copy = self
      copy.cat = cat
      return copy
    }
    
    init() {
    }
    
    func build() -> Person {
      Person (
        name: name,
        dateOfBirth: dateOfBirth,
        height: height,
        website: website,
        cat: cat
      )
    }
  }
}

struct Cat {
  let name: String
}
```

Usage:

```swift
let person = Person
  .Builder()
  .name("Alex")
  .build()

print(person)
//Person(
//  name: "Alex",
//  dateOfBirth: 1970-01-01 00:00:00 +0000,
//  height: 0.0,
//  website: /,
//  cat: Cat(name: "Bob")
//)
```