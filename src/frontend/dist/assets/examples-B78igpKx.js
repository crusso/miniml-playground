const EXAMPLES = [
  {
    id: "identity",
    title: "Identity Function",
    description: "The simplest polymorphic function — takes any value and returns it unchanged. Works for any type.",
    code: "let id = fun x -> x in id 42",
    expectedType: "'a -> 'a"
  },
  {
    id: "arithmetic",
    title: "Arithmetic Expression",
    description: "Operator precedence in action: multiplication binds tighter than addition, so 4 * 2 evaluates first.",
    code: "let x = 3 + 4 * 2 in x",
    expectedType: "int"
  },
  {
    id: "boolean-logic",
    title: "Boolean Logic",
    description: "Short-circuit boolean operators && and || combined in a single expression.",
    code: "let b = true && false || true in b",
    expectedType: "bool"
  },
  {
    id: "curried-addition",
    title: "Curried Addition",
    description: "A two-argument curried function built from nested lambdas. Applying add 3 returns a new function waiting for the second argument.",
    code: "let add = fun x -> fun y -> x + y in add 3 4",
    expectedType: "int -> int -> int"
  },
  {
    id: "let-binding",
    title: "Chained Let Bindings",
    description: "Nested let-in expressions thread values through a computation. The inner binding can reference the outer one.",
    code: "let x = 10 in let y = x + 5 in x * y",
    expectedType: "int"
  },
  {
    id: "conditional",
    title: "Absolute Value",
    description: "An if-then-else expression selects between two branches. The type inferencer ensures both branches have the same type.",
    code: "let abs = fun n -> if n < 0 then 0 - n else n in abs (0 - 7)",
    expectedType: "int -> int"
  },
  {
    id: "higher-order-apply",
    title: "Higher-Order Apply",
    description: "A higher-order function that takes a function f and an argument x, then applies f to x. Works for any types.",
    code: "let apply = fun f -> fun x -> f x in apply (fun n -> n * n) 5",
    expectedType: "('a -> 'b) -> 'a -> 'b"
  },
  {
    id: "composition",
    title: "Function Composition",
    description: "Implement compose (f ∘ g), then chain double and inc to show the pipeline in action.",
    code: "let compose = fun f -> fun g -> fun x -> f (g x) in let double = fun x -> x * 2 in let inc = fun x -> x + 1 in compose double inc 4",
    expectedType: "int"
  },
  {
    id: "factorial",
    title: "Factorial (Recursive)",
    description: "let rec enables self-referential definitions. This computes 5! = 120 using a standard recursive pattern.",
    code: "let rec fact = fun n -> if n <= 0 then 1 else n * fact (n - 1) in fact 5",
    expectedType: "int -> int"
  },
  {
    id: "fibonacci",
    title: "Fibonacci (Recursive)",
    description: "Doubly-recursive Fibonacci shows how the type inferencer handles multiple recursive calls in a single definition.",
    code: "let rec fib = fun n -> if n <= 1 then n else fib (n - 1) + fib (n - 2) in fib 8",
    expectedType: "int -> int"
  }
];
export {
  EXAMPLES as E
};
