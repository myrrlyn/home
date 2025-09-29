export function daemon(group: SVGElement) {
  let face = group.getElementsByTagName("image")[0];
  let hands = group.getElementsByTagName("line");
  let hour_hand = hands.namedItem("hour");
  let minute_hand = hands.namedItem("minute");

  if (!face || !hour_hand || !minute_hand) {
    return;
  }
  let bgn = new Date();
  let next_minute = 60 - bgn.getSeconds();

  let dy = face.height.baseVal;
  dy.convertToSpecifiedUnits(SVGLength.SVG_LENGTHTYPE_PX);
  let ry = dy.valueInSpecifiedUnits / 2;

  let mhy0 = minute_hand.y1.baseVal;
  let mhy1 = minute_hand.y2.baseVal;
  mhy0.convertToSpecifiedUnits(dy.unitType);
  mhy1.convertToSpecifiedUnits(dy.unitType);
  let mhy = Math.abs(mhy0.valueInSpecifiedUnits - mhy1.valueInSpecifiedUnits);

  let ty = ry - mhy;

  // adjust immediately on entry
  adjust_hands(bgn, hour_hand, minute_hand, ty);
  // schedule at the top of the minute:
  setTimeout(() => {
    // schedule at the top of every minute from now on:
    setInterval(() => adjust_hands(new Date, hour_hand, minute_hand, ty), 60 * 1000);
    // then adjust hands once for the first top-of-minute after entry.
    adjust_hands(new Date, hour_hand, minute_hand, ty);
  }, next_minute * 1000);
}

function adjust_hands(date: Date, hour_hand: SVGLineElement, minute_hand: SVGLineElement, offset: number) {
  let hr_deg = hour_angle(date);
  let mn_deg = minute_angle(date);
  hour_hand.style.transform = `rotate(${hr_deg}deg) translateY(-${offset}px)`;
  minute_hand.style.transform = `rotate(${mn_deg}deg) translateY(-${offset}px)`;
}

function hour_angle(date: Date) {
  return (date.getHours() * 360 / 24) + (date.getMinutes() * 360 / (24 * 60));
}

function minute_angle(date: Date) {
  return date.getMinutes() * 360 / 60;
}
