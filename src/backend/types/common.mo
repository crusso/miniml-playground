module {
  /// Result returned by the evaluate endpoint
  public type EvalResult = {
    ok : Bool;
    value : Text;
    inferredType : Text;
    error : Text;
  };
};
