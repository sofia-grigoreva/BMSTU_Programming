const zoomRange = document.getElementById('zoomRange');
const zoomValue = document.getElementById('zoomValue');

zoomRange.addEventListener('input', () => {
  const scale = zoomRange.value / 100;
  canvas.style.transform = `scale(${scale})`;
  canvas.style.transformOrigin = 'top left';
  zoomValue.value = zoomRange.value;
  canvas.scrollTop = 0;
  canvas.scrollLeft = 0;
});

zoomValue.addEventListener('input', () => {
  let value = parseInt(zoomValue.value, 10);
  if (isNaN(value) || value < 50) value = 50;
  if (value > 200) value = 200;
  zoomRange.value = value;
  const scale = value / 100;
  canvas.style.transform = `scale(${scale})`;
  canvas.style.transformOrigin = 'top left';
  canvas.scrollTop = 0;
  canvas.scrollLeft = 0;
});