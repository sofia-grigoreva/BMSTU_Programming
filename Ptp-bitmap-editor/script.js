tippy('[data-tippy-content]');

const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");
let w = (canvas.width = window.innerWidth * 0.9);
let h = (canvas.height = window.innerHeight * 0.6);

buttonlocation();

function updateCanvasSize(width, height) {
  w = width;
  h = height;
  canvas.width = width;
  canvas.height = height;
}

var Text = "";
var FontSize = 140;
var img = new Image();
var coefficient = 1;

const mouse = {
  x: 0,
  y: 0,
  x2: 0,
  y2: 0
};

const area = {
  x: 0,
  y: 0,
  x2: 0,
  y2: 0,
  h:0,
  w:0
};

const tools = {
  pen: "p",
  rect: "r",
  line: "l",
  circle: "c",
  eraser: "e",
  ellipse: "el",
  tr: "t",
  text: "pt",
  image: "pi",
  heart: "h",
  square: "sq",
  prtr: "pr",
  star4: "s4",
  star5: "s5",
  star6: "s6",
  spray: "s",
  fill: "f",
  moon: "m",
  allocation1: "a1",
  allocation2: "a2"
};

let snapshot = null;
let isdrawing = false;

let undoStack = [];
let redoStack = [];

let curtool = tools.pen;
ctx.strokeStyle = colorPicker.value;
ctx.lineWidth = lineWidth.value;

function getCoordinates(event) {
  event.preventDefault();
  const scale = zoomRange.value / 100;
  if (event.touches) {
    const { clientX, clientY } = event.touches[0];
    return {
      x: (clientX - canvas.offsetLeft) / scale,
      y: (clientY - canvas.offsetTop) / scale
    };
  }
  return {
    x: event.offsetX,
    y: event.offsetY
  };
}

function startdraw(event) {
  isdrawing = true;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  const { x, y } = getCoordinates(event);
  mouse.x = x;
  mouse.y = y;
  if (dash){
    ctx.setLineDash([13, 30]);
  } else {
    ctx.setLineDash([0, 0]);
  }
  ctx.strokeStyle = colorPicker.value;
  ctx.lineWidth = lineWidth.value;
  ctx.fillStyle  = colorPicker.value;
  ctx.globalAlpha = 1 - transparency.value;
  ctx.beginPath();
  undoStack.push(ctx.getImageData(0, 0, w, h));
  redoStack = [];
  if (curtool == tools.fill) {
    floodFill(event);
  } else if (curtool == tools.text) {
    ctx.font = FontSize.toString()+'px serif';
    ctx.fillStyle = ctx.strokeStyle;
    TextWidth = ctx.measureText(Text).width / 2;
    ctx.fillText(Text, mouse.x - TextWidth, mouse.y);
  } else if (curtool == tools.image) {
      ctx.drawImage(img, mouse.x , mouse.y, img.width * coefficient , img.height * coefficient);
  }
  
  if (curtool == tools.allocation2 && ((mouse.x < area.x || mouse.x > area.x2) || (mouse.y < area.y || mouse.y > area.y2))){
    curtool = tools.allocation1;
    ctx.putImageData(snapshot3, 0, 0);
  }
  
  if (curtool == tools.allocation2){
    ctx.clearRect(area.x - 2, area.y - 2, Math.abs(area.x2 - area.x) + 4, Math.abs(area.y2 - area.y) + 4);
    snapshot = ctx.getImageData(0, 0, w, h);
  }
  snapshot = ctx.getImageData(0, 0, w, h);
}


function draw(event) {
  if (!isdrawing) return;
  if (curtool === tools.pen) {
    drawpen(event);
  } else if (curtool == tools.rect) {
    drawrect(event);
  } else if (curtool == tools.line) {
    drawline(event);
  } else if (curtool == tools.eraser) {
    erase(event);
  } else if (curtool == tools.circle) {
    drawcircle(event);
  } else if (curtool == tools.ellipse) {
    drawellipse(event);
  } else if (curtool == tools.tr) {
    drawtr(event);
  } else if (curtool == tools.heart) {
    drawheart(event);
  } else if (curtool == tools.square) {
    drawsquare(event);
  } else if (curtool == tools.prtr) {
    drawprtr(event);
  } else if (curtool == tools.star4) {
    drawstar(event, 4);
  } else if (curtool == tools.star5) {
    drawstar(event, 5);
  } else if (curtool == tools.star6) {
    drawstar(event, 6);
  } else if (curtool == tools.spray) {
    drawspray(event);
  } else if (curtool == tools.moon) {
    drawmoon(event);
  } else if (curtool == tools.allocation1){
    allocation1(event);
  } else if (curtool == tools.allocation2){
    allocation2(event);
  }
}

function finishdraw(event) {
  if (curtool == tools.allocation1){
     snapshot2 = ctx.getImageData(0, 0, w, h);
     ctx.putImageData(snapshot, 0, 0);
     area.x = Math.min(mouse.x2, mouse.x);
     area.y = Math.min(mouse.y2, mouse.y);
     area.x2 = Math.max(mouse.x2, mouse.x);
     area.y2 = Math.max(mouse.y2, mouse.y);
     area.h = Math.abs(mouse.y2 - mouse.y);
     area.w = Math.abs(mouse.x2 - mouse.x);
     picture = ctx.getImageData(mouse.x - 2, mouse.y - 2, Math.abs(mouse.x2 - mouse.x), Math.abs(mouse.y2 - mouse.y));
     ctx.putImageData(snapshot2, 0, 0);
     curtool = tools.allocation2;
  } else if (curtool == tools.allocation2){
     ctx.putImageData(snapshot3, 0, 0);
     curtool = tools.allocation1;
  }
  isdrawing = false;
  ctx.closePath();
  ctx.globalCompositeOperation = "source-over";
}

canvas.addEventListener("mousemove", draw);
canvas.addEventListener("mousedown", startdraw);
window.addEventListener("mouseup", finishdraw);

canvas.addEventListener('touchstart', startdraw);
canvas.addEventListener('touchmove', draw);
canvas.addEventListener('touchend', finishdraw);
