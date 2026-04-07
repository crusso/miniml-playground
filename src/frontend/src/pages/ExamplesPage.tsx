import { EXAMPLES } from "@/data/examples";
import type { Example } from "@/types";
import { useNavigate } from "@tanstack/react-router";
import { Terminal } from "lucide-react";

export default function ExamplesPage() {
  const navigate = useNavigate();

  function handleLoad(code: string) {
    // Store in sessionStorage so ReplPage can read it on mount
    sessionStorage.setItem("miniml_load_code", code);
    navigate({ to: "/" });
  }

  return (
    <div className="flex flex-col flex-1 min-h-0">
      {/* Page header bar */}
      <div className="border-b border-border bg-secondary/30 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-baseline gap-4">
          <span className="text-label-upper text-primary tracking-widest font-mono">
            examples
          </span>
          <span className="text-muted-foreground font-mono text-xs">
            — {EXAMPLES.length} curated programs
          </span>
          <span className="ml-auto text-muted-foreground font-mono text-xs hidden sm:block">
            click any card to load in REPL
          </span>
        </div>
      </div>

      {/* Grid */}
      <div className="flex-1 overflow-y-auto px-6 py-6">
        <div
          className="max-w-7xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-px bg-border"
          data-ocid="examples-grid"
        >
          {EXAMPLES.map((example, i) => (
            <ExampleCard
              key={example.id}
              example={example}
              index={i}
              onLoad={() => handleLoad(example.code)}
            />
          ))}
        </div>

        <div className="max-w-7xl mx-auto mt-6 flex items-center gap-3">
          <div className="h-px flex-1 bg-border" />
          <span className="text-muted-foreground font-mono text-[0.65rem] tracking-widest uppercase">
            tip: use <code className="type-highlight">let rec</code> for
            recursive definitions
          </span>
          <div className="h-px flex-1 bg-border" />
        </div>
      </div>
    </div>
  );
}

interface ExampleCardProps {
  example: Example;
  index: number;
  onLoad: () => void;
}

function ExampleCard({ example, index, onLoad }: ExampleCardProps) {
  return (
    <article
      data-ocid={`example-card-${example.id}`}
      className="group flex flex-col bg-card hover:border-primary/60 transition-colors duration-200"
      style={{ animationDelay: `${index * 0.04}s` }}
    >
      {/* Card top bar: index + expected type */}
      <div className="flex items-center justify-between px-4 py-2 border-b border-border bg-secondary/40">
        <span className="text-label-upper text-muted-foreground font-mono text-[0.6rem]">
          {String(index + 1).padStart(2, "0")}
        </span>
        <span
          className="type-highlight text-xs font-mono truncate max-w-[160px]"
          title={`Expected type: ${example.expectedType}`}
        >
          {example.expectedType}
        </span>
      </div>

      {/* Title + description */}
      <div className="px-4 pt-3 pb-2">
        <h2 className="font-mono font-bold text-foreground text-sm leading-tight mb-1.5">
          {example.title}
        </h2>
        <p className="text-muted-foreground text-xs leading-relaxed line-clamp-2 font-mono">
          {example.description}
        </p>
      </div>

      {/* Code preview */}
      <div className="mx-4 mb-4 flex-1 bg-background border border-border/60 overflow-hidden">
        <pre className="code-output text-foreground/75 p-3 overflow-x-auto whitespace-pre leading-relaxed text-[0.7rem] max-h-[112px] scrollbar-none">
          <code>{example.code}</code>
        </pre>
      </div>

      {/* Load button */}
      <button
        type="button"
        data-ocid={`load-repl-${example.id}`}
        onClick={onLoad}
        className="flex items-center gap-2 px-4 py-2.5 border-t border-border bg-secondary/20 hover:bg-primary/10 text-xs font-mono text-muted-foreground hover:text-primary transition-colors-fast w-full focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        aria-label={`Load ${example.title} in REPL`}
      >
        <Terminal size={11} className="shrink-0" />
        <span>Load in REPL</span>
        <span className="ml-auto opacity-0 group-hover:opacity-100 transition-smooth font-bold">
          →
        </span>
      </button>
    </article>
  );
}
