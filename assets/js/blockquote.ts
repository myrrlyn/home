export function cite_blockquotes() {
  for (var node of document.querySelectorAll("article blockquote[cite]")) {
    let src = node.getAttribute("cite");
    // We know this never enters.
    if (src === null) {
      continue;
    }
    let citation = document.createElement("figcaption");
    citation.classList.add("bq-citation");
    citation.innerHTML = `—<a href="${src}">Source</a>`;

    let wrapper = document.createElement("figure");
    wrapper.classList.add("bq-cited");
    node.replaceWith(wrapper);
    wrapper.appendChild(node);
    wrapper.appendChild(citation);
  }
}
