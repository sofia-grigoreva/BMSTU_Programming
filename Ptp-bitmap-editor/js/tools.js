//Pen ------------------------------------------------------------------------------
const penbtn = document.getElementById("penBtn");

penbtn.addEventListener("click", () => {
  ctx.globalCompositeOperation = "source-over";
  curtool = tools.pen;
});

function drawpen(event) {
  const { x, y } = getCoordinates(event);
  ctx.lineTo(x, y);
  ctx.stroke();
}

//Eraser ---------------------------------------------------------------------------
const eraserbtn = document.getElementById("eraserBtn");

eraserbtn.addEventListener("click", () => {
  curtool = tools.eraser;
});

function erase(event) {
  const { x, y } = getCoordinates(event);
  ctx.globalAlpha = 1;
  ctx.setLineDash([0, 0]);
  ctx.globalCompositeOperation = "destination-out";
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.lineTo(x, y);
  ctx.stroke();
}

//Spray ----------------------------------------------------------------------------
const spraybtn = document.getElementById("sprayBtn");

spraybtn.addEventListener("click", () => {
  ctx.globalCompositeOperation = "source-over";
  curtool = tools.spray;
});

function drawspray(event) {
  const { x, y } = getCoordinates(event);
  const density = 50;
  const sprayRadius = ctx.lineWidth * 5;

  for (let i = 0; i < density; i++) {
    const offsetX = (Math.random() - 0.5) * sprayRadius;
    const offsetY = (Math.random() - 0.5) * sprayRadius;
    const sprayX = x + offsetX;
    const sprayY = y + offsetY;

    ctx.fillStyle = ctx.strokeStyle;
    ctx.fillRect(sprayX, sprayY, ctx.lineWidth / 5, ctx.lineWidth / 5);
  }
}

//Fill -----------------------------------------------------------------------------
const fillbtn = document.getElementById("fillBtn");

fillbtn.addEventListener("click", () => {
  curtool = tools.fill;
});

function floodFill(event) {
  const { x, y } = getCoordinates(event);
  const newColor = [
    parseInt(ctx.strokeStyle.slice(1, 3), 16),
    parseInt(ctx.strokeStyle.slice(3, 5), 16),
    parseInt(ctx.strokeStyle.slice(5, 7), 16)
  ];
  const imageData = ctx.getImageData(0, 0, w, h);
  const data = imageData.data;
  const oldColor = [data[(y * w + x) * 4], data[(y * w + x) * 4 + 1], data[(y * w + x) * 4 + 2]];
  if (oldColor[0] === newColor[0] && oldColor[1] === newColor[1] && oldColor[2] === newColor[2]) {
    if (!(oldColor[0] === 0 && oldColor[1] === 0 && oldColor[2] === 0)) {
      return;
    } else {
      newColor[0] = 255;
      newColor[1] = 255;
      newColor[2] = 255;
      const queue = [[x, y]];
      while (queue.length > 0) {
        const [cx, cy] = queue.shift();
        const index = (cy * w + cx) * 4;
        if (data[index] === oldColor[0] && data[index + 1] === oldColor[1] && data[index + 2] === oldColor[2]) {
          data[index] = newColor[0];
          data[index + 1] = newColor[1];
          data[index + 2] = newColor[2];
          data[index + 3] = 255 * ctx.globalAlpha;
          queue.push([cx - 1, cy], [cx + 1, cy], [cx, cy - 1], [cx, cy + 1]);
        }
      }
      newColor[0] = 0;
      newColor[1] = 0;
      newColor[2] = 0;
      oldColor[0] = 255;
      oldColor[1] = 255;
      oldColor[2] = 255;
    }
  } 

  const queue = [[x, y]];
  while (queue.length > 0) {
    const [cx, cy] = queue.shift();
    const index = (cy * w + cx) * 4;
    if (data[index] === oldColor[0] && data[index + 1] === oldColor[1] && data[index + 2] === oldColor[2]) {
      data[index] = newColor[0];
      data[index + 1] = newColor[1];
      data[index + 2] = newColor[2];
      data[index + 3] = 255 * ctx.globalAlpha;
      queue.push([cx - 1, cy], [cx + 1, cy], [cx, cy - 1], [cx, cy + 1]);
    }
  }
  ctx.putImageData(imageData, 0, 0);
}

//Pipette --------------------------------------------------------------------------
const pipettebtn = document.getElementById("pipetteBtn");

pipettebtn.addEventListener("click", () => {
  canvas.addEventListener("touchstart", getColor);
  canvas.addEventListener("click", getColor);
});

function rgbToHex(r, g, b) {
  const toHex = (c) => {
    const hex = c.toString(16).padStart(2, "0");
    return hex;
  };
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

function getColor(event) {
  const { x, y } = getCoordinates(event);
  const pixel = ctx.getImageData(x, y, 1, 1).data;
  const color = `rgba(${pixel[0]}, ${pixel[1]}, ${pixel[2]}, ${pixel[3]})`;

  if (pixel[0] === 0 && pixel[1] === 0 && pixel[2] === 0 && pixel[3] === 0) {
    colorPicker.value = "#ffffff";
    ctx.strokeStyle = "white";
  } else {
    colorPicker.value = rgbToHex(pixel[0], pixel[1], pixel[2]);
    transparency.value = 1 - pixel[3] / 255;
    transparency.style.setProperty("--value", transparency.value);
    ctx.globalAlpha = pixel[3] / 255;
    ctx.strokeStyle = color;
    if (currow == "1" && !colors1.includes(colorPicker.value) && !colors2.includes(colorPicker.value)) {
    colors1.splice(7, 1, colorPicker.value);
    } else if (currow == "2" && !colors2.includes(colorPicker.value) && !colors1.includes(colorPicker.value)) {
    colors2.splice(7, 1, colorPicker.value);
    }
    colorlist1.innerHTML = "";
    colorlist2.innerHTML = "";
    displayColors();
    if (currow == "1") {
      currow = "2";
    } else {
      currow = "1";
    }
  }
  canvas.removeEventListener("touchstart", getColor);
  canvas.removeEventListener("click", getColor);
}

//Allocation -----------------------------------------------------------------------
const allocationbtn = document.getElementById("allocationBtn");

allocationbtn.addEventListener("click", () => {
  curtool = tools.allocation1;
});

function allocation1(event) {
  const { x, y } = getCoordinates(event);
  ctx.putImageData(snapshot, 0, 0);
  ctx.strokeStyle = "#0000a7";
  ctx.lineWidth = "3";
  ctx.globalAlpha = 1;
  ctx.setLineDash([12, 6]);
  mouse.x2 = x;
  mouse.y2 = y;
  let rectX = Math.min(mouse.x2, mouse.x);
  let rectY = Math.min(mouse.y2, mouse.y);
  snapshot3 = ctx.getImageData(0, 0, w, h);
  ctx.strokeRect(rectX, rectY, Math.abs(mouse.x2 - mouse.x), Math.abs(mouse.y2 - mouse.y));
}

function allocation2(event) {
  const { x, y } = getCoordinates(event);
  let v = area.h - Math.abs(area.y2 - mouse.y);
  let z = area.w - Math.abs(area.x2 - mouse.x);
  ctx.putImageData(snapshot, 0, 0);
  ctx.strokeStyle = "#0000a7";
  ctx.lineWidth = "3";
  ctx.globalAlpha = 1;
  ctx.setLineDash([12, 6]);
  mouse.x2 = x;
  mouse.y2 = y;
  ctx.putImageData(picture, mouse.x2 - z, mouse.y2 - v);
  snapshot3 = ctx.getImageData(0, 0, w, h);
  ctx.strokeRect(mouse.x2 - z, mouse.y2 - v, area.w, area.h);
}
