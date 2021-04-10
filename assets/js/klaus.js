// import "bootstrap";
import css from "../css/klaus.scss";

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

window.onload = () => {
	let from = document.getElementById("date-src");
	let to = document.getElementById("date");
	if ((from !== null) && (to !== null)) {
		to.innerText = from.innerText;
		from.parentNode.removeChild(from);
	}
};
