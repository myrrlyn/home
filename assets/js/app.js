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

window.onload = () => {
	mark_headings();
	mark_codeblocks();
	set_jukebox();
	load_images();
};

function mark_headings() {
	for (let num of [2, 3, 4, 5, 6]) {
		let sel = `main article h${num}:not(.subtitle)`;
		for (let hed of document.querySelectorAll(sel)) {
			let inner = hed.innerHTML;
			let id = hed.id;
			if (id === "") {
				continue;
			}
			hed.innerHTML = `<a href="#${hed.id}" class="text-mono">§</a> <span>${inner}</span>`;
		}
	}
}

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

function set_jukebox() {
	for (let ident of ["intro", "outro"]) {
		let slot = document.getElementById(ident);
		if (slot !== null) {
			// console.debug(`Found slot ${slot}`);
			let audio = document.getElementById(`${ident}-sound`);
			if (audio !== null) {
				// console.debug(`Found audio ${audio}`);
				slot.parentNode.replaceChild(audio, slot);
			}
		}
	}
	for (let audio of document.getElementsByTagName("audio")) {
		audio.onplay = pause_others;
	}
}

function pause_others(event) {
	let src = event.target;
	for (let audio of document.getElementsByTagName("audio")) {
		if (audio == src) {
			continue;
		}
		audio.pause();
	}
}

function load_images() {
	function load_one(elems) {
		let elem = elems.pop();
		if (elem === undefined) { return; }
		let image = new Image();
		image.onload = () => {
			console.debug(`Replacing ${elem} with ${image}`);
			elem.replaceWith(image);
			load_one(elems);
		};
		image.src = elem.dataset.src;
	}

	let elems = Array.from(document.getElementsByClassName("async-image"));

	setTimeout(() => { load_one(elems); }, 20);
	setTimeout(() => { load_one(elems); }, 15);
	setTimeout(() => { load_one(elems); }, 10);
	setTimeout(() => { load_one(elems); }, 5);
}
