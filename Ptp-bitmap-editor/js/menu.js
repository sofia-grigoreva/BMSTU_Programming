const toolsbtn = document.getElementById('toolsBtn');
const colorsbtn = document.getElementById('colorsBtn');
const figuresbtn = document.getElementById('figuresBtn');
const stylebtn = document.getElementById('styleBtn');

const color = document.getElementById('colors');
const tool = document.getElementById('tools');
const figures = document.getElementById('figures');
const style = document.getElementById('styles');


const line = document.getElementById('secondline');

const menus = {
  colors: 'none',
  tools: 'none',
  figures: 'none',
  style: 'none'
};

let binterval = (window.innerWidth - 40 - 130 * 4) / 3;

function buttonlocation() {
  binterval = (window.innerWidth - 40 - 130 * 4) / 3;
  stylebtn.style.left = 20 + 130 + binterval  + 'px';
  figuresbtn.style.left = 20 + 260 + binterval * 2 + 'px';
  colorsbtn.style.left = 20 + 390 + binterval * 3 + 'px';
}


colorsbtn.addEventListener('click', () => {
  if (menus.colors == 'flex'){
    color.style.display = 'none';
    menus.colors = 'none';
  } else {
    color.style.display = 'flex';
    figures.style.display = 'none';
    style.style.display = 'none';
    tool.style.display = 'none';
    menus.colors = 'flex';
    menus.tools = 'none';
    menus.style = 'none';
    menus.figures = 'none';
  }
});


toolsbtn.addEventListener('click', () => {
  if (menus.tools == 'flex'){
    tool.style.display = 'none';
    menus.tools = 'none';
  } else {
    tool.style.display = 'flex';
    figures.style.display = 'none';
    style.style.display = 'none';
    color.style.display = 'none';
     menus.tools = 'flex';
    menus.style = 'none';
    menus.colors = 'none';
    menus.figures = 'none';
  }
});


figuresbtn.addEventListener('click', () => {
  if (menus.figures == 'flex'){
    figures.style.display = 'none';
    menus.figures = 'none';
  } else {
    figures.style.display = 'flex';
    style.style.display = 'none';
    tool.style.display = 'none';
    color.style.display = 'none';
    menus.figures = 'flex';
    menus.tools = 'none';
    menus.style = 'none';
    menus.colors = 'none';
  }
});


stylebtn.addEventListener('click', () => {
  if (menus.style == 'flex'){
    style.style.display = 'none';
    menus.style = 'none';
  } else {
    style.style.display = 'flex';
    figures.style.display = 'none';
    tool.style.display = 'none';
    color.style.display = 'none';
    menus.style = 'flex';
    menus.tools = 'none';
    menus.colors = 'none';
    menus.figures = 'none';
  }
});

window.addEventListener('resize', (e) => {
  const windowWidth = window.innerWidth;
  if (windowWidth > 1160) {
    style.style.display = 'flex';
    figures.style.display = 'flex';
    tool.style.display = 'flex';
    color.style.display = 'flex';
    menus.style = 'none';
    menus.tools = 'none';
    menus.colors = 'none';
    menus.figures = 'none';
  } else {
    buttonlocation();
    style.style.display = menus.style;
    figures.style.display = menus.figures;
    tool.style.display = menus.tools;
    color.style.display = menus.colors;
  }
}); 
