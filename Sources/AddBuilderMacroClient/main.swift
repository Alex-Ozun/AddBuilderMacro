import AddBuilderMacro
import Foundation

@AddBuilder()
struct Person {
  let id: UUID
  @Builder(default: "Steve")
  let name: String
  let dateOfBirth: Date
  let height: Float
  let website: URL
  let cats: [Cat]
}

@AddBuilder()
struct Cat {
  let name: String
}

let person = Person
  .Builder()
  .name("Alex")
  .build()

print(person)
