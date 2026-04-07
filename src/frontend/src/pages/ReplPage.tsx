import { EXAMPLES } from "@/data/examples";
import { useEvaluate } from "@/hooks/useEvaluate";
import type { EvalHistoryEntry, EvalResult, Example } from "@/types";
import { useCallback, useEffect, useId, useRef, useState } from "react";

export default function ReplPage() {
  const [input, setInput] = useState("");
  const [history, setHistory] = useState<EvalHistoryEntry[]>([]);
  const { evaluate, isLoading } = useEvaluate();
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const historyEndRef = useRef<HTMLDivElement>(null);
  const uid = useId();

  // Load example from URL params or sessionStorage on mount
  // Supports ?code=<raw-code> (URL param), ?example=<id>, or sessionStorage key
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const rawCode = params.get("code");
    if (rawCode) {
      setInput(decodeURIComponent(rawCode));
      window.history.replaceState({}, "", window.location.pathname);
      setTimeout(() => textareaRef.current?.focus(), 50);
      return;
    }
    const exId = params.get("example");
    if (exId) {
      const found = EXAMPLES.find((e) => e.id === exId);
      if (found) {
        setInput(found.code);
        window.history.replaceState({}, "", window.location.pathname);
        setTimeout(() => textareaRef.current?.focus(), 50);
        return;
      }
    }
    // Legacy: sessionStorage (set by ExamplesPage)
    const stored = sessionStorage.getItem("miniml_load_code");
    if (stored) {
      sessionStorage.removeItem("miniml_load_code");
      setInput(stored);
      setTimeout(() => textareaRef.current?.focus(), 50);
    }
  }, []);

  const handleEvaluate = useCallback(async () => {
    const src = input.trim();
    if (!src || isLoading) return;

    const result = await evaluate(src);
    if (!result) return;

    const entry: EvalHistoryEntry = {
      id: `${uid}-${Date.now()}`,
      input: src,
      result,
      timestamp: new Date(),
    };

    setHistory((prev) => [...prev, entry]);
    setInput("");
    requestAnimationFrame(() => {
      historyEndRef.current?.scrollIntoView({ behavior: "smooth" });
    });
  }, [input, isLoading, evaluate, uid]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        handleEvaluate();
      }
    },
    [handleEvaluate],
  );

  const loadExample = useCallback((code: string) => {
    setInput(code);
    setTimeout(() => textareaRef.current?.focus(), 0);
  }, []);

  const clearHistory = useCallback(() => setHistory([]), []);

  return (
    <div className="flex-1 flex flex-col lg:flex-row min-h-0">
      {/* Left: REPL panel */}
      <div className="flex-1 flex flex-col min-w-0 border-r border-border">
        {/* Session toolbar */}
        <div className="flex items-center justify-between px-4 sm:px-6 py-2 bg-card border-b border-border">
          <div className="flex items-center gap-3">
            <span className="text-accent font-mono text-xs font-bold select-none">
              ●
            </span>
            <span className="text-accent font-mono text-xs font-bold tracking-widest uppercase">
              MiniML Session
            </span>
            <span className="text-muted-foreground font-mono text-xs hidden sm:inline">
              — Ctrl/⌘+Enter to run
            </span>
          </div>
          {history.length > 0 && (
            <button
              type="button"
              onClick={clearHistory}
              data-ocid="clear-history"
              className="font-mono text-xs tracking-widest uppercase text-muted-foreground hover:text-destructive border border-transparent hover:border-destructive/40 px-2 py-1 transition-colors-fast"
            >
              clear
            </button>
          )}
        </div>

        {/* History scroll area */}
        <div
          className="flex-1 overflow-y-auto min-h-0 flex flex-col"
          data-ocid="history-list"
        >
          {history.length === 0 ? (
            <EmptyState onLoadExample={loadExample} />
          ) : (
            <div className="flex flex-col divide-y divide-border">
              {history.map((entry) => (
                <HistoryRow key={entry.id} entry={entry} />
              ))}
              {isLoading && <LoadingRow />}
              <div ref={historyEndRef} />
            </div>
          )}
        </div>

        {/* Input area */}
        <div
          className="border-t border-border bg-card"
          data-ocid="repl-input-area"
        >
          {/* Toolbar top */}
          <div className="flex items-center gap-2 px-4 pt-3 pb-1">
            <span className="text-accent font-mono text-sm font-bold select-none">
              ›_
            </span>
            <span className="text-muted-foreground font-mono text-xs tracking-widest uppercase">
              input
            </span>
          </div>

          <textarea
            ref={textareaRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={"let add x y = x + y\nadd 3 4"}
            rows={6}
            disabled={isLoading}
            data-ocid="repl-textarea"
            className={[
              "code-input w-full bg-transparent px-4 py-2 resize-none outline-none",
              "placeholder:text-muted-foreground/30 text-foreground",
              "focus:border-accent-glow transition-smooth",
              isLoading ? "opacity-50 cursor-not-allowed" : "",
            ].join(" ")}
            aria-label="ML expression input"
            spellCheck={false}
            autoComplete="off"
            autoCorrect="off"
          />

          {/* Toolbar bottom */}
          <div className="flex items-center justify-between px-4 pb-3 pt-1">
            <span className="text-muted-foreground font-mono text-xs">
              {isLoading ? (
                <span className="text-accent flex items-center gap-2">
                  <Spinner />
                  evaluating…
                </span>
              ) : (
                <span className="hidden sm:inline">
                  ⌘↩ or Ctrl+↩ to evaluate
                </span>
              )}
            </span>
            <button
              type="button"
              onClick={handleEvaluate}
              disabled={isLoading || !input.trim()}
              data-ocid="evaluate-btn"
              className={[
                "font-mono text-xs tracking-widest uppercase px-5 py-2 border transition-colors-fast",
                "disabled:opacity-30 disabled:cursor-not-allowed",
                "border-accent text-accent hover:bg-accent hover:text-accent-foreground",
                "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
              ].join(" ")}
            >
              {isLoading ? "running…" : "run"}
            </button>
          </div>
        </div>
      </div>

      {/* Right: Examples panel */}
      <aside
        className="w-full lg:w-80 xl:w-96 flex flex-col bg-background border-t lg:border-t-0 border-border"
        data-ocid="examples-panel"
      >
        <div className="flex items-center gap-2 px-4 py-3 bg-card border-b border-border">
          <span className="text-accent font-mono text-xs font-bold tracking-widest uppercase">
            Examples
          </span>
          <span className="text-muted-foreground font-mono text-xs ml-auto">
            {EXAMPLES.length} programs
          </span>
        </div>
        <div className="flex-1 overflow-y-auto">
          <div className="p-3 flex flex-col gap-2">
            {EXAMPLES.map((ex) => (
              <ExampleCard key={ex.id} example={ex} onLoad={loadExample} />
            ))}
          </div>
        </div>
      </aside>
    </div>
  );
}

/* ── Sub-components ─────────────────────────────────────────────────── */

function EmptyState({
  onLoadExample,
}: { onLoadExample: (code: string) => void }) {
  const starter = EXAMPLES[1]; // "Integer Addition" — simple, digestible
  return (
    <div className="flex-1 flex flex-col items-center justify-center p-8 text-center gap-4">
      <span className="text-accent font-mono text-4xl font-bold select-none opacity-20">
        λ
      </span>
      <p className="text-muted-foreground font-mono text-sm max-w-xs leading-relaxed">
        Type an ML expression above and press{" "}
        <kbd className="px-1.5 py-0.5 border border-border text-xs">⌘↩</kbd> to
        evaluate.
      </p>
      <button
        type="button"
        onClick={() => onLoadExample(starter.code)}
        data-ocid="empty-state-cta"
        className="font-mono text-xs tracking-widest uppercase px-4 py-2 border border-accent/50 text-accent hover:bg-accent/10 transition-colors-fast"
      >
        try: {starter.title}
      </button>
    </div>
  );
}

function LoadingRow() {
  return (
    <div className="px-4 py-3 border-b border-border animate-pulse">
      <div className="flex items-center gap-2">
        <span className="text-muted-foreground font-mono text-xs select-none">
          ›
        </span>
        <span className="text-muted-foreground font-mono text-xs">
          evaluating
        </span>
        <Spinner className="text-accent" />
      </div>
    </div>
  );
}

function HistoryRow({ entry }: { entry: EvalHistoryEntry }) {
  const ts = entry.timestamp.toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });

  return (
    <div
      className="history-row px-4 py-4 animate-slide-in-up"
      data-ocid="history-row"
    >
      {/* Timestamp + prompt */}
      <div className="flex items-start gap-2 mb-2">
        <span
          className="text-muted-foreground font-mono text-xs mt-0.5 select-none shrink-0"
          aria-hidden
        >
          ›
        </span>
        <pre className="code-output text-foreground/80 whitespace-pre-wrap break-words min-w-0 flex-1">
          <code>{entry.input}</code>
        </pre>
        <time
          dateTime={entry.timestamp.toISOString()}
          className="text-muted-foreground/50 font-mono text-xs shrink-0 mt-0.5 hidden sm:block"
        >
          {ts}
        </time>
      </div>
      {/* Result */}
      <ResultDisplay result={entry.result} />
    </div>
  );
}

function ResultDisplay({ result }: { result: EvalResult }) {
  if (!result.ok) {
    return (
      <div className="ml-4 border-l-2 border-destructive pl-3 py-0.5">
        <span className="font-mono text-xs tracking-widest uppercase text-destructive font-bold">
          error
        </span>
        <pre className="code-output text-destructive mt-1 whitespace-pre-wrap break-words">
          <code>{result.error}</code>
        </pre>
      </div>
    );
  }

  return (
    <div className="ml-4 flex flex-col gap-1.5">
      {result.inferredType && (
        <div className="flex items-center gap-2">
          <span className="font-mono text-xs tracking-widest uppercase text-muted-foreground">
            type
          </span>
          <span className="type-highlight">{result.inferredType}</span>
        </div>
      )}
      {result.value !== "" && (
        <div className="flex items-start gap-2">
          <span className="font-mono text-xs tracking-widest uppercase text-muted-foreground mt-0.5 shrink-0">
            val
          </span>
          <pre className="code-output text-foreground whitespace-pre-wrap break-words min-w-0">
            <code>{result.value}</code>
          </pre>
        </div>
      )}
    </div>
  );
}

function ExampleCard({
  example,
  onLoad,
}: {
  example: Example;
  onLoad: (code: string) => void;
}) {
  return (
    <button
      type="button"
      onClick={() => onLoad(example.code)}
      data-ocid={`example-${example.id}`}
      className="group w-full text-left border border-border bg-card hover:border-accent/60 hover:bg-accent/5 transition-colors-fast p-3 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
    >
      <div className="flex items-start justify-between gap-2 mb-1.5">
        <span className="font-mono text-xs font-bold text-foreground group-hover:text-accent transition-colors-fast leading-tight">
          {example.title}
        </span>
        <span className="type-highlight text-xs shrink-0">
          {example.expectedType}
        </span>
      </div>
      <p className="font-mono text-xs text-muted-foreground leading-relaxed mb-2 line-clamp-2">
        {example.description}
      </p>
      <pre className="code-output text-muted-foreground/70 text-xs bg-background/60 p-2 overflow-hidden max-h-16 leading-snug">
        <code className="line-clamp-3">{example.code}</code>
      </pre>
    </button>
  );
}

function Spinner({ className = "" }: { className?: string }) {
  return (
    <svg
      className={`inline-block w-3 h-3 animate-spin ${className}`}
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"
      />
    </svg>
  );
}
