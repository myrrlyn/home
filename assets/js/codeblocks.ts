import hljs from "highlight.js";
// import elixir from "highlight.js/lib/languages/elixir";
// hljs.registerLanguage("elixir", elixir);

/**
 * Maps each language identifier as carried in `.codeblock-` classes to a marker
 * snippet.
 */
let lang_dict = {
  "ascii-art": "Text diagram",
  c: "C code",
  cosmos: "COSMOS interface definition",
  cpp: "C++ code",
  erlang: "Erlang code",
  elixir: "Elixir code",
  html: "HTML code",
  js: "JavaScript code",
  irc: "IRC log",
  ps1: "PowerShell session",
  rust: "Rust code",
  rust_errors: "Rust compiler errors",
  sh: "UNIX shell session",
  plain: "Plain text",
  plaintext: "Plain text",
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

        // TODO(myrrlyn): create a button that copies the code span to the
        // system clipboard.

        // let copy = document.createElement("button");
        // copy.classList.add("copy-icon");
        // copy.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><!--!Font Awesome Free 6.5.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.--><path d="M208 0H332.1c12.7 0 24.9 5.1 33.9 14.1l67.9 67.9c9 9 14.1 21.2 14.1 33.9V336c0 26.5-21.5 48-48 48H208c-26.5 0-48-21.5-48-48V48c0-26.5 21.5-48 48-48zM48 128h80v64H64V448H256V416h64v48c0 26.5-21.5 48-48 48H48c-26.5 0-48-21.5-48-48V176c0-26.5 21.5-48 48-48z"/></svg>`;

        // remaining tasks:
        // - add an onclick handler that grabs the sibling codeblock's contents
        //   and writes them into navigator.clipboard
        // - consider a tooltip explaining the button?

        // sources: <https://developer.mozilla.org/en-US/docs/Web/API/ClipboardItem>

        let wrapper = document.createElement("div");
        wrapper.classList.add("code-container", `codeblock-${lang}`);
        wrapper.appendChild(marker);
        // wrapper.appendChild(copy);
        node.replaceWith(wrapper);
        wrapper.appendChild(node);
      }
    }
  }
}
