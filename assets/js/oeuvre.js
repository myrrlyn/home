// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "bootstrap";
import css from "../css/oeuvre.scss";

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

window.onload = function () {
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
};

function pause_others(event) {
	let src = event.target;
	for (let audio of document.getElementsByTagName("audio")) {
		if (audio == src) {
			continue;
		}
		audio.pause();
	}
}
