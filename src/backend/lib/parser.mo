// Lexer + recursive-descent parser for mini-ML.
//
// Precedence (low → high):
//   let / fun / if  →  ||  →  &&  →  = / <> / < / <= / > / >=  →  + / -  →  * / /  →  app  →  atom
//
// Supports:
//   - let x = e in e2
//   - let f p1 p2 = body in e   (desugared to let f = fun p1 -> fun p2 -> body in e)
//   - let rec f p1 p2 = body in e  (desugared to let f = fix (fun f -> fun p1 -> fun p2 -> body) in e)
//   - fun x -> e
//   - Top-level program: sequence of `let f p1 ... = e` (no `in`) followed by a final expression

import Types "../types/ml";
import Nat32 "mo:core/Nat32";

module {
  public type ParseResult = { #ok : Types.Expr; #err : Text };

  // ─── Token ─────────────────────────────────────────────────────────────────
  type Token = {
    #intLit  : Int;
    #kwTrue;
    #kwFalse;
    #ident   : Text;
    #plus;
    #minus;
    #star;
    #slash;
    #eq;       // =  (let binding and equality)
    #neq;      // <>
    #lt;
    #le;
    #gt;
    #ge;
    #andAnd;
    #orOr;
    #lparen;
    #rparen;
    #arrow;    // ->
    #kwLet;
    #kwRec;
    #kwIn;
    #kwFun;
    #kwIf;
    #kwThen;
    #kwElse;
    #eof;
  };

  // ─── Lexer ─────────────────────────────────────────────────────────────────
  func isDigit(c : Char) : Bool { c >= '0' and c <= '9' };
  func isAlpha(c : Char) : Bool {
    (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
  };
  func isAlphaNum(c : Char) : Bool { isAlpha(c) or isDigit(c) };

  func identToToken(s : Text) : Token {
    switch s {
      case "let"   #kwLet;
      case "rec"   #kwRec;
      case "in"    #kwIn;
      case "fun"   #kwFun;
      case "if"    #kwIf;
      case "then"  #kwThen;
      case "else"  #kwElse;
      case "true"  #kwTrue;
      case "false" #kwFalse;
      case _       #ident s;
    }
  };

  func tokenize(src : Text) : [Token] {
    let chars = src.toArray();
    let n = chars.size();
    var i = 0;
    var buf : [Token] = [];

    func push(t : Token) { buf := buf.concat([t]) };

    label lex while (i < n) {
      let c = chars[i];

      // whitespace
      if (c == ' ' or c == '\n' or c == '\r' or c == '\t') { i += 1; continue lex };

      // integer literal
      if (isDigit(c)) {
        var num = 0 : Int;
        label digits while (i < n and isDigit(chars[i])) {
          let digitVal = (Char.toNat32(chars[i]) -% 48 : Nat32).toNat();
          num := num * 10 + digitVal.toInt();
          i += 1;
        };
        push(#intLit num);
        continue lex;
      };

      // identifier / keyword
      if (isAlpha(c)) {
        var word = "";
        label wl while (i < n and isAlphaNum(chars[i])) {
          word := word # Text.fromChar(chars[i]);
          i += 1;
        };
        push(identToToken(word));
        continue lex;
      };

      // two-char operators
      if (i + 1 < n) {
        let c2 = chars[i + 1];
        if (c == '-' and c2 == '>') { push(#arrow);  i += 2; continue lex };
        if (c == '<' and c2 == '>') { push(#neq);    i += 2; continue lex };
        if (c == '<' and c2 == '=') { push(#le);     i += 2; continue lex };
        if (c == '>' and c2 == '=') { push(#ge);     i += 2; continue lex };
        if (c == '&' and c2 == '&') { push(#andAnd); i += 2; continue lex };
        if (c == '|' and c2 == '|') { push(#orOr);   i += 2; continue lex };
      };

      // single-char operators
      switch c {
        case '+' { push(#plus);   i += 1 };
        case '-' { push(#minus);  i += 1 };
        case '*' { push(#star);   i += 1 };
        case '/' { push(#slash);  i += 1 };
        case '=' { push(#eq);     i += 1 };
        case '<' { push(#lt);     i += 1 };
        case '>' { push(#gt);     i += 1 };
        case '(' { push(#lparen); i += 1 };
        case ')' { push(#rparen); i += 1 };
        case _   { i += 1 };   // skip unknown
      };
    };
    push(#eof);
    buf
  };

  // ─── Parser class ──────────────────────────────────────────────────────────
  class Parser(tokens : [Token]) {
    var pos : Nat = 0;

    public func peek() : Token {
      if (pos < tokens.size()) tokens[pos] else #eof
    };

    public func advance() : Token {
      let t = peek();
      if (pos < tokens.size()) pos += 1;
      t
    };

    func expectEq() : ?Text {
      switch (advance()) {
        case (#eq) null;
        case t     ?(showToken(t) # " unexpected, expected '='");
      }
    };

    func _expectIn() : ?Text {
      switch (advance()) {
        case (#kwIn) null;
        case t       ?(showToken(t) # " unexpected, expected 'in'");
      }
    };

    func expectArrow() : ?Text {
      switch (advance()) {
        case (#arrow) null;
        case t        ?(showToken(t) # " unexpected, expected '->'");
      }
    };

    func expectRParen() : ?Text {
      switch (advance()) {
        case (#rparen) null;
        case t         ?(showToken(t) # " unexpected, expected ')'");
      }
    };

    func expectThen() : ?Text {
      switch (advance()) {
        case (#kwThen) null;
        case t         ?(showToken(t) # " unexpected, expected 'then'");
      }
    };

    func expectElse() : ?Text {
      switch (advance()) {
        case (#kwElse) null;
        case t         ?(showToken(t) # " unexpected, expected 'else'");
      }
    };

    // ── Grammar ──────────────────────────────────────────────────────────────

    public func parseExpr() : ParseResult { parseOr() };

    // ||
    func parseOr() : ParseResult {
      switch (parseAnd()) {
        case (#err e) #err e;
        case (#ok left) {
          var result = left;
          label lp loop {
            switch (peek()) {
              case (#orOr) {
                let _ = advance();
                switch (parseAnd()) {
                  case (#err e) return #err e;
                  case (#ok r)  result := #binop { op = #or_; left = result; right = r };
                };
              };
              case _ break lp;
            };
          };
          #ok result
        };
      }
    };

    // &&
    func parseAnd() : ParseResult {
      switch (parseCmpOrKeyword()) {
        case (#err e) #err e;
        case (#ok left) {
          var result = left;
          label lp loop {
            switch (peek()) {
              case (#andAnd) {
                let _ = advance();
                switch (parseCmpOrKeyword()) {
                  case (#err e) return #err e;
                  case (#ok r)  result := #binop { op = #and_; left = result; right = r };
                };
              };
              case _ break lp;
            };
          };
          #ok result
        };
      }
    };

    // let / fun / if  OR  comparison
    func parseCmpOrKeyword() : ParseResult {
      switch (peek()) {
        case (#kwLet) parseLet(true);
        case (#kwFun) parseFun();
        case (#kwIf)  parseIf();
        case _ {
          switch (parseAdd()) {
            case (#err e) #err e;
            case (#ok left) {
              var result = left;
              label lp loop {
                let mop : ?Types.BinOp = switch (peek()) {
                  case (#eq)  ?#eq;
                  case (#neq) ?#neq;
                  case (#lt)  ?#lt;
                  case (#le)  ?#le;
                  case (#gt)  ?#gt;
                  case (#ge)  ?#ge;
                  case _      null;
                };
                switch mop {
                  case null break lp;
                  case (?op) {
                    let _ = advance();
                    switch (parseAdd()) {
                      case (#err e) return #err e;
                      case (#ok r)  result := #binop { op; left = result; right = r };
                    };
                  };
                };
              };
              #ok result
            };
          }
        };
      }
    };

    // + -
    func parseAdd() : ParseResult {
      switch (parseMul()) {
        case (#err e) #err e;
        case (#ok left) {
          var result = left;
          label lp loop {
            let mop : ?Types.BinOp = switch (peek()) {
              case (#plus)  ?#add;
              case (#minus) ?#sub;
              case _        null;
            };
            switch mop {
              case null break lp;
              case (?op) {
                let _ = advance();
                switch (parseMul()) {
                  case (#err e) return #err e;
                  case (#ok r)  result := #binop { op; left = result; right = r };
                };
              };
            };
          };
          #ok result
        };
      }
    };

    // * /
    func parseMul() : ParseResult {
      switch (parseApp()) {
        case (#err e) #err e;
        case (#ok left) {
          var result = left;
          label lp loop {
            let mop : ?Types.BinOp = switch (peek()) {
              case (#star)  ?#mul;
              case (#slash) ?#div;
              case _        null;
            };
            switch mop {
              case null break lp;
              case (?op) {
                let _ = advance();
                switch (parseApp()) {
                  case (#err e) return #err e;
                  case (#ok r)  result := #binop { op; left = result; right = r };
                };
              };
            };
          };
          #ok result
        };
      }
    };

    // function application (left-assoc)
    func parseApp() : ParseResult {
      switch (parseAtom()) {
        case (#err e) #err e;
        case (#ok func_) {
          var result = func_;
          label lp loop {
            // atom-starters (not operators or keywords that end a sub-expr)
            switch (peek()) {
              case (#intLit _) {};
              case (#kwTrue)   {};
              case (#kwFalse)  {};
              case (#ident _)  {};
              case (#lparen)   {};
              case _ break lp;
            };
            switch (parseAtom()) {
              case (#err e) return #err e;
              case (#ok arg) result := #app { func_ = result; arg };
            };
          };
          #ok result
        };
      }
    };

    // atoms
    func parseAtom() : ParseResult {
      switch (peek()) {
        case (#intLit n)  { let _ = advance(); #ok (#intLit n) };
        case (#kwTrue)    { let _ = advance(); #ok (#boolLit true) };
        case (#kwFalse)   { let _ = advance(); #ok (#boolLit false) };
        case (#ident x)   { let _ = advance(); #ok (#var_ x) };
        case (#lparen) {
          let _ = advance();
          switch (parseExpr()) {
            case (#err e) #err e;
            case (#ok e) {
              switch (expectRParen()) {
                case (?err) #err err;
                case null   #ok e;
              }
            };
          }
        };
        case t #err ("Unexpected token: " # showToken(t));
      }
    };

    // Parse params until '=' — returns list of param names
    func parseParams() : { #ok : [Text]; #err : Text } {
      var params : [Text] = [];
      label lp loop {
        switch (peek()) {
          case (#ident p) {
            let _ = advance();
            params := params.concat([p]);
          };
          case (#eq) break lp;
          case t return #err ("Expected parameter name or '=', got " # showToken(t));
        };
      };
      #ok params
    };

    // Wrap body in nested lambdas for each param (right-to-left)
    func wrapLams(params : [Text], body : Types.Expr) : Types.Expr {
      var e = body;
      var i = params.size();
      while (i > 0) {
        i -= 1;
        e := #lam { param = params[i]; paramType = null; body = e };
      };
      e
    };

    // let [rec] name [params...] = e1 in e2
    // requireIn: if true, require 'in' keyword after RHS (expression-level let)
    //            if false, 'in' is optional (top-level definition mode — no 'in' needed)
    public func parseLet(requireIn : Bool) : ParseResult {
      let _ = advance(); // 'let'
      let isRec = switch (peek()) {
        case (#kwRec) { let _ = advance(); true };
        case _        false;
      };
      switch (advance()) {
        case (#ident name) {
          // collect parameters before '='
          switch (parseParams()) {
            case (#err e) #err e;
            case (#ok params) {
              switch (expectEq()) {
                case (?err) #err err;
                case null {
                  switch (parseExpr()) {
                    case (#err e) #err e;
                    case (#ok rhs) {
                      // Desugar params into lambdas
                      let valueExpr : Types.Expr = if (params.size() == 0) {
                        rhs
                      } else {
                        wrapLams(params, rhs)
                      };
                      // Wrap with fix for rec
                      let finalValue : Types.Expr = if (isRec) {
                        #fix (#lam { param = name; paramType = null; body = valueExpr })
                      } else {
                        valueExpr
                      };
                      // Check for 'in'
                      switch (peek()) {
                        case (#kwIn) {
                          let _ = advance(); // consume 'in'
                          switch (parseExpr()) {
                            case (#err e) #err e;
                            case (#ok body) #ok (#let_ { name; value = finalValue; body });
                          }
                        };
                        case _ {
                          if (requireIn) {
                            #err ("Expected 'in' after let binding value")
                          } else {
                            // Return a sentinel: let_ with unit-like body placeholder
                            // Caller (parseProgram) will chain the body
                            #ok (#let_ { name; value = finalValue; body = #var_ "__toplevel__" })
                          }
                        };
                      }
                    };
                  }
                };
              }
            };
          }
        };
        case t #err ("Expected identifier after 'let', got " # showToken(t));
      }
    };

    // fun x -> e  (also supports multi-param: fun x y -> e)
    func parseFun() : ParseResult {
      let _ = advance(); // 'fun'
      // collect one or more params
      var params : [Text] = [];
      label lp loop {
        switch (peek()) {
          case (#ident p) {
            let _ = advance();
            params := params.concat([p]);
          };
          case _ break lp;
        };
      };
      if (params.size() == 0) {
        return #err "Expected parameter name after 'fun'";
      };
      switch (expectArrow()) {
        case (?err) #err err;
        case null {
          switch (parseExpr()) {
            case (#err e) #err e;
            case (#ok body) #ok (wrapLams(params, body));
          }
        };
      }
    };

    // if e1 then e2 else e3
    func parseIf() : ParseResult {
      let _ = advance(); // 'if'
      switch (parseExpr()) {
        case (#err e) #err e;
        case (#ok cond) {
          switch (expectThen()) {
            case (?err) #err err;
            case null {
              switch (parseExpr()) {
                case (#err e) #err e;
                case (#ok then_) {
                  switch (expectElse()) {
                    case (?err) #err err;
                    case null {
                      switch (parseExpr()) {
                        case (#err e) #err e;
                        case (#ok else_) #ok (#if_ { cond; then_; else_ });
                      }
                    };
                  }
                };
              }
            };
          }
        };
      }
    };

    // Top-level program:
    //   let f p1 ... = e
    //   let g p1 ... = e
    //   ...
    //   finalExpr
    // Each top-level let without 'in' is collected; the last item must be a non-let expression.
    public func parseProgram() : ParseResult {
      // Collect top-level definitions: list of (name, valueExpr)
      var defs : [(Text, Types.Expr)] = [];

      label outer loop {
        switch (peek()) {
          case (#kwLet) {
            // Speculatively check: is the token after 'let' (and optional 'rec') followed
            // by ident params* '=' ... and no 'in'?
            // We use parseLet(false) which returns a sentinel body __toplevel__ when no 'in' found.
            let savedPos = pos;
            switch (parseLet(false)) {
              case (#err _e) {
                pos := savedPos;
                break outer;
              };
              case (#ok (#let_ { name; value; body = #var_ "__toplevel__" })) {
                // Top-level definition (no 'in' consumed)
                defs := defs.concat([(name, value)]);
              };
              case (#ok expr) {
                // Had 'in' — it was a self-contained let..in expression, treat as final expr
                // but we still need to wrap with prior defs
                return #ok (nestDefs(defs, expr));
              };
            };
          };
          case _ break outer;
        };
      };

      // Parse the final expression
      switch (parseExpr()) {
        case (#err e) #err e;
        case (#ok finalExpr) #ok (nestDefs(defs, finalExpr));
      }
    };
  };

  // Nest definitions: let d1 = v1 in (let d2 = v2 in (... in finalExpr))
  func nestDefs(defs : [(Text, Types.Expr)], finalExpr : Types.Expr) : Types.Expr {
    var e = finalExpr;
    var i = defs.size();
    while (i > 0) {
      i -= 1;
      let (name, value) = defs[i];
      e := #let_ { name; value; body = e };
    };
    e
  };

  func showToken(t : Token) : Text {
    switch t {
      case (#intLit n) "int(" # n.toText() # ")";
      case (#kwTrue)   "true";
      case (#kwFalse)  "false";
      case (#ident x)  x;
      case (#plus)     "+";
      case (#minus)    "-";
      case (#star)     "*";
      case (#slash)    "/";
      case (#eq)       "=";
      case (#neq)      "<>";
      case (#lt)       "<";
      case (#le)       "<=";
      case (#gt)       ">";
      case (#ge)       ">=";
      case (#andAnd)   "&&";
      case (#orOr)     "||";
      case (#lparen)   "(";
      case (#rparen)   ")";
      case (#arrow)    "->";
      case (#kwLet)    "let";
      case (#kwRec)    "rec";
      case (#kwIn)     "in";
      case (#kwFun)    "fun";
      case (#kwIf)     "if";
      case (#kwThen)   "then";
      case (#kwElse)   "else";
      case (#eof)      "<eof>";
    }
  };

  // ─── Public entries ──────────────────────────────────────────────────────────

  /// Parse a single expression (no top-level definitions)
  public func parse(src : Text) : ParseResult {
    let tokens = tokenize(src);
    let p = Parser(tokens);
    switch (p.parseExpr()) {
      case (#err e) #err ("Parse error: " # e);
      case (#ok expr) {
        switch (p.peek()) {
          case (#eof) #ok expr;
          case t      #err ("Parse error: unexpected token after expression: " # showToken(t));
        }
      };
    }
  };

  /// Parse a program: zero or more top-level `let` definitions followed by a final expression
  public func parseProgram(src : Text) : ParseResult {
    let tokens = tokenize(src);
    let p = Parser(tokens);
    switch (p.parseProgram()) {
      case (#err e) #err ("Parse error: " # e);
      case (#ok expr) {
        switch (p.peek()) {
          case (#eof) #ok expr;
          case t      #err ("Parse error: unexpected token after program: " # showToken(t));
        }
      };
    }
  };
};
