export interface EvalResult {
  ok: boolean;
  value: string;
  inferredType: string;
  error: string;
}

export interface EvalHistoryEntry {
  id: string;
  input: string;
  result: EvalResult;
  timestamp: Date;
}

export interface Example {
  id: string;
  title: string;
  description: string;
  code: string;
  expectedType: string;
}
