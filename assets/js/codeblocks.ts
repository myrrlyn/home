import hljs from "highlight.js";
// import elixir from "highlight.js/lib/languages/elixir";
// hljs.registerLanguage("elixir", elixir);

/**
 * Maps each language identifier as carried in `.codeblock-` classes to a marker
 * snippet.
 */
let lang_dict = {
  c: "C code",
  cosmos: "COSMOS interface definition",
  cpp: "C++ code",
  erlang: "Erlang code",
  elixir: "Elixir code",
  js: "JavaScript code",
  irc: "IRC log",
  ps1: "PowerShell session",
  rust: "Rust code",
  rust_errors: "Rust compiler errors",
  sh: "UNIX shell session",
  plain: "Plain text",
  plaintext: "Plain text",
  term: "Text diagram",
  toml: "TOML configuration",
  xml: "XML",
};

export function mark_codeblocks() {
  for (var node of document.querySelectorAll("pre.codeblock")) {
    var lang: string | null = null;
    for (var klass of node.classList) {
      if (klass.startsWith("codeblock-")) {
        lang = klass.replace(/^codeblock-/, "");
        break;
      }
    }
    if (lang !== null) {
      let text = lang_dict[lang];
      if (text !== undefined) {
        let codespan = node.firstElementChild;
        if (codespan === null) {
          continue;
        }
        if (lang === "term" || lang == "cosmos" || lang == "irc" || lang === "rust_errors") {
          codespan.classList.remove(`${lang}`, `lang-${lang}`, `language-${lang}`);
          codespan.classList.add("plaintext", "lang-plaintext", "language-plaintext");
        }
        hljs.highlightElement(codespan as HTMLElement);

        let marker = document.createElement("span");
        marker.classList.add("lang-marker");
        marker.innerText = lang_dict[lang];

        let wrapper = document.createElement("div");
        wrapper.classList.add("code-container", `codeblock-${lang}`);
        wrapper.appendChild(marker);
        node.replaceWith(wrapper);
        wrapper.appendChild(node);
      }
    }
  }
}
