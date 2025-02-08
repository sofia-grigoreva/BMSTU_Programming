//Saving ---------------------------------------------------------------------------
const savebtn = document.getElementById('saveBtn');

function cancelSaveOptions() {
  event.preventDefault();
  document.getElementById('saveOptions').style.display = 'none';
}

function applySaveOptions() {
  const filename = document.getElementById('filename').value || 'canvas-masterpiece';
  const format = document.getElementById('format').value;
  
  const dataURL = canvas.toDataURL(format);
  const a = document.createElement('a');
  a.href = dataURL;
  a.download = `${filename}.${format.split('/')[1]}`;
  a.click();
  
  document.getElementById('saveOptions').style.display = 'none';
}

function save() {
  document.getElementById('saveOptions').style.display = 'block';
}

savebtn.addEventListener('click', save);

//Clearing -------------------------------------------------------------------------
const clearbtn = document.getElementById('clearBtn');

clearbtn.addEventListener('click', () => {
  ctx.clearRect(0, 0, w, h);
});

//Copying --------------------------------------------------------------------------
const copybtn = document.getElementById('copyBtn');

function copy() {
  canvas.toBlob(function(blob) {
    const item = new ClipboardItem({'image/png': blob});
    navigator.clipboard.write([item]).catch(function(error) {
    });
  });
}

copybtn.addEventListener('click', copy);

//Undo and redo --------------------------------------------------------------------
const undobtn = document.getElementById('undoBtn');
const redobtn = document.getElementById('redoBtn');

function undo() {
  if (undoStack.length > 0) {
    redoStack.push(ctx.getImageData(0, 0, w, h));
    snapshot = undoStack.pop();
    ctx.putImageData(snapshot, 0, 0);
  }
}

function redo() {
  if (redoStack.length > 0) {
    undoStack.push(ctx.getImageData(0, 0, w, h));
    snapshot = redoStack.pop();
    ctx.putImageData(snapshot, 0, 0);
  }
}

undobtn.addEventListener('click', undo);
redobtn.addEventListener('click', redo);

//Pasting images -------------------------------------------------------------------
const pasteImagebtn = document.getElementById('pasteImageBtn');
const modalFour = document.getElementById("CoefficientModal");
const spanthree = document.getElementsByClassName("close-buttonThree")[0];
const saveCoefficientButton = document.getElementById("saveCoefficientModal");

pasteImagebtn.addEventListener('click', () => {
  curtool = tools.image;
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'image/*';
  input.onchange = function(event) {
    const file = event.target.files[0];
    const reader = new FileReader();
    reader.onload = function(event) {
      img.src = event.target.result;
      modalFour.style.display = "block";
    };
    reader.readAsDataURL(file);
  };
  input.click();
});

spanthree.onclick = function() {
  modalFour.style.display = "none";
};

saveCoefficientButton.onclick = function() {
  changeCoefficient(document.getElementById("coefficient").value);
  modalFour.style.display = "none";
};

function changeCoefficient(newCoefficient) {
    coefficient = newCoefficient;
}

//Pasting text ---------------------------------------------------------------------
const pasteTextbtn = document.getElementById('pasteTextBtn');
const modalTwo = document.getElementById("TextModal");
const span = document.getElementsByClassName("close-button")[0];
const saveButton = document.getElementById("saveModal");

pasteTextbtn.addEventListener('click', () => {
  modalTwo.style.display = "block";
  curtool = tools.text;
});

span.onclick = function() {
  modalTwo.style.display = "none";
};

saveButton.onclick = function() {
  const modalText = document.getElementById("modalText").value;
  changeText(modalText);
  FontSize = document.getElementById("fontTwo").value;
  modalTwo.style.display = "none";
};

function changeText(t) {
  Text = t;
}

//Hotkeys --------------------------------------------------------------------------
document.addEventListener('keydown', function(event) {
  if (event.ctrlKey && (event.key === 'z' || event.key === 'я')) {
    event.preventDefault();
    undo();
  }

  if (event.ctrlKey && (event.key === 'y' || event.key === 'н')) {
    event.preventDefault();
    redo();
  }

  if (event.ctrlKey && (event.key === 's' || event.key === 'ы')) {
    event.preventDefault();
    save();
  }
  
  if (event.ctrlKey && (event.key === 'c' || event.key === 'с')) {
    event.preventDefault();
    copy();
  }
});