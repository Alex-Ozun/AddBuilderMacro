import AddBuilderMacro
import Foundation

struct Bla {
  @AddBuilder()
  let name: String
}

@AddBuilder()
struct Person {
  let name: String
  var middleName: String?
  let age: Int
  @AddBuilder(default: Cat(name: "Bob"))
  let cat: Cat
}

//@AddBuilder
struct Cat {
  let name: String
}

let person = Person
  .Builder()
  .name("Alex")
  .build()

print(person)
