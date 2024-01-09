# Implicit Type Conversions 

- Odin is a strongly and distinctly typed language by default. It has very few implicit type conversions compared to many other languages.

```odin
^T -> rawptr
[^]T -> rawptr
[^]T <-> ^T
All types to any (must be specialized/non-polymorphic)
Any of its variants to the union
fN -> complex2N (e.g. f32 -> complex64)
fN -> quaternion4N (e.g. f32 -> quaternion128)
complex2N -> quaternion4N (e.g. complex64 -> quaternion128)
T -> [N]T
T -> matrix[R, C]T
T -> #simd[N]T
distinct proc <-> proc (same base types)
distinct matrix <-> matrix (same base types)
Subtypes through using
Untyped integers -> all numeric related types that can represent them without truncation
Untyped floats -> all numeric related types that can represent them without truncation
Untyped booleans -> all boolean related types
Untyped rune -> all rune types
Untyped strings -> all string types
```
