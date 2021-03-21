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

setTimeout(() => {
	for (var div of document.querySelectorAll("div.MathJax_SVG_Display")) {
		let pt = div.parentElement;
		pt.insertBefore(div.children[0], div);
		pt.removeChild(div);
	}
}, 3333);
