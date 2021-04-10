// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "bootstrap";
import css from "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import hljs from 'highlight.js';

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
	text: "Plain text",
	term: "Text diagram",
	toml: "TOML configuration",
};

setTimeout(mark_codeblocks, 1);

function mark_codeblocks() {
	for (var node of document.querySelectorAll("pre.codeblock")) {
		var lang = null;
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
				if (lang === "term" || lang == "cosmos" || lang == "irc") {
					for (let klass of [`${lang}`, `lang-${lang}`, `language-${lang}`]) {
						codespan.classList.remove(klass);
					}
					for (let klass of ["text", "lang-text", "language-text"]) {
						codespan.classList.add(klass);
					}
				}
				hljs.highlightBlock(codespan);
				let marker = document.createElement("div");
				marker.classList.add("lang-marker");
				marker.innerText = lang_dict[lang];
				node.insertBefore(marker, codespan);

				let wrapper = document.createElement("div");
				wrapper.classList.add("code-container");
				wrapper.appendChild(codespan);
				node.append(wrapper);
			}
		}
	}
}
