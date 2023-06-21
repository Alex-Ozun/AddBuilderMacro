import AddBuilderMacro
import Foundation

struct Bla {
  @AddBuilder()
  let name: String
}

@AddBuilder()
struct Person {
  let name: String
  let dateOfBirth: Date
  let height: Float
  let website: URL
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
print(person.website)
//Person(
//  name: "Alex",
//  dateOfBirth: 1970-01-01 00:00:00 +0000,
//  height: 0.0,
//  website: /,
//  cat: Cat(name: "Bob")
//)
