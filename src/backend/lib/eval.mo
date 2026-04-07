// Big-step evaluator for mini-ML.
// Supports fix-point combinator for let rec.

import Types "../types/ml";

module {
  public type EvalResult = { #ok : Types.Value; #err : Text };

  // ─── Environment lookup ────────────────────────────────────────────────────
  func envLookup(env : Types.Env, name : Text) : ?Types.Value {
    var i = env.size();
    while (i > 0) {
      i -= 1;
      let (n, v) = env[i];
      if (n == name) return ?v;
    };
    null
  };

  /// Render a Value as a human-readable string
  public func valueToText(v : Types.Value) : Text {
    switch v {
      case (#int n)      n.toText();
      case (#bool b)     if b "true" else "false";
      case (#closure _)  "<fun>";
      case (#builtin n)  "<builtin:" # n # ">";
    }
  };

  // ─── Core evaluator ───────────────────────────────────────────────────────
  func evalExpr(env : Types.Env, expr : Types.Expr) : EvalResult {
    switch expr {
      case (#intLit n)  #ok (#int n);
      case (#boolLit b) #ok (#bool b);

      case (#var_ x) {
        switch (envLookup(env, x)) {
          case (?v)  #ok v;
          case null  #err ("Runtime error: unbound variable '" # x # "'");
        }
      };

      case (#lam { param; body; paramType = _ }) {
        #ok (#closure { param; body; env })
      };

      case (#fix inner) {
        // fix f  where f is a lambda (fun self -> fun x -> body)
        // Evaluated by creating a self-referential closure via a lazy knot.
        // We evaluate the inner expression (should be a closure expecting itself as argument).
        // We apply the fix: fix f = f (fix f), computed iteratively via a closure trick.
        switch (evalExpr(env, inner)) {
          case (#err e) #err e;
          case (#ok fv) {
            switch fv {
              case (#closure { param = _selfName; body = _selfBody; env = _cenv }) {
                // Build a recursive value: a closure that, when called,
                // will call itself by looking up selfName in an env that includes itself.
                // We achieve this by creating a #fix closure sentinel.
                // The trick: build a closure whose env contains a reference to itself.
                // Since we can't mutate env, we use a two-step approach:
                // The fix value is represented as a special closure that re-invokes fix on each call.
                // fix (fun f -> body)  means f = fun x -> (fun f -> body) f x
                // We desugar: fix lam evaluates lam applied to (fix lam).
                // This is safe for terminating programs. For infinite recursion, IC will time out.
                let fixExpr : Types.Expr = #app { func_ = inner; arg = #fix inner };
                evalExpr(env, fixExpr)
              };
              case _ #err "Runtime error: fix applied to non-function value";
            };
          };
        }
      };

      case (#app { func_; arg }) {
        switch (evalExpr(env, func_)) {
          case (#err e) #err e;
          case (#ok fv) {
            switch (evalExpr(env, arg)) {
              case (#err e) #err e;
              case (#ok av) {
                switch fv {
                  case (#closure { param; body; env = cenv }) {
                    evalExpr(cenv.concat([(param, av)]), body)
                  };
                  case _ #err "Runtime error: applied a non-function value";
                };
              };
            };
          };
        }
      };

      case (#let_ { name; value; body }) {
        switch (evalExpr(env, value)) {
          case (#err e) #err e;
          case (#ok v) {
            evalExpr(env.concat([(name, v)]), body)
          };
        }
      };

      case (#if_ { cond; then_; else_ }) {
        switch (evalExpr(env, cond)) {
          case (#err e) #err e;
          case (#ok cv) {
            switch cv {
              case (#bool b) if b evalExpr(env, then_) else evalExpr(env, else_);
              case _ #err "Runtime error: if-condition is not a boolean";
            }
          };
        }
      };

      case (#binop { op; left; right }) {
        switch (evalExpr(env, left)) {
          case (#err e) #err e;
          case (#ok lv) {
            // short-circuit &&
            switch op {
              case (#and_) {
                switch lv {
                  case (#bool false) return #ok (#bool false);
                  case (#bool true)  {};
                  case _ return #err "Runtime error: && requires boolean left operand";
                };
              };
              case (#or_) {
                switch lv {
                  case (#bool true)  return #ok (#bool true);
                  case (#bool false) {};
                  case _ return #err "Runtime error: || requires boolean left operand";
                };
              };
              case _ {};
            };

            switch (evalExpr(env, right)) {
              case (#err e) #err e;
              case (#ok rv) evalBinop(op, lv, rv);
            };
          };
        }
      };
    }
  };

  func evalBinop(op : Types.BinOp, lv : Types.Value, rv : Types.Value) : EvalResult {
    switch (op, lv, rv) {
      case (#add, #int a, #int b) #ok (#int (a + b));
      case (#sub, #int a, #int b) #ok (#int (a - b));
      case (#mul, #int a, #int b) #ok (#int (a * b));
      case (#div, #int a, #int b) {
        if (b == 0) #err "Runtime error: division by zero"
        else        #ok (#int (a / b))
      };
      case (#eq,  #int a,  #int b)  #ok (#bool (a == b));
      case (#eq,  #bool a, #bool b) #ok (#bool (a == b));
      case (#neq, #int a,  #int b)  #ok (#bool (a != b));
      case (#neq, #bool a, #bool b) #ok (#bool (a != b));
      case (#lt,  #int a, #int b)   #ok (#bool (a < b));
      case (#le,  #int a, #int b)   #ok (#bool (a <= b));
      case (#gt,  #int a, #int b)   #ok (#bool (a > b));
      case (#ge,  #int a, #int b)   #ok (#bool (a >= b));
      case (#and_, #bool a, #bool b) #ok (#bool (a and b));
      case (#or_,  #bool a, #bool b) #ok (#bool (a or b));
      case _ #err "Runtime error: type mismatch in binary operator";
    }
  };

  /// Evaluate an expression under a runtime environment
  public func eval(env : Types.Env, expr : Types.Expr) : EvalResult {
    evalExpr(env, expr)
  };
};
