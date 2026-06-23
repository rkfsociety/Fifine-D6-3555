/// <reference path="../utils/common.js" />
/// <reference path="../utils/action.js" />

const $local = false, $back = false, $dom = {
    main: $('.sdpi-wrapper')
};

function pickPath(data) {
    if (!data) return "";
    if (typeof data === "string") return data;
    return data.path || data.file || data.url || data[0] || "";
}

function toFileUrl(path) {
    if (!path) return "";
    const normalized = path.replace(/\\/g, "/");
    if (normalized.startsWith("file:")) return normalized;
    return "file:///" + (normalized.startsWith("/") ? normalized.slice(1) : normalized);
}

function readLocalFile(path) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", toFileUrl(path), true);
        xhr.responseType = "blob";
        xhr.onload = () => {
            if (xhr.status === 0 || (xhr.status >= 200 && xhr.status < 300)) {
                const reader = new FileReader();
                reader.onload = () => resolve(reader.result);
                reader.onerror = reject;
                reader.readAsDataURL(xhr.response);
            } else {
                reject(new Error("read failed"));
            }
        };
        xhr.onerror = reject;
        xhr.send();
    });
}

function updatePreview() {
    const preview = document.getElementById("preview");
    if ($settings.gifData) {
        preview.src = $settings.gifData;
    } else if ($settings.gifUrl) {
        preview.src = $settings.gifUrl;
    } else if ($settings.gifPath) {
        preview.src = toFileUrl($settings.gifPath);
    } else if ($settings.demoGif) {
        preview.src = "../../" + $settings.demoGif;
    } else {
        preview.src = "../../static/demo.gif";
    }
}

function pushSettingsToPlugin() {
    $websocket.sendToPlugin({ settings: JSON.parse(JSON.stringify($settings)) });
}

function updateSpeedLabel() {
    $("#speedValue").textContent = ($settings.speed ?? 100) + "%";
}

function updateTimingUi() {
    const useGif = $settings.timingMode === "gif";
    $("#fpsRow").style.display = useGif ? "none" : "";
}

function syncFields() {
    $("#gifUrl").value = $settings.gifUrl || "";
    $("#speed").value = $settings.speed ?? 100;
    $("#timingMode").value = $settings.timingMode === "gif" ? "gif" : "fps";
    $("#fps").value = $settings.fps ?? 15;
    $("#bgOpacity").value = $settings.bgOpacity ?? 50;
    $("#title").value = $settings.title || "";
    updateSpeedLabel();
    updateTimingUi();
    updatePreview();
}

const $propEvent = {
    didReceiveSettings() {
        syncFields();
    }
};

$emit.on("File-gifFile", async (data) => {
    const path = pickPath(data);
    $settings.gifPath = path;
    $settings.gifUrl = "";
    $settings.demoGif = "";
    $("#gifUrl").value = "";

    try {
        $settings.gifData = await readLocalFile(path);
    } catch {
        $settings.gifData = "";
    }

    updatePreview();
    $websocket.sendToPlugin({ settings: JSON.parse(JSON.stringify($settings)) });
});

$("#gifUrl").on("change", () => {
    const url = $("#gifUrl").value.trim();
    $settings.gifUrl = url;
    if (url) {
        $settings.gifPath = "";
        $settings.gifData = "";
        $settings.demoGif = "";
    }
    updatePreview();
});

$("#speed").on("input", () => {
    $settings.speed = Math.min(400, Math.max(25, Number($("#speed").value) || 100));
    updateSpeedLabel();
    pushSettingsToPlugin();
});

$("#timingMode").on("change", () => {
    $settings.timingMode = $("#timingMode").value === "gif" ? "gif" : "fps";
    updateTimingUi();
    pushSettingsToPlugin();
});

$("#fps").on("change", () => {
    $settings.fps = Math.min(30, Math.max(1, Number($("#fps").value) || 15));
    pushSettingsToPlugin();
});

$("#bgOpacity").on("input", () => {
    $settings.bgOpacity = Math.min(100, Math.max(0, Number($("#bgOpacity").value) || 50));
    pushSettingsToPlugin();
});

$("#title").on("change", () => {
    $settings.title = $("#title").value.trim();
    pushSettingsToPlugin();
});

$("#clear").on("click", () => {
    $settings.gifPath = "";
    $settings.gifUrl = "";
    $settings.gifData = "";
    $settings.demoGif = "static/demo.gif";
    $("#gifUrl").value = "";
    updatePreview();
    $websocket.sendToPlugin({ settings: JSON.parse(JSON.stringify($settings)) });
});
