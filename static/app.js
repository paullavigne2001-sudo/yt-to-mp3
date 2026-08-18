const urlInput = document.getElementById("url");
const bitrate = document.getElementById("bitrate");
const convertButton = document.getElementById("convert");
const result = document.getElementById("result");
const errorBox = document.getElementById("error");
const message = document.getElementById("message");
const percent = document.getElementById("percent");
const bar = document.getElementById("bar");
const title = document.getElementById("title");
const download = document.getElementById("download");

let timer = null;

function showError(text) {
  errorBox.textContent = text;
  errorBox.classList.remove("hidden");
}

function resetUI() {
  errorBox.classList.add("hidden");
  result.classList.remove("hidden");
  download.classList.add("hidden");
  title.textContent = "";
  bar.style.width = "0%";
  percent.textContent = "0 %";
}

async function startConversion() {
  const url = urlInput.value.trim();
  if (!url) return showError("Collez d’abord un lien YouTube.");

  clearInterval(timer);
  resetUI();
  convertButton.disabled = true;
  message.textContent = "Démarrage…";

  try {
    const response = await fetch("/api/convert", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({url, bitrate: bitrate.value})
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Impossible de démarrer la conversion.");

    timer = setInterval(() => poll(data.job_id), 700);
    await poll(data.job_id);
  } catch (err) {
    convertButton.disabled = false;
    showError(err.message);
  }
}

async function poll(jobId) {
  try {
    const response = await fetch(`/api/status/${jobId}`);
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Erreur de statut.");

    const p = Number(data.progress || 0);
    bar.style.width = `${p}%`;
    percent.textContent = `${p} %`;
    message.textContent = data.message || "";

    if (data.title) title.textContent = data.title;

    if (data.status === "done") {
      clearInterval(timer);
      convertButton.disabled = false;
      bar.style.width = "100%";
      percent.textContent = "100 %";
      message.textContent = "Conversion terminée.";
      download.href = data.download_url;
      download.classList.remove("hidden");
    } else if (data.status === "error") {
      clearInterval(timer);
      convertButton.disabled = false;
      showError(data.message || "La conversion a échoué.");
    }
  } catch (err) {
    clearInterval(timer);
    convertButton.disabled = false;
    showError(err.message);
  }
}

convertButton.addEventListener("click", startConversion);
urlInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter") startConversion();
});
