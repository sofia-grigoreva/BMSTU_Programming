//Line width -----------------------------------------------------------------------
const lineWidth = document.getElementById("lineWidth");
lineWidth.value = "3";
lineWidth.addEventListener("input", () => {
  ctx.lineWidth = lineWidth.value;
});

//Transparency ---------------------------------------------------------------------
const transparency = document.getElementById("transparency");

transparency.addEventListener("input", () => {
  ctx.globalAlpha = 1 - transparency.value;
});

//Hatch -------------------------------------------------------------------------------
let dash = false;
const hatchcheck = document.getElementById("hatch");

function hatchchange() {
  if (hatchcheck.checked) {
    dash = true;
  } else {
    dash = false;
  }
}

hatchcheck.addEventListener("change", hatchchange);

//Figures fill -------------------------------------------------------------------------------
let figurefill = false;

const figfillcheck = document.getElementById("figfill");

function figfillchange() {
  if (figfillcheck.checked) {
    figurefill = true;
  } else {
    figurefill = false;
  }
}

figfillcheck.addEventListener("change", figfillchange);


//Input range style --------------------------------------------------------------------------

for (let e of document.querySelectorAll('input[type="range"].slider-progress')) {
  e.style.setProperty('--value', e.value);
  e.style.setProperty('--min', e.min == '' ? '0' : e.min);
  e.style.setProperty('--max', e.max == '' ? '100' : e.max);
  e.addEventListener('input', () => e.style.setProperty('--value', e.value));
}