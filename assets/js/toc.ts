// TODO(myrrlyn): Figure out how to make this server-side.
export function mark_headings(ranks: Array<number>) {
	for (let num of ranks) {
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
