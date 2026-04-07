// Hindley-Milner style type inference with union-find unification.

import Types "../types/ml";
import Array "mo:core/Array";

module {
  public type InferResult = { #ok : Types.Type; #err : Text };

  // ─── Union-Find substitution ────────────────────────────────────────────────
  class Subst() {
    var table : [var ?Types.Type] = [var];
    var nextId : Nat = 0;

    public func fresh() : Nat {
      let id = nextId;
      nextId += 1;
      let newSize = nextId;
      let newTable = Array.tabulate(newSize, func(i : Nat) : ?Types.Type {
        if (i < table.size()) table[i] else null
      }).toVarArray<(?Types.Type)>();
      table := newTable;
      id
    };

    public func bind(id : Nat, t : Types.Type) {
      table[id] := ?t;
    };

    public func find(id : Nat) : Types.Type {
      switch (table[id]) {
        case null           #typeVar id;
        case (?#typeVar id2) {
          let resolved = find(id2);
          table[id] := ?resolved;
          resolved
        };
        case (?t) t;
      }
    };

    public func apply(t : Types.Type) : Types.Type {
      switch t {
        case (#typeVar id) find(id);
        case (#fun { param; ret }) #fun { param = apply(param); ret = apply(ret) };
        case _ t;
      }
    };
  };

  // ─── Occurs check ─────────────────────────────────────────────────────────
  func occurs(subst : Subst, id : Nat, t : Types.Type) : Bool {
    switch (subst.apply(t)) {
      case (#typeVar vid)           vid == id;
      case (#fun { param; ret })    occurs(subst, id, param) or occurs(subst, id, ret);
      case _                        false;
    }
  };

  // ─── Unification ──────────────────────────────────────────────────────────
  func unify(subst : Subst, a : Types.Type, b : Types.Type) : ?Text {
    let ta = subst.apply(a);
    let tb = subst.apply(b);
    switch (ta, tb) {
      case (#int,  #int)  null;
      case (#bool, #bool) null;
      case (#typeVar id, t) {
        switch t {
          case (#typeVar id2) {
            if (id == id2) null else { subst.bind(id, t); null }
          };
          case _ {
            if (occurs(subst, id, t))
              ?("Occurs check failed: type variable a" # id.toText())
            else { subst.bind(id, t); null }
          };
        }
      };
      case (t, #typeVar id) {
        if (occurs(subst, id, t))
          ?("Occurs check failed")
        else { subst.bind(id, t); null }
      };
      case (#fun { param = p1; ret = r1 }, #fun { param = p2; ret = r2 }) {
        switch (unify(subst, p1, p2)) {
          case (?err) ?err;
          case null   unify(subst, r1, r2);
        }
      };
      case _ {
        ?("Cannot unify " # typeToText_(subst, ta) # " with " # typeToText_(subst, tb))
      };
    }
  };

  // ─── Type-to-text (internal, resolves via subst) ─────────────────────────
  func typeToText_(subst : Subst, t : Types.Type) : Text {
    switch (subst.apply(t)) {
      case (#int)                  "int";
      case (#bool)                 "bool";
      case (#typeVar id)           "a" # id.toText();
      case (#fun { param; ret }) {
        let ps = switch (subst.apply(param)) {
          case (#fun _) "(" # typeToText_(subst, param) # ")";
          case _        typeToText_(subst, param);
        };
        ps # " -> " # typeToText_(subst, ret)
      };
    }
  };

  /// Render a Type as a human-readable string (no subst needed post-inference)
  public func typeToText(t : Types.Type) : Text {
    switch t {
      case (#int)                  "int";
      case (#bool)                 "bool";
      case (#typeVar id)           "a" # id.toText();
      case (#fun { param; ret }) {
        let ps = switch param {
          case (#fun _) "(" # typeToText(param) # ")";
          case _        typeToText(param);
        };
        ps # " -> " # typeToText(ret)
      };
    }
  };

  // ─── Environment lookup ───────────────────────────────────────────────────
  func envLookup(env : Types.TypeEnv, name : Text) : ?Types.Type {
    var i = env.size();
    while (i > 0) {
      i -= 1;
      let (n, t) = env[i];
      if (n == name) return ?t;
    };
    null
  };

  // ─── Core inference ───────────────────────────────────────────────────────
  func inferExpr(subst : Subst, env : Types.TypeEnv, expr : Types.Expr) : InferResult {
    switch expr {
      case (#intLit _)  #ok (#int);
      case (#boolLit _) #ok (#bool);

      case (#var_ x) {
        switch (envLookup(env, x)) {
          case (?t)  #ok t;
          case null  #err ("Type error: unbound variable '" # x # "'");
        }
      };

      case (#lam { param; body; paramType = _ }) {
        let pv : Types.Type = #typeVar (subst.fresh());
        let ext : Types.TypeEnv = env.concat([(param, pv)]);
        switch (inferExpr(subst, ext, body)) {
          case (#err e)  #err e;
          case (#ok ret) #ok (#fun { param = pv; ret });
        }
      };

      case (#fix inner) {
        // fix : (a -> a) -> a
        // fresh type variable for the fixed-point type
        let tv : Types.Type = #typeVar (subst.fresh());
        switch (inferExpr(subst, env, inner)) {
          case (#err e) #err e;
          case (#ok ft) {
            // ft must unify with (tv -> tv)
            switch (unify(subst, ft, #fun { param = tv; ret = tv })) {
              case (?err) #err ("Type error: fix requires a function type — " # err);
              case null   #ok (subst.apply(tv));
            };
          };
        }
      };

      case (#app { func_; arg }) {
        switch (inferExpr(subst, env, func_)) {
          case (#err e) #err e;
          case (#ok ft) {
            switch (inferExpr(subst, env, arg)) {
              case (#err e) #err e;
              case (#ok at) {
                let rv : Types.Type = #typeVar (subst.fresh());
                switch (unify(subst, ft, #fun { param = at; ret = rv })) {
                  case (?err) #err ("Type error: " # err);
                  case null   #ok (subst.apply(rv));
                };
              };
            };
          };
        }
      };

      case (#let_ { name; value; body }) {
        switch (inferExpr(subst, env, value)) {
          case (#err e)   #err e;
          case (#ok vt) {
            let ext : Types.TypeEnv = env.concat([(name, subst.apply(vt))]);
            inferExpr(subst, ext, body)
          };
        }
      };

      case (#if_ { cond; then_; else_ }) {
        switch (inferExpr(subst, env, cond)) {
          case (#err e) #err e;
          case (#ok ct) {
            switch (unify(subst, ct, #bool)) {
              case (?err) #err ("Type error: if-condition must be bool — " # err);
              case null {
                switch (inferExpr(subst, env, then_)) {
                  case (#err e) #err e;
                  case (#ok tt) {
                    switch (inferExpr(subst, env, else_)) {
                      case (#err e) #err e;
                      case (#ok et) {
                        switch (unify(subst, tt, et)) {
                          case (?err) #err ("Type error: then/else branches must match — " # err);
                          case null   #ok (subst.apply(tt));
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        }
      };

      case (#binop { op; left; right }) {
        switch (inferExpr(subst, env, left)) {
          case (#err e) #err e;
          case (#ok lt) {
            switch (inferExpr(subst, env, right)) {
              case (#err e) #err e;
              case (#ok rt) {
                switch op {
                  case (#add or #sub or #mul or #div) {
                    switch (unify(subst, lt, #int)) {
                      case (?e) #err ("Type error: arithmetic requires int — " # e);
                      case null {
                        switch (unify(subst, rt, #int)) {
                          case (?e) #err ("Type error: arithmetic requires int — " # e);
                          case null #ok (#int);
                        };
                      };
                    };
                  };
                  case (#eq or #neq) {
                    switch (unify(subst, lt, rt)) {
                      case (?e) #err ("Type error: equality requires same types — " # e);
                      case null #ok (#bool);
                    };
                  };
                  case (#lt or #le or #gt or #ge) {
                    switch (unify(subst, lt, #int)) {
                      case (?e) #err ("Type error: comparison requires int — " # e);
                      case null {
                        switch (unify(subst, rt, #int)) {
                          case (?e) #err ("Type error: comparison requires int — " # e);
                          case null #ok (#bool);
                        };
                      };
                    };
                  };
                  case (#and_ or #or_) {
                    switch (unify(subst, lt, #bool)) {
                      case (?e) #err ("Type error: logical operator requires bool — " # e);
                      case null {
                        switch (unify(subst, rt, #bool)) {
                          case (?e) #err ("Type error: logical operator requires bool — " # e);
                          case null #ok (#bool);
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        }
      };
    }
  };

  /// Infer the type of an expression under a type environment
  public func infer(env : Types.TypeEnv, expr : Types.Expr) : InferResult {
    let subst = Subst();
    switch (inferExpr(subst, env, expr)) {
      case (#err e) #err e;
      case (#ok t)  #ok (subst.apply(t));
    }
  };
};
