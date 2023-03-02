// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import { set_jukebox } from "./jukebox";
import { mark_headings } from "./toc";
import "bootstrap";
import "phoenix_html";

window.onload = function () {
  mark_headings([2, 3, 4, 5, 6]);
  set_jukebox();
};
