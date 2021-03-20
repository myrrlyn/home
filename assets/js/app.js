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
	rust: "Rust code",
	sh: "Shell session",
	text: "Plain text",
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