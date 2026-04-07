module {
  /// Source position for error reporting
  public type Pos = { line : Nat; col : Nat };

  /// AST expression nodes
  public type Expr = {
    #intLit : Int;
    #boolLit : Bool;
    #var_ : Text;
    #lam : { param : Text; paramType : ?Type; body : Expr };
    #app : { func_ : Expr; arg : Expr };
    #let_ : { name : Text; value : Expr; body : Expr };
    #if_ : { cond : Expr; then_ : Expr; else_ : Expr };
    #binop : { op : BinOp; left : Expr; right : Expr };
    #fix : Expr;  // fixpoint combinator: fix f computes the least fixed-point of f
  };

  /// Binary operators
  public type BinOp = {
    #add;
    #sub;
    #mul;
    #div;
    #eq;
    #neq;
    #lt;
    #le;
    #gt;
    #ge;
    #and_;
    #or_;
  };

  /// Type annotations in the AST
  public type Type = {
    #int;
    #bool;
    #fun : { param : Type; ret : Type };
    #typeVar : Nat; // unification variable id
  };

  /// Runtime values
  public type Value = {
    #int : Int;
    #bool : Bool;
    #closure : { param : Text; body : Expr; env : Env };
    #builtin : Text;
  };

  /// Variable environment (immutable association list)
  public type Env = [(Text, Value)];

  /// Type environment
  public type TypeEnv = [(Text, Type)];
};
