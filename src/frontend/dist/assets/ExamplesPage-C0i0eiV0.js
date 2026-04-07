import { J as reactExports, $ as useNavigate, _ as jsxRuntimeExports } from "./index-2oa-DoTP.js";
import { E as EXAMPLES } from "./examples-B78igpKx.js";
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const toKebabCase = (string) => string.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const toCamelCase = (string) => string.replace(
  /^([A-Z])|[\s-_]+(\w)/g,
  (match, p1, p2) => p2 ? p2.toUpperCase() : p1.toLowerCase()
);
const toPascalCase = (string) => {
  const camelCase = toCamelCase(string);
  return camelCase.charAt(0).toUpperCase() + camelCase.slice(1);
};
const mergeClasses = (...classes) => classes.filter((className, index, array) => {
  return Boolean(className) && className.trim() !== "" && array.indexOf(className) === index;
}).join(" ").trim();
const hasA11yProp = (props) => {
  for (const prop in props) {
    if (prop.startsWith("aria-") || prop === "role" || prop === "title") {
      return true;
    }
  }
};
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
var defaultAttributes = {
  xmlns: "http://www.w3.org/2000/svg",
  width: 24,
  height: 24,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 2,
  strokeLinecap: "round",
  strokeLinejoin: "round"
};
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Icon = reactExports.forwardRef(
  ({
    color = "currentColor",
    size = 24,
    strokeWidth = 2,
    absoluteStrokeWidth,
    className = "",
    children,
    iconNode,
    ...rest
  }, ref) => reactExports.createElement(
    "svg",
    {
      ref,
      ...defaultAttributes,
      width: size,
      height: size,
      stroke: color,
      strokeWidth: absoluteStrokeWidth ? Number(strokeWidth) * 24 / Number(size) : strokeWidth,
      className: mergeClasses("lucide", className),
      ...!children && !hasA11yProp(rest) && { "aria-hidden": "true" },
      ...rest
    },
    [
      ...iconNode.map(([tag, attrs]) => reactExports.createElement(tag, attrs)),
      ...Array.isArray(children) ? children : [children]
    ]
  )
);
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const createLucideIcon = (iconName, iconNode) => {
  const Component = reactExports.forwardRef(
    ({ className, ...props }, ref) => reactExports.createElement(Icon, {
      ref,
      iconNode,
      className: mergeClasses(
        `lucide-${toKebabCase(toPascalCase(iconName))}`,
        `lucide-${iconName}`,
        className
      ),
      ...props
    })
  );
  Component.displayName = toPascalCase(iconName);
  return Component;
};
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode = [
  ["path", { d: "M12 19h8", key: "baeox8" }],
  ["path", { d: "m4 17 6-6-6-6", key: "1yngyt" }]
];
const Terminal = createLucideIcon("terminal", __iconNode);
function ExamplesPage() {
  const navigate = useNavigate();
  function handleLoad(code) {
    sessionStorage.setItem("miniml_load_code", code);
    navigate({ to: "/" });
  }
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col flex-1 min-h-0", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border-b border-border bg-secondary/30 px-6 py-4", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "max-w-7xl mx-auto flex items-baseline gap-4", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-label-upper text-primary tracking-widest font-mono", children: "examples" }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-muted-foreground font-mono text-xs", children: [
        "— ",
        EXAMPLES.length,
        " curated programs"
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "ml-auto text-muted-foreground font-mono text-xs hidden sm:block", children: "click any card to load in REPL" })
    ] }) }),
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex-1 overflow-y-auto px-6 py-6", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx(
        "div",
        {
          className: "max-w-7xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-px bg-border",
          "data-ocid": "examples-grid",
          children: EXAMPLES.map((example, i) => /* @__PURE__ */ jsxRuntimeExports.jsx(
            ExampleCard,
            {
              example,
              index: i,
              onLoad: () => handleLoad(example.code)
            },
            example.id
          ))
        }
      ),
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "max-w-7xl mx-auto mt-6 flex items-center gap-3", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "h-px flex-1 bg-border" }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-muted-foreground font-mono text-[0.65rem] tracking-widest uppercase", children: [
          "tip: use ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "type-highlight", children: "let rec" }),
          " for recursive definitions"
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "h-px flex-1 bg-border" })
      ] })
    ] })
  ] });
}
function ExampleCard({ example, index, onLoad }) {
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "article",
    {
      "data-ocid": `example-card-${example.id}`,
      className: "group flex flex-col bg-card hover:border-primary/60 transition-colors duration-200",
      style: { animationDelay: `${index * 0.04}s` },
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center justify-between px-4 py-2 border-b border-border bg-secondary/40", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-label-upper text-muted-foreground font-mono text-[0.6rem]", children: String(index + 1).padStart(2, "0") }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            "span",
            {
              className: "type-highlight text-xs font-mono truncate max-w-[160px]",
              title: `Expected type: ${example.expectedType}`,
              children: example.expectedType
            }
          )
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "px-4 pt-3 pb-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("h2", { className: "font-mono font-bold text-foreground text-sm leading-tight mb-1.5", children: example.title }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-muted-foreground text-xs leading-relaxed line-clamp-2 font-mono", children: example.description })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "mx-4 mb-4 flex-1 bg-background border border-border/60 overflow-hidden", children: /* @__PURE__ */ jsxRuntimeExports.jsx("pre", { className: "code-output text-foreground/75 p-3 overflow-x-auto whitespace-pre leading-relaxed text-[0.7rem] max-h-[112px] scrollbar-none", children: /* @__PURE__ */ jsxRuntimeExports.jsx("code", { children: example.code }) }) }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "button",
          {
            type: "button",
            "data-ocid": `load-repl-${example.id}`,
            onClick: onLoad,
            className: "flex items-center gap-2 px-4 py-2.5 border-t border-border bg-secondary/20 hover:bg-primary/10 text-xs font-mono text-muted-foreground hover:text-primary transition-colors-fast w-full focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
            "aria-label": `Load ${example.title} in REPL`,
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(Terminal, { size: 11, className: "shrink-0" }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { children: "Load in REPL" }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "ml-auto opacity-0 group-hover:opacity-100 transition-smooth font-bold", children: "→" })
            ]
          }
        )
      ]
    }
  );
}
export {
  ExamplesPage as default
};
