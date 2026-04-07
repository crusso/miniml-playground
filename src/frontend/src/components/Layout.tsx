import { Link, useRouterState } from "@tanstack/react-router";

interface LayoutProps {
  children: React.ReactNode;
}

export function Layout({ children }: LayoutProps) {
  const state = useRouterState();
  const pathname = state.location.pathname;

  return (
    <div className="min-h-screen flex flex-col bg-background text-foreground">
      {/* Header */}
      <header
        className="bg-card border-b border-border sticky top-0 z-50"
        data-ocid="nav"
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-12 flex items-center justify-between">
          {/* Logo / Brand */}
          <div className="flex items-center gap-3">
            <span className="text-accent font-mono text-lg font-bold select-none leading-none">
              λ_
            </span>
            <span className="font-display font-semibold text-sm tracking-tight text-foreground">
              MiniML Playground
            </span>
          </div>

          {/* Nav links */}
          <nav className="flex items-center gap-1" aria-label="Main navigation">
            <NavLink
              href="/"
              active={pathname === "/"}
              label="REPL"
              ocid="nav-repl"
            />
            <NavLink
              href="/examples"
              active={pathname === "/examples"}
              label="Examples"
              ocid="nav-examples"
            />
          </nav>
        </div>
      </header>

      {/* Main */}
      <main className="flex-1 flex flex-col">{children}</main>

      {/* Footer */}
      <footer className="bg-muted/40 border-t border-border py-4 px-4">
        <p className="text-center text-muted-foreground text-xs font-mono">
          © {new Date().getFullYear()}. Built with love using{" "}
          <a
            href={`https://caffeine.ai?utm_source=caffeine-footer&utm_medium=referral&utm_content=${encodeURIComponent(
              typeof window !== "undefined" ? window.location.hostname : "",
            )}`}
            target="_blank"
            rel="noopener noreferrer"
            className="text-accent hover:underline"
          >
            caffeine.ai
          </a>
        </p>
      </footer>
    </div>
  );
}

interface NavLinkProps {
  href: string;
  active: boolean;
  label: string;
  ocid: string;
}

function NavLink({ href, active, label, ocid }: NavLinkProps) {
  return (
    <Link
      to={href}
      data-ocid={ocid}
      className={[
        "px-3 py-1 text-xs font-mono font-semibold tracking-widest uppercase transition-colors duration-150",
        active
          ? "text-accent border border-accent/50 bg-accent/10"
          : "text-muted-foreground hover:text-foreground border border-transparent hover:border-border",
      ].join(" ")}
    >
      {label}
    </Link>
  );
}
