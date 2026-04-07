import { Layout } from "@/components/Layout";
import {
  RouterProvider,
  createRootRoute,
  createRoute,
  createRouter,
} from "@tanstack/react-router";
import { Suspense, lazy } from "react";

const ReplPage = lazy(() => import("@/pages/ReplPage"));
const ExamplesPage = lazy(() => import("@/pages/ExamplesPage"));

const rootRoute = createRootRoute({
  component: () => (
    <Layout>
      <Suspense fallback={<PageLoader />}>
        <Outlet />
      </Suspense>
    </Layout>
  ),
});

const replRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/",
  component: ReplPage,
});

const examplesRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/examples",
  component: ExamplesPage,
});

const routeTree = rootRoute.addChildren([replRoute, examplesRoute]);

const router = createRouter({ routeTree });

declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router;
  }
}

function PageLoader() {
  return (
    <div className="flex-1 flex items-center justify-center text-muted-foreground font-mono text-sm">
      loading...
    </div>
  );
}

// Inline Outlet helper so rootRoute component can render child routes
import { Outlet } from "@tanstack/react-router";

export default function App() {
  return <RouterProvider router={router} />;
}
