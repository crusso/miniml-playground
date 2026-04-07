import { type backendInterface, createActor } from "@/backend";
import type { EvalResult } from "@/types";
import { useActor } from "@caffeineai/core-infrastructure";
import { useState } from "react";

// Extend the backend interface to include the evaluate method once bindgen runs
type BackendWithEvaluate = backendInterface & {
  evaluate?: (src: string) => Promise<EvalResult>;
};

export function useEvaluate() {
  const { actor, isFetching } = useActor<BackendWithEvaluate>(
    createActor as Parameters<typeof useActor<BackendWithEvaluate>>[0],
  );
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function evaluate(src: string): Promise<EvalResult | null> {
    if (!actor || isFetching) return null;

    setIsLoading(true);
    setError(null);

    try {
      if (!actor.evaluate) {
        throw new Error(
          "Backend evaluate method not available. Run pnpm bindgen.",
        );
      }
      const result = await actor.evaluate(src);
      return result;
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Unknown error";
      setError(msg);
      return {
        ok: false,
        value: "",
        inferredType: "",
        error: msg,
      };
    } finally {
      setIsLoading(false);
    }
  }

  return { evaluate, isLoading, error };
}
