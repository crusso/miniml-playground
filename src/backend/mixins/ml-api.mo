import Common    "../types/common";
import ML        "../types/ml";
import Parser    "../lib/parser";
import TypeInfer "../lib/typeinfer";
import Eval      "../lib/eval";

mixin () {
  /// Evaluate ML source: parse (as program) → type-infer → eval
  public func evaluate(src : Text) : async Common.EvalResult {
    // 1. Parse as top-level program (supports multiple let bindings + final expr)
    switch (Parser.parseProgram(src)) {
      case (#err msg) {
        return { ok = false; value = ""; inferredType = ""; error = msg };
      };
      case (#ok expr) {
        // 2. Type inference
        let emptyTypeEnv : ML.TypeEnv = [];
        switch (TypeInfer.infer(emptyTypeEnv, expr)) {
          case (#err msg) {
            return { ok = false; value = ""; inferredType = ""; error = msg };
          };
          case (#ok inferredType) {
            let typeStr = TypeInfer.typeToText(inferredType);
            // 3. Evaluate
            let emptyEnv : ML.Env = [];
            switch (Eval.eval(emptyEnv, expr)) {
              case (#err msg) {
                return { ok = false; value = ""; inferredType = typeStr; error = msg };
              };
              case (#ok value) {
                let valueStr = Eval.valueToText(value);
                return { ok = true; value = valueStr; inferredType = typeStr; error = "" };
              };
            };
          };
        };
      };
    };
  };
};
