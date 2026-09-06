const fs = require('fs');
const path = require('path');

const charWidth = 7.92;
const fontSize = 13.2;
const textStartX = 66;
const svgWidth = 540;
const outerRectX = 0.75;
const outerRectY = 0.75;
const outerRectHeight = 33;
const outerRectRx = 16.5;
const pillCenterX = svgWidth / 2;
const rightPadding = 16.05;
const typeTime = 2;
const pauseTime = 2;
const deleteTime = 1;
const lineDuration = typeTime + pauseTime + deleteTime;
const featInset = 15.25;
const dividerInset = 51.25;
const textInset = 65.25;

const lines = [
  "love building fintech tools",
  "turning ideas into shipped products",
  "open to weird, ambitious problems",
  "currently deep in AI + product work"
];

function getOuterWidth(visibleWidth) {
  return textInset + rightPadding + visibleWidth;
}

function getOuterX(visibleWidth) {
  return pillCenterX - getOuterWidth(visibleWidth) / 2;
}

function getFeatX(visibleWidth) {
  return getOuterX(visibleWidth) + featInset;
}

function getDividerX(visibleWidth) {
  return getOuterX(visibleWidth) + dividerInset;
}

function getTextX(visibleWidth) {
  return getOuterX(visibleWidth) + textInset;
}

function generateFrames(lineLength) {
  const dur = lines.length * lineDuration;
  
  const steps = lineLength;
  const widths = [];
  const kts = [];
  
  let time = 0;
  // start empty
  widths.push(0);
  kts.push(0);
  
  // type
  for(let i = 1; i <= steps; i++) {
    time = (i / steps) * (typeTime / dur);
    widths.push(i * charWidth);
    kts.push(time.toFixed(4));
  }
  // pause
  time = (typeTime + pauseTime) / dur;
  widths.push(steps * charWidth);
  kts.push(time.toFixed(4));
  
  // delete
  for(let i = steps - 1; i >= 0; i--) {
    let delProgress = (steps - i) / steps;
    time = ((typeTime + pauseTime) / dur) + delProgress * (deleteTime / dur);
    widths.push(i * charWidth);
    kts.push(time.toFixed(4));
  }
  
  // hold empty for the rest of the full loop
  widths.push(0);
  kts.push(1);

  return {
    widths,
    keyTimes: kts
  };
}

function formatAnimation(values, keyTimes) {
  return {
    values: values.map((value) => value.toFixed(2)).join(';'),
    keyTimes: keyTimes.join(';')
  };
}

function generateValues(lineLength) {
  const { widths, keyTimes } = generateFrames(lineLength);
  
  return {
    values: widths.map((width) => width.toFixed(2)).join(';'),
    keyTimes: keyTimes.join(';')
  };
}

function generateLoopFrames() {
  const totalDuration = lines.length * lineDuration;
  const widths = [0];
  const kts = ['0'];

  lines.forEach((line, index) => {
    const steps = line.length;
    const segmentStart = index * lineDuration;

    for (let i = 1; i <= steps; i++) {
      const time = (segmentStart + (i / steps) * typeTime) / totalDuration;
      widths.push(i * charWidth);
      kts.push(time.toFixed(4));
    }

    widths.push(steps * charWidth);
    kts.push(((segmentStart + typeTime + pauseTime) / totalDuration).toFixed(4));

    for (let i = steps - 1; i >= 0; i--) {
      const delProgress = (steps - i) / steps;
      const time = (segmentStart + typeTime + pauseTime + delProgress * deleteTime) / totalDuration;
      widths.push(i * charWidth);
      kts.push(time.toFixed(4));
    }
  });

  return {
    widths,
    keyTimes: kts
  };
}

function generateOuterWidthAnimation() {
  const { widths, keyTimes } = generateLoopFrames();

  return formatAnimation(
    widths.map((width) => getOuterWidth(width)),
    keyTimes
  );
}

function generateOuterXAnimation() {
  const { widths, keyTimes } = generateLoopFrames();

  return formatAnimation(
    widths.map((width) => getOuterX(width)),
    keyTimes
  );
}

function generateSvg(theme) {
  const isDark = theme === 'dark';
  
  const rectStroke = isDark ? "#334155" : "#CBD5E1";
  const rectStrokeOp = isDark ? "0.96" : "0.82";
  const featFill = "#14B8A6";
  const textFill = isDark ? "#E6EDF3" : "#0F172A";
  
  const { widths: loopWidths, keyTimes: loopKeyTimes } = generateLoopFrames();
  const { values: outerXValues, keyTimes: outerXKeyTimes } = generateOuterXAnimation();
  const { values: outerWidthValues, keyTimes: outerWidthKeyTimes } = generateOuterWidthAnimation();
  const { values: featAnimationValues, keyTimes: featAnimationKeyTimes } = formatAnimation(
    loopWidths.map((width) => getFeatX(width)),
    loopKeyTimes
  );
  const { values: dividerAnimationValues, keyTimes: dividerAnimationKeyTimes } = formatAnimation(
    loopWidths.map((width) => getDividerX(width)),
    loopKeyTimes
  );
  
  let defs = '<defs>\n';
  let groups = '';
  
  const totalLines = lines.length;
  const durTotal = totalLines * lineDuration;
  
  lines.forEach((line, index) => {
    const { widths, keyTimes } = generateFrames(line.length);
    const { values, keyTimes: localKeyTimes } = formatAnimation(widths, keyTimes);
    const clipXValues = widths.map((width) => getTextX(width));
    const textXValues = clipXValues;
    const cursorValues = widths.map((width) => getTextX(width) + width);
    const {
      values: clipXAnimationValues
    } = formatAnimation(clipXValues, keyTimes);
    const {
      values: textXAnimationValues
    } = formatAnimation(textXValues, keyTimes);
    const {
      values: cursorAnimationValues
    } = formatAnimation(cursorValues, keyTimes);
    const id = `clip-${index + 1}`;
    const beginTime = index * lineDuration;
    
    // clip path
    defs += `    <clipPath id="${id}">
      <rect x="${textStartX}" y="8" width="0" height="20">
        <animate attributeName="x" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${clipXAnimationValues}" keyTimes="${localKeyTimes}" fill="remove" />
        <animate attributeName="width" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${values}" keyTimes="${localKeyTimes}" fill="remove" />
      </rect>
    </clipPath>\n`;

    // Opacity needs to be 1 for first 4.6s (which is 0.23 of 20s), then 0 for 15.4s
    const gOpacityAnim = `<animate attributeName="opacity" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" values="1;1;0;0;0" keyTimes="0;0.23;0.23025;0.25;1" fill="remove" />`;
    
    groups += `
  <g opacity="0">
    ${gOpacityAnim}
    <rect x="${textStartX}" y="10" width="1.5" height="15" rx="0.75" fill="${textFill}">
      <animate attributeName="x" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${cursorAnimationValues}" keyTimes="${localKeyTimes}" fill="remove" />
      <animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;0.49;0.5;0.99;1" dur="1s" repeatCount="indefinite" />
    </rect>
    <text x="${textStartX}" y="22.7" fill="${textFill}" clip-path="url(#${id})" font-family="Fira Code, Cascadia Code, SFMono-Regular, Consolas, monospace" font-size="${fontSize}" font-weight="500">
      <animate attributeName="x" begin="${beginTime}s" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${textXAnimationValues}" keyTimes="${localKeyTimes}" fill="remove" />
      ${line}
    </text>
  </g>`;
  });
  
  defs += '  </defs>';
  
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${svgWidth}" height="36" viewBox="0 0 ${svgWidth} 36" fill="none" role="img" aria-labelledby="title desc">
  <title id="title">Animated feat tagline</title>
  <desc id="desc">Outlined pill with a teal feat label and a typing-style rotation of four lines.</desc>
  ${defs}
  <rect x="${getOuterX(0).toFixed(2)}" y="${outerRectY}" width="${getOuterWidth(0).toFixed(2)}" height="${outerRectHeight}" rx="${outerRectRx}" stroke="${rectStroke}" stroke-opacity="${rectStrokeOp}" stroke-width="1.5" fill="none">
    <animate attributeName="x" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${outerXValues}" keyTimes="${outerXKeyTimes}" />
    <animate attributeName="width" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${outerWidthValues}" keyTimes="${outerWidthKeyTimes}" />
  </rect>
  <text x="${getFeatX(0).toFixed(2)}" y="22.7" fill="${featFill}" font-family="Fira Code, Cascadia Code, SFMono-Regular, Consolas, monospace" font-size="${fontSize}" font-weight="600">
    <animate attributeName="x" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${featAnimationValues}" keyTimes="${featAnimationKeyTimes}" />
    feat:
  </text>
  <line x1="${getDividerX(0).toFixed(2)}" y1="8" x2="${getDividerX(0).toFixed(2)}" y2="26.5" stroke="${rectStroke}" stroke-opacity="${rectStrokeOp}" stroke-width="1.2">
    <animate attributeName="x1" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${dividerAnimationValues}" keyTimes="${dividerAnimationKeyTimes}" />
    <animate attributeName="x2" dur="${durTotal}s" repeatCount="indefinite" calcMode="discrete" values="${dividerAnimationValues}" keyTimes="${dividerAnimationKeyTimes}" />
  </line>
  ${groups}
</svg>`;
}

fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill-light.svg'), generateSvg('light'));
fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill-dark.svg'), generateSvg('dark'));
fs.writeFileSync(path.join(__dirname, '../assets/tagline-pill.svg'), generateSvg('light'));

console.log("SVGs generated.");
