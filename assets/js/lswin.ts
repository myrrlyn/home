// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view";

export interface LiveSocketWindow extends Window {
	liveSocket: LiveSocket;
}

export function get_live_socket(path, csrf_token) {
	return new LiveSocket(path, Socket, { params: { _csrf_token: csrf_token } });
}
