# DictionaryCoder

A Swift 4 coder/decoder that maps standard types (dictionary, array) to Codable, and vice-versa

## Usage

Let's assume we have a `Codable` type called `Simple`

Encoding:
```
let o = Simple(...)
let encoded = try DictionaryCoding().encode(o)
switch encoded {
	case .dictionary(let d): // do something with d
	default: // something went wrong, or maybe Simple is an Array?
}
```

Decoding:
```
let d = [...] // dictionary with the RIGHT keys
let o = try DictionaryCoding().decode(Simple.self, from: d)
// o is a Simple, or there was an exception
```

## More info

I took the time to explain the whole process of creating that package [in this blog post](https://blog.krugazor.eu/dictionary-coder-codable/).

## Licence

A long time ago, I went by the licence of people having to offer me a beer if they used the code and met me in real life, but the world is wider now 😉

Instead, this is under [CC BY-SA 1.0](https://creativecommons.org/licenses/by-sa/1.0/)