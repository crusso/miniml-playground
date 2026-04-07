import type { backendInterface } from "../backend";

export const mockBackend: backendInterface = {
  evaluate: async (src: string) => {
    // Simulate some basic ML interpreter responses
    if (src.trim() === "") {
      return { ok: false, value: "", inferredType: "", error: "Empty input" };
    }
    if (src.includes("let")) {
      return { ok: true, value: "42", inferredType: "Int", error: "" };
    }
    if (src.includes("fun")) {
      return { ok: true, value: "<function>", inferredType: "Int -> Int", error: "" };
    }
    if (src.includes("+") || src.includes("-") || src.includes("*")) {
      return { ok: true, value: "10", inferredType: "Int", error: "" };
    }
    if (src.includes("true") || src.includes("false")) {
      return { ok: true, value: "true", inferredType: "Bool", error: "" };
    }
    return { ok: true, value: src.trim(), inferredType: "String", error: "" };
  },
};
