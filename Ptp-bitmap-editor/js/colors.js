const colorlist1 = document.getElementById("colors-row1");
const colorlist2 = document.getElementById("colors-row2");

let colors1 = ["#ff0000", 
               "#ffa500", 
               "#ffff00", 
               "#008000", 
               "#009fff", 
               "#0000ff", 
               "#800080", 
               "#ffffff00"];

let colors2 = ["#0000a7", 
               "#0000ff", 
               "#2736f2", 
               "#5883cc", 
               "#6BC6F0", 
               "#ffffff",
               "#000000", 
               "#ffffff00"];

var currow = "1";

//Color palette --------------------------------------------------------------------

function createelement(name, text, classes = [], listeners = []) {
  const element = document.createElement(name);
  element.textContent = text;
  element.classList.add(...classes);
  listeners.forEach((listener) => {
    element.addEventListener(listener.event, listener.handler);
  });
  return element;
}

function displayColors() {
  colors1.forEach((color) => {
    const listeners = [
      {
        event: "click",
        handler: () => {
          ctx.strokeStyle = color;
          colorPicker.value = color;
        }
      }
    ];
    const li = createelement("li", null, ["color-list-item"], listeners);
    if (color == "#ffffff00") {
      li.style.borderColor = "#5883cc";
      li.style.backgroundColor = "#c0ddff";
      li.pointerEvents = "none";
      li.style.pointerEvents = "none";
    } else {
      li.style.backgroundColor = color;
    }
    colorlist1.appendChild(li);
  });

  colors2.forEach((color) => {
    const listeners = [
      {
        event: "click",
        handler: () => {
          ctx.strokeStyle = color;
          colorPicker.value = color;
        }
      }
    ];
    const li = createelement("li", null, ["color-list-item"], listeners);
    if (color == "#ffffff00") {
      li.style.borderColor = "#5883cc";
      li.style.backgroundColor = "#c0ddff";
      li.style.pointerEvents = "none";
    } else {
      li.style.backgroundColor = color;
    }
    colorlist2.appendChild(li);
  });
}

displayColors();

//Current color --------------------------------------------------------------------
const colorPicker = document.getElementById("colorPicker");

colorPicker.addEventListener("change", () => {
  ctx.strokeStyle = colorPicker.value;
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
});