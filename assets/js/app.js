import "bootstrap"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

import hljs from 'highlight.js';

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } })

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

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
	xml: "XML",
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
		image.classList.add("unset", "gallery-img");
		let title = elem.dataset.title;
		if (title) {
			image.alt = title;
		}
		image.onload = () => {
			elem.replaceWith(image);
			load_one(elems);
		};
		image.src = elem.dataset.src;
	}

	let elems = Array.from(document.getElementsByClassName("async-image")).reverse();

	setTimeout(() => { load_one(elems); }, 20);
	setTimeout(() => { load_one(elems); }, 15);
	setTimeout(() => { load_one(elems); }, 10);
	setTimeout(() => { load_one(elems); }, 5);
}
