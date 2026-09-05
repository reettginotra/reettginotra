const fs = require('fs');
const path = require('path');

const widths = {
  problems: { total: 251, rect: 249.5 },
  stack: { total: 170, rect: 168.5 },
  pronouns: { total: 90, rect: 88.5 }
};

const gap = 10;
const transStack = widths.problems.total + gap; // 251 + 10 = 261
const transPronouns = transStack + widths.stack.total + gap; // 261 + 170 + 10 = 441
const totalRowWidth = transPronouns + widths.pronouns.total; // 441 + 90 = 531

['chips-row-light.svg', 'chips-row-dark.svg', 'chips-row.svg'].forEach(filename => {
  const filepath = path.join(__dirname, '../assets', filename);
  if (fs.existsSync(filepath)) {
    let content = fs.readFileSync(filepath, 'utf-8');
    
    // Update SVG viewBox and width
    content = content.replace(/viewBox="0 0 [\d\.]+ 36"/, `viewBox="0 0 ${totalRowWidth} 36"`);
    content = content.replace(/<svg(.*?)width="[\d\.]+"(.*?)>/, `<svg$1width="${totalRowWidth}"$2>`);
    
    // Update Chip 1 rect width
    // Match the first rect in the file (which belongs to chip 1)
    content = content.replace(/<rect x="0\.75" y="0\.75" width="[\d\.]+"/, `<rect x="0.75" y="0.75" width="${widths.problems.rect}"`);
    
    // Update Chip 2 transform and rect width
    content = content.replace(/<g transform="translate\([\d\.]+ 0\)">/, `<g transform="translate(${transStack} 0)">`);
    // Wait, regex might match any. Let's be specific.
    // Instead of regex for the second and third rects, let's just use string replace.
    // Actually, I can use a simpler approach. We know the original values.
    // Original Chip 1 rect: width="298.5"
    // Original Chip 2 rect: width="174.5"
    // Original Chip 3 rect: width="86.5"
    // Original Chip 2 transform: translate(310 0)
    // Original Chip 3 transform: translate(496 0)
    
    content = content.replace('width="298.5"', `width="${widths.problems.rect}"`);
    content = content.replace('width="174.5"', `width="${widths.stack.rect}"`);
    content = content.replace('width="86.5"', `width="${widths.pronouns.rect}"`);
    content = content.replace('translate(310 0)', `translate(${transStack} 0)`);
    content = content.replace('translate(496 0)', `translate(${transPronouns} 0)`);
    
    fs.writeFileSync(filepath, content);
    console.log(`Updated ${filename} to width ${totalRowWidth}`);
  }
});
