// import Prism from "prismjs";

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
	sh: "UNIX shell session",
	plain: "Plain text",
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
				if (lang === "term" || lang == "cosmos" || lang == "irc") {
					for (let klass of [`${lang}`, `lang-${lang}`, `language-${lang}`]) {
						codespan.classList.remove(klass);
					}
					for (let klass of ["plain", "lang-plain", "language-plain"]) {
						codespan.classList.add(klass);
					}
				}
				let marker = document.createElement("div");
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
