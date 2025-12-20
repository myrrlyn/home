export function set_jukebox() {
  console.groupCollapsed("music");
  for (let ident of ["intro", "outro"]) {
    let slot = document.getElementById(ident);
    if (slot === null) {
      continue;
    }
    // console.debug(`Found slot ${slot}`);
    let audio = document.getElementById(`${ident}-sound`);
    if (audio === null) {
      continue;
    }
    // console.debug(`Found audio ${audio}`);
    slot.parentNode?.replaceChild(audio, slot);
  }
  for (let audio of document.getElementsByTagName("audio")) {
    audio.onplay = pause_others;
  }
  console.groupEnd();
}

function pause_others(event: Event) {
  let src = event.target;
  for (let audio of document.getElementsByTagName("audio")) {
    if (audio == src) {
      continue;
    }
    audio.pause();
  }
}
