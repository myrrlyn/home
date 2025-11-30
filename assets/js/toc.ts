/// Encloses `<hN>` text with a preceding-sibling link and enclosing span.
///
/// The link is a section-symbol targeting its own heading. The span allows the
/// CSS engine to target the heading display for numbering.
export function mark_headings(ranks: Array<number>) {
  // TODO(myrrlyn): Figure out how to make this server-side.
  console.group("headings")
  for (let num of ranks) {
    let sel = `main article h${num}:not(.no-toc)`;
    for (let hed of document.querySelectorAll(sel)) {
      let inner = hed.innerHTML;
      let id = hed.id;
      if (id === "") {
        continue;
      }
      console.log(`marking h${num} "${inner}"`)
      hed.innerHTML = `<a href="#${hed.id}" class="mark-ss">§</a><span>${inner}</span>`;
    }
  }
  console.groupEnd();
}

/// Vaguely counts the number of words in an article, then vaguely guesses
/// reading time from that count.
export function guess_reading_time(words_per_minute: number) {
  var words = 0;
  // Nearly all Markdown text gets shoved in a `<p>` element at some point. Not
  // all, though! Lists don't have to make them, for example. Codeblocks also
  // aren't in `<p>`, but codeblocks also read WAY faster than prose, so they're
  // basically skippable.
  for (var para of document.querySelectorAll("main article p")) {
    words += (para as HTMLElement).innerText.trim().split(/\s+/).length;
  }
  let time = Math.ceil(words / words_per_minute);
  let span = document.getElementById("reading-time");
  if (span !== null) {
    span.innerText = `${time} minutes`;
  }
}
