export function load_images() {
  console.group("loading images");
  let elems = Array.from(document.getElementsByClassName("async-image"))
    .map((elem) => elem as HTMLElement)
    .reverse();

  setTimeout(() => load_one(elems), 20);
  setTimeout(() => load_one(elems), 15);
  setTimeout(() => load_one(elems), 10);
  setTimeout(() => load_one(elems), 5);
  console.groupEnd();
}

function load_one(elems: Array<HTMLElement>) {
  let elem = elems.pop();
  if (elem === undefined) {
    return;
  }
  let image = new Image();
  image.classList.add("unset", "gallery-img");
  let title = elem.dataset.title;
  let source = elem.dataset.src;
  if (title) {
    image.alt = title;
  }
  image.onload = () => {
    elem?.replaceWith(image);
    load_one(elems);
  };
  if (source) {
    image.src = source;
  }
}
