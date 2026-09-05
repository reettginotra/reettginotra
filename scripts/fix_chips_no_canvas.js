const fs = require('fs');
const path = require('path');

const chips = [
  {
    prefix: 'chip-problems',
    measuredWidth: 201, // measured via python tkinter font at size 13.2 weight 600
    textStartX: 34,
    rightPadding: 16
  },
  {
    prefix: 'chip-stack',
    measuredWidth: 136,
    textStartX: 18,
    rightPadding: 16
  },
  {
    prefix: 'chip-pronouns',
    measuredWidth: 56,
    textStartX: 18,
    rightPadding: 16
  }
];

chips.forEach(chip => {
  const totalWidth = chip.textStartX + chip.measuredWidth + chip.rightPadding;
  const rectWidth = totalWidth - 1.5;

  ['light', 'dark'].forEach(theme => {
    const filename = `${chip.prefix}-${theme}.svg`;
    const filepath = path.join(__dirname, '../assets', filename);
    
    if (fs.existsSync(filepath)) {
      let content = fs.readFileSync(filepath, 'utf-8');
      
      // Update viewBox
      content = content.replace(/viewBox="0 0 [\d\.]+ 36"/, `viewBox="0 0 ${totalWidth} 36"`);
      // Update svg width
      content = content.replace(/<svg(.*?)width="[\d\.]+"(.*?)>/, `<svg$1width="${totalWidth}"$2>`);
      // Update rect width
      content = content.replace(/<rect(.*?)width="[\d\.]+"(.*?)>/, `<rect$1width="${rectWidth}"$2>`);
      
      fs.writeFileSync(filepath, content);
      console.log(`Updated ${filename} to width ${totalWidth}`);
    }
  });
});
