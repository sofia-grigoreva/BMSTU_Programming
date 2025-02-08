const welcomeModal = document.getElementById("welcomeModal");
const sizeModal = document.getElementById("sizeModal");

const closeButtons = document.querySelectorAll(".close");

window.onload = function () {
  welcomeModal.style.display = "block";
};

closeButtons.forEach((button) => {
  button.onclick = function () {
    welcomeModal.style.display = "none";
    sizeModal.style.display = "none";
  };
});

const openSizeModalBtn = document.getElementById("openSizeModal");
openSizeModalBtn.onclick = function () {
  sizeModal.style.display = "block";
};

window.onclick = function (event) {
  if (event.target == sizeModal) {
    sizeModal.style.display = "none";
    welcomeModal.style.display = "none";
  }
};

const canvasSizeForm = document.getElementById("canvasSizeForm");
canvasSizeForm.onsubmit = function (event) {
  event.preventDefault();
  const width = document.getElementById("width").value;
  const height = document.getElementById("height").value;

  const canvas = document.getElementById("canvas");
  updateCanvasSize(width, height);

  welcomeModal.style.display = "none";
  sizeModal.style.display = "none";

  canvas.style.display = "block";
};

//Uploading images -----------------------------------------------------------------
const uploadImage = document.getElementById("uploadImage");

uploadImage.addEventListener("change", (event) => {
  const file = event.target.files[0];
  const reader = new FileReader();

  reader.onload = (e) => {
    const img = new Image();
    img.onload = () => {
      let targetWidth = img.width;
      let targetHeight = img.height;

      const MIN_SIZE = 100;
      const MAX_WIDTH = 1920;
      const MAX_HEIGHT = 1080;

      if (targetWidth < MIN_SIZE || targetHeight < MIN_SIZE) {
        const scale = Math.max(MIN_SIZE / targetWidth, MIN_SIZE / targetHeight);
        targetWidth *= scale;
        targetHeight *= scale;
      }

      if (targetWidth > MAX_WIDTH || targetHeight > MAX_HEIGHT) {
        const scale = Math.min(MAX_WIDTH / targetWidth, MAX_HEIGHT / targetHeight);
        targetWidth *= scale;
        targetHeight *= scale;
      }

      canvas.width = targetWidth;
      canvas.height = targetHeight;
      ctx.drawImage(img, 0, 0, targetWidth, targetHeight);
    };
    img.src = e.target.result;
  };

  if (file) {
    reader.readAsDataURL(file);
    welcomeModal.style.display = "none";
    sizeModal.style.display = "none";
  }
});
