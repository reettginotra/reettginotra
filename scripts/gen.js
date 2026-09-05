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
  const dur = 20; // total duration 20s for infinite loop
  const typeTime = 2; // time to type
  const pauseTime = 2; // time to pause
  const deleteTime = 1; // time to delete
  
  const steps = lineLength;
  const vals = [];
  const kts = [];
  
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
  
  // hold empty for the rest of the 20s
  vals.push(0);
  kts.push(1);
  
  return {
    values: vals.join(';'),
    keyTimes: kts.join(';')
  };
}

function generateSvg(theme) {
  const isDark = theme === 'dark';
  
  const rectStroke = isDark ? "#334155" : "#CBD5E1";
  const rectStrokeOp = isDark ? "0.96" : "0.82";
  const featFill = "#14B8A6";
  const textFill = isDark ? "#E6EDF3" : "#0F172A";
  
  const height = 34.5;
  const rx = 17.25;
  
  let defs = '<defs>\n';
  let groups = '';
  
  const totalLines = lines.length;
  const durTotal = totalLines * 5; // 20s
  
  lines.forEach((line, index) => {
    const { values, keyTimes } = generateValues(line.length);
    const id = `clip-${index + 1}`;
    const beginTime = index * 5;
    
    // clip path
    defs += `    <clipPath id="${id}">
      <rect x="66" y="8" width="0" height="20">
        <animate attributeName="width" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${values}" keyTimes="${keyTimes}" fill="remove" />
      </rect>
    </clipPath>\n`;

    // Opacity needs to be 1 for first 4.6s (which is 0.23 of 20s), then 0 for 15.4s
    const gOpacityAnim = `<animate attributeName="opacity" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" values="1;1;0;0;0" keyTimes="0;0.23;0.23025;0.25;1" fill="remove" />`;
    
    const cursorValues = values.split(';').map(v => (66 + parseFloat(v)).toFixed(2)).join(';');
    
    groups += `
  <g opacity="0">
    ${gOpacityAnim}
    <rect x="66" y="10" width="1.5" height="15" rx="0.75" fill="${textFill}">
      <animate attributeName="x" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${cursorValues}" keyTimes="${keyTimes}" fill="remove" />
      <animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;0.49;0.5;0.99;1" dur="1s" repeatCount="indefinite" />
    </rect>
    <text x="66" y="22.7" fill="${textFill}" clip-path="url(#${id})" font-family="Fira Code, Cascadia Code, SFMono-Regular, Consolas, monospace" font-size="${fontSize}" font-weight="500">${line}</text>
  </g>`;
  });
  
  defs += '  </defs>';
  
  return `<svg xmlns="http://www.w3.org/2000/svg" width="360" height="36" viewBox="0 0 360 36" fill="none" role="img" aria-labelledby="title desc">
  <title id="title">Animated feat tagline</title>
  <desc id="desc">Outlined pill with a teal feat label and a typing-style rotation of four lines.</desc>
  ${defs}
  <rect x="0.75" y="0.75" width="358.5" height="33" rx="16.5" stroke="${rectStroke}" stroke-opacity="${rectStrokeOp}" stroke-width="1.5" fill="none" />
  <text x="16" y="22.7" fill="${featFill}" font-family="Fira Code, Cascadia Code, SFMono-Regular, Consolas, monospace" font-size="${fontSize}" font-weight="600">feat:</text>
  <line x1="52" y1="8" x2="52" y2="26.5" stroke="${rectStroke}" stroke-opacity="${rectStrokeOp}" stroke-width="1.2" />
  ${groups}
</svg>`;
}

fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill-light.svg'), generateSvg('light'));
fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill-dark.svg'), generateSvg('dark'));
fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill.svg'), generateSvg('light'));

console.log("SVGs generated.");
