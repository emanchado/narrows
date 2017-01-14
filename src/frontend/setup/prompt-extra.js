const {Field} = require("./prompt");

class FileUploaderField extends Field {
    render() {
        const url = this.options.url;
        const addImageCallback = this.options.addImageCallback;

        const fileInput = document.createElement("input");
        fileInput.type = "file";
        fileInput.style.display = "none";
        fileInput.addEventListener("change", () => {
            let xhr = new XMLHttpRequest();
            xhr.open("POST", url);
            xhr.addEventListener("load", function() {
                if (this.status >= 200 && this.status < 400) {
                    const res = JSON.parse(this.responseText);
                    addButton.value = res.name;
                    addImageCallback(res.name);
                } else {
                    console.error("Error uploading file: " + this.status);
                }
            });
            const formData = new FormData();
            formData.append("file", fileInput.files[0]);
            xhr.send(formData);
        }, false);

        const addButton = document.createElement("button");
        addButton.textContent = "Upload image";
        addButton.addEventListener("click", e => {
            e.preventDefault();
            fileInput.click();
        }, false);
        return addButton;
    }
}
exports.FileUploaderField = FileUploaderField;

function updateMultiValue(el) {
    const options = el.querySelectorAll("input");
    const value = [];

    for (let i = 0, len = options.length; i < len; i++) {
        if (options[i].checked) {
            value.push(options[i].value);
        }
    }

    el.value = value;
}

class MultiSelectField extends Field {
    render() {
        const selected = this.options.selected;
        const options = this.options.options;

        const container = document.createElement("div");

        options.forEach(opt => {
            const labelEl = document.createElement("label");
            labelEl.style.display = "block";
            const checkboxEl = document.createElement("input");
            checkboxEl.type = "checkbox";
            checkboxEl.value = opt.value;
            checkboxEl.addEventListener("change", () => updateMultiValue(container), false);
            labelEl.appendChild(checkboxEl);
            labelEl.appendChild(new Text(" " + opt.label));

            container.appendChild(labelEl);
        });
        return container;
    }
}
exports.MultiSelectField = MultiSelectField;
