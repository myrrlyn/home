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
import { mark_codeblocks } from "./codeblocks";
import { load_images } from "./image_loader";
import { set_jukebox } from "./jukebox";
import { LiveSocketWindow, get_live_socket } from "./lswin";
import { mark_headings } from "./toc";

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

function guess_reading_time() {
  var words = 0;
  for (var para of document.querySelectorAll("main article p")) {
    words += (para as HTMLElement).innerText.trim().split(/\s+/).length;
  }
  let time = Math.ceil(words / 200);
  let span = document.getElementById("reading-time");
  if (span !== null) {
    span.innerText = `${time} minutes`;
  }
}

function number_figures() {
  var counter = 0;
  for (let fig of document.querySelectorAll("main article figure")) {
    counter += 1;
    if (fig.id == "") {
      fig.id = `fig-${counter}`;
    }
    if (fig.querySelector("figcaption") === null) {
      fig.appendChild(document.createElement("figcaption"));
    }
  }
}

window.onload = () => {
  mark_headings([2, 3, 4, 5, 6]);
  mark_codeblocks();
  number_figures();
  guess_reading_time();
  set_jukebox();
  load_images();
};
