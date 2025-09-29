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
import * as blocks from "./codeblocks";
import * as gallery from "./image_loader";
import * as music from "./jukebox";
import { LiveSocketWindow, get_live_socket } from "./lswin";
import * as toc from "./toc";
import * as sundial from "./sundial";

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
import "bootstrap";

let csrf_token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
let live_socket = get_live_socket("/live", csrf_token);

// connect if there are any LiveViews on the page
live_socket.connect();

// expose live_socket on window for web console debug logs and latency simulation:
// >> live_socket.enableDebug()
// >> live_socket.enableLatencySim(1000)  // enabled for duration of browser session
// >> live_socket.disableLatencySim()
declare let window: LiveSocketWindow;
window.liveSocket = live_socket;

window.onload = () => {
  let svg = document.querySelector("svg#gravatar");
  if (svg instanceof SVGElement) {
    sundial.daemon(svg);
  }
  toc.guess_reading_time(200);
  toc.mark_headings([2, 3, 4, 5, 6]);
  blocks.mark_codeblocks();
  blocks.number_figures();
  music.set_jukebox();
  gallery.load_images();
};
