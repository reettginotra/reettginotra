const fs = require('fs');
const path = require('path');

const charWidth = 7.92;
const fontSize = 13.2;

const lines = [
  "love building fintech tools",
  "turning ideas into shipped products",
  "open to weird, ambitious problems",
  "currently deep in AI + product work"
];

function generateValues(lineLength, maxLineLength, offset = 0) {
  const dur = 5; // seconds
  const typeTime = 2; // time to type
  const pauseTime = 2; // time to pause
  const deleteTime = 1; // time to delete
  
  const steps = lineLength;
  const values = [];
  const keyTimes = [];
  
  // typing
  for (let i = 0; i <= steps; i++) {
    values.push((i * charWidth).toFixed(1));
    keyTimes.push((i / steps * (typeTime / dur)).toFixed(4));
  }
  
  // pause
  values.push((steps * charWidth).toFixed(1));
  keyTimes.push(((typeTime + pauseTime) / dur).toFixed(4));
  
  // deleting
  for (let i = steps; i >= 0; i--) {
    values.push((i * charWidth).toFixed(1));
    keyTimes.push((1 - (i / steps * (deleteTime / dur))).toFixed(4));
  }
  
  // padding to max duration if needed, actually SMIL animate handles this with discrete if we pad
  // wait, the keyTimes must be strictly increasing. 
  // Let's ensure strictly increasing keyTimes:
  let kts = [];
  let vals = [];
  
  let time = 0;
  // start empty
  vals.push(0);
  kts.push(0);
  
  // type
  for(let i = 1; i <= steps; i++) {
    time = (i / steps) * (typeTime / dur);
    vals.push((i * charWidth).toFixed(2));
    kts.push(time.toFixed(4));
  }
  // pause
  time = (typeTime + pauseTime) / dur;
  vals.push((steps * charWidth).toFixed(2));
  kts.push(time.toFixed(4));
  
  // delete
  for(let i = steps - 1; i >= 0; i--) {
    let delProgress = (steps - i) / steps;
    time = ((typeTime + pauseTime) / dur) + delProgress * (deleteTime / dur);
    vals.push((i * charWidth).toFixed(2));
    kts.push(time.toFixed(4));
  }
  
  // force last to be 1
  kts[kts.length - 1] = 1;
  
  return {
    values: vals.join(';'),
    keyTimes: kts.join(';')
  };
}

function generateSvg(theme) {
  const isDark = theme === 'dark';
  
  // Colors based on chips-row-light vs tagline-pill-light
  // Chips light: fill="none", stroke="#38BDF8" (wait, chips have rect fill "#7DD3FC" opacity 0.14)
  // Let's use the pill colors from before, but adjust height
  // In light theme previous tagline-pill:
  // Rect: stroke="#CBD5E1" stroke-opacity="0.82" stroke-width="1.4"
  // text "feat:": fill="#14B8A6"
  // text typing: fill="#0F172A"
  // cursor: fill="#0F172A"
  
  // Dark theme previous:
  // Rect: stroke="#334155" stroke-opacity="0.96" stroke-width="1.4"
  // text "feat:": fill="#14B8A6"
  // text typing: fill="#E6EDF3"
  // cursor: fill="#E6EDF3"

  const rectStroke = isDark ? "#334155" : "#CBD5E1";
  const rectStrokeOp = isDark ? "0.96" : "0.82";
  const featFill = "#14B8A6";
  const textFill = isDark ? "#E6EDF3" : "#0F172A";
  
  const height = 34.5;
  const rx = 17.25;
  
  let defs = '<defs>\n';
  let groups = '';
  
  lines.forEach((line, index) => {
    const { values, keyTimes } = generateValues(line.length);
    const id = `clip-${index + 1}`;
    const beginTime = index * 5; // 5s per line
    const totalLines = lines.length;
    const durTotal = totalLines * 5;
    
    // clip path
    defs += `    <clipPath id="${id}">
      <rect x="66" y="8" width="0" height="20">
        <animate attributeName="width" begin="${beginTime}s;${beginTime + durTotal}s" dur="5s" calcMode="discrete" values="${values}" keyTimes="${keyTimes}" fill="remove" />
      </rect>
    </clipPath>\n`;

    const gOpacityAnim = `<animate attributeName="opacity" begin="${beginTime}s;${beginTime + durTotal}s" dur="5s" values="1;1;0;0" keyTimes="0;0.92;0.921;1" fill="remove" />`;
    
    // We animate the x of the group to center it? Wait, the original animated the group's transform to center it depending on text length!
    // Original: <animateTransform attributeName="transform" type="translate" ... >
    // Let's check how much to translate.
    // The pill width needs to animate as well.
    // Original pill width animates from 74 up to 74 + textWidth.
    // Let's animate the rect width.
    const rectValues = values.split(';').map(v => (74 + parseFloat(v)).toFixed(2)).join(';');
    
    // The group translate X animates to keep the pill centered.
    // The pill is in a viewBox 0 0 320 44 (or 36 now). Center is 160.
    // Pill starts at width 74, so center of pill is at 37. To center pill in viewBox, we translate by (320/2) - (currentWidth/2).
    // Original had group transform! Let's do the same.
    const transformValues = values.split(';').map(v => {
      const w = 74 + parseFloat(v);
      const tx = 160 - (w / 2);
      return `${tx.toFixed(2)} 1`;
    }).join(';');
    
    const cursorValues = values.split(';').map(v => (66 + parseFloat(v)).toFixed(2)).join(';');
    
    groups += `
  <g opacity="0" transform="translate(123 1)">
    ${gOpacityAnim}
    <animateTransform attributeName="transform" type="translate" begin="${beginTime}s;${beginTime + durTotal}s" dur="5s" calcMode="discrete" values="${transformValues}" keyTimes="${keyTimes}" fill="remove" />
    <rect width="74" height="${height}" rx="${rx}" stroke="${rectStroke}" stroke-opacity="${rectStrokeOp}" stroke-width="1.4">
      <animate attributeName="width" begin="${beginTime}s;${beginTime + durTotal}s" dur="5s" calcMode="discrete" values="${rectValues}" keyTimes="${keyTimes}" fill="remove" />
    </rect>
    <text x="16" y="22.7" fill="${featFill}" font-family="Fira Code, Cascadia Code, SFMono-Regular, Consolas, monospace" font-size="${fontSize}" font-weight="600">feat:</text>
    <line x1="52" y1="8" x2="52" y2="26.5" stroke="${rectStroke}" stroke-opacity="${rectStrokeOp}" stroke-width="1.2" />
    <rect x="66" y="10" width="1.5" height="15" rx="0.75" fill="${textFill}">
      <animate attributeName="x" begin="${beginTime}s;${beginTime + durTotal}s" dur="5s" calcMode="discrete" values="${cursorValues}" keyTimes="${keyTimes}" fill="remove" />
      <animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;0.49;0.5;0.99;1" dur="1s" repeatCount="indefinite" />
    </rect>
    <text x="66" y="22.7" fill="${textFill}" clip-path="url(#${id})" font-family="Fira Code, Cascadia Code, SFMono-Regular, Consolas, monospace" font-size="${fontSize}" font-weight="500">${line}</text>
  </g>`;
  });
  
  defs += '  </defs>';
  
  return `<svg xmlns="http://www.w3.org/2000/svg" width="320" height="36" viewBox="0 0 320 36" fill="none" role="img" aria-labelledby="title desc">
  <title id="title">Animated feat tagline</title>
  <desc id="desc">Outlined pill with a teal feat label and a typing-style rotation of four lines.</desc>
  ${defs}${groups}
</svg>`;
}

fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill-light.svg'), generateSvg('light'));
fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill-dark.svg'), generateSvg('dark'));
fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill.svg'), generateSvg('light'));

console.log("SVGs generated.");
