//Line -----------------------------------------------------------------------------
const linebtn = document.getElementById("lineBtn");

linebtn.addEventListener("click", () => {
  curtool = tools.line;
});

function drawline(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  ctx.moveTo(mouse.x, mouse.y);
  const { x, y } = getCoordinates(event);
  ctx.lineTo(x, y);
  ctx.stroke();
}

//Rectangle ------------------------------------------------------------------------
const rectbtn = document.getElementById("rectBtn");

rectbtn.addEventListener("click", () => {
  curtool = tools.rect;
});

function drawrect(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let x1 = Math.min(mouse.x2, mouse.x);
  let y1 = Math.min(mouse.y2, mouse.y);
  ctx.moveTo(x1, y1);
  ctx.lineTo(x1, y1 + Math.abs(mouse.y2 - mouse.y));
  ctx.lineTo(x1 + Math.abs(mouse.x2 - mouse.x), y1 + Math.abs(mouse.y2 - mouse.y));
  ctx.lineTo(x1 + Math.abs(mouse.x2 - mouse.x), y1);
  ctx.lineTo(x1, y1);
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}


//Square ---------------------------------------------------------------------------
const squarebtn = document.getElementById("squareBtn");

squarebtn.addEventListener("click", () => {
  curtool = tools.square;
});

function drawsquare(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let r = Math.min(Math.abs(mouse.y2 - mouse.y), Math.abs(mouse.x2 - mouse.x));
  let x1 = mouse.x;
  let y1 = mouse.y;
  if (mouse.x > mouse.x2) {
    x1 = x1 - r;
  }
  if (mouse.y > mouse.y2) {
    y1 = y1 - r;
  }
  ctx.moveTo(x1, y1);
  ctx.lineTo(x1, y1 + r);
  ctx.lineTo(x1 + r, y1 + r);
  ctx.lineTo(x1 + r, y1);
  ctx.lineTo(x1, y1);
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}

//Circle ---------------------------------------------------------------------------
const circlebtn = document.getElementById("circleBtn");

circlebtn.addEventListener("click", () => {
  curtool = tools.circle;
});

function drawcircle(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let r = Math.min(Math.abs(mouse.y2 - mouse.y), Math.abs(mouse.x2 - mouse.x)) / 2;
  let x1 = mouse.x + r;
  let y1 = mouse.y + r;
  if (mouse.x > mouse.x2) {
    x1 = x1 - r * 2;
  }
  if (mouse.y > mouse.y2) {
    y1 = y1 - r * 2;
  }
  ctx.arc(x1, y1, r, 0, Math.PI * 2, false);
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}

//Triangle -------------------------------------------------------------------------
const trbtn = document.getElementById("trBtn");

trbtn.addEventListener("click", () => {
  curtool = tools.tr;
});

function drawtr(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let x1 = Math.min(mouse.x2, mouse.x);
  ctx.moveTo(mouse.x2, mouse.y2);
  ctx.lineTo(mouse.x, mouse.y2);
  ctx.lineTo(Math.abs(mouse.x2 - mouse.x) / 2 + x1, mouse.y);
  ctx.lineTo(mouse.x2, mouse.y2);
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}

//Right Triangle -------------------------------------------------------------------
const prtrbtn = document.getElementById("prtrBtn");

prtrbtn.addEventListener("click", () => {
  curtool = tools.prtr;
});

function drawprtr(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  ctx.moveTo(mouse.x2, mouse.y2);
  ctx.lineTo(mouse.x, mouse.y2);
  ctx.lineTo(mouse.x, mouse.y);
  ctx.lineTo(mouse.x2, mouse.y2);
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}

//Ellipse --------------------------------------------------------------------------
const ellipsebtn = document.getElementById("ellipseBtn");

ellipsebtn.addEventListener("click", () => {
  curtool = tools.ellipse;
});

function drawellipse(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let x1 = Math.min(mouse.x2, mouse.x);
  let y1 = Math.min(mouse.y2, mouse.y);
  let r1 = Math.abs((mouse.y2 - mouse.y) / 2);
  let r2 = Math.abs((mouse.x2 - mouse.x) / 2);
  ctx.ellipse(x1 + Math.abs(mouse.x2 - mouse.x) / 2, 
              y1 + Math.abs(mouse.y2 - mouse.y) / 2, r2, r1, 0, 0, 2 * Math.PI);
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}

//Heart ----------------------------------------------------------------------------
const heartbtn = document.getElementById("heartBtn");

heartbtn.addEventListener("click", () => {
  curtool = tools.heart;
});

function drawheart(event) {
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let y1 = Math.max(mouse.y2, mouse.y);
  let y2 = Math.min(mouse.y2, mouse.y);
  let x1 = Math.max(mouse.x2, mouse.x);
  let x2 = Math.min(mouse.x2, mouse.x);
  let r1 = Math.abs((mouse.y2 - mouse.y) / 3);
  let r2 = Math.abs((mouse.x2 - mouse.x) / 4);
  ctx.ellipse(x2 + Math.abs(mouse.x2 - mouse.x) / 4,
              y2 + Math.abs(mouse.y2 - mouse.y) / 3,
              r2, r1, 0, Math.PI, 0);
  ctx.ellipse(x2 + (Math.abs(mouse.x2 - mouse.x) / 4) * 3,
              y2 + Math.abs(mouse.y2 - mouse.y) / 3,
              r2, r1, 0, Math.PI, 0);
  ctx.moveTo(x2, y2 + Math.abs(mouse.y2 - mouse.y) / 3);
  ctx.lineTo(x2 + Math.abs(mouse.x2 - mouse.x) / 2, y1);
  ctx.lineTo(x1, y2 + Math.abs(mouse.y2 - mouse.y) / 3);
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}

//Stars ----------------------------------------------------------------------------
const star4btn = document.getElementById("star4Btn");
const star5btn = document.getElementById("star5Btn");
const star6btn = document.getElementById("star6Btn");

star4btn.addEventListener("click", () => {
  curtool = tools.star4;
});

star5btn.addEventListener("click", () => {
  curtool = tools.star5;
});

star6btn.addEventListener("click", () => {
  curtool = tools.star6;
});

function drawstar(event, spikes) {
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let r = Math.min(Math.abs(mouse.y2 - mouse.y), Math.abs(mouse.x2 - mouse.x)) / 2;
  let centerX = mouse.x + r;
  let centerY = mouse.y + r;
  if (mouse.x > mouse.x2) {
    centerX = mouse.x - r;
  }
  if (mouse.y > mouse.y2) {
    centerY = mouse.y - r;
  }
  let step = Math.PI / spikes;
  let rotation = (Math.PI / 2) * 3;
  ctx.beginPath();
  ctx.putImageData(snapshot, 0, 0);
  ctx.moveTo(centerX, centerY - r);
  for (var i = 0; i < spikes; i++) {
    let x = centerX + Math.cos(rotation) * r;
    let y = centerY + Math.sin(rotation) * r;
    ctx.lineTo(x, y);
    rotation += step;
    x = centerX + Math.cos(rotation) * (r / 2);
    y = centerY + Math.sin(rotation) * (r / 2);
    ctx.lineTo(x, y);
    rotation += step;
  }
  ctx.lineTo(centerX, centerY - r);
  ctx.closePath();
  ctx.stroke();
  if (figurefill){
    ctx.fill();
  }
}

//Moon -----------------------------------------------------------------------------
const moonbtn = document.getElementById("moonBtn");

moonbtn.addEventListener("click", () => {
  curtool = tools.moon;
});

function drawmoon(event) {
  ctx.putImageData(snapshot, 0, 0);
  const { x, y } = getCoordinates(event);
  mouse.x2 = x;
  mouse.y2 = y;
  let x1 = Math.min(mouse.x2, mouse.x);
  let y1 = Math.min(mouse.y2, mouse.y);
  let ry = Math.abs((mouse.y2 - mouse.y) / 2);
  let r1 = Math.abs(mouse.x2 - mouse.x);
  let r2 = r1 * 0.6;

  ctx.beginPath();
  if (mouse.x2 < mouse.x) {
    ctx.ellipse(mouse.x - r1, y1 + Math.abs(mouse.y2 - mouse.y) / 2,
                r1, ry, 0, (Math.PI / 2) * 3, (Math.PI / 2) * 5);
    ctx.ellipse(mouse.x - r1, y1 + Math.abs(mouse.y2 - mouse.y) / 2,
                r2, ry, 0,  (Math.PI / 2) * 5, (Math.PI / 2) * 3 , true);
  } else {
    ctx.ellipse(x1 + r1, y1 + Math.abs(mouse.y2 - mouse.y) / 2,
                r1, ry, 0, Math.PI / 2, (Math.PI / 2) * 3);
    ctx.ellipse(x1 + r1, y1 + Math.abs(mouse.y2 - mouse.y) / 2,
                r2, ry, 0, (Math.PI / 2) * 3, Math.PI / 2, true);
  }
  
  if (figurefill){
    ctx.fill('evenodd');
  }
  ctx.stroke(); 
  ctx.closePath();
}
