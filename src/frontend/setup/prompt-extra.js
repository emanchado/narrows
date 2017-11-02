const {Field} = require("./prompt");

class ImageSelectorField extends Field {
    render() {
        // This is the main component, the one to be returned.
        const container = document.createElement("div");
        container.className = "control-line";

        // Image preview
        const imagePreview = document.createElement("img");
        imagePreview.className = "image-preview";

        // Select component for the already-uploaded images.
        const select = document.createElement("select");
        this.options.images.forEach(imageName => {
            const opt = select.appendChild(document.createElement("option"));
            opt.value = imageName;
            opt.selected = imageName == this.options.value;
            opt.textContent = imageName;
        });
        container.value = select.selectedOptions.item(0) && select.selectedOptions.item(0).value;
        select.addEventListener("change", evt => {
            container.value = select.selectedOptions.item(0) && select.selectedOptions.item(0).value;
            imagePreview.src = select.selectedOptions.item(0) && `/static/narrations/${this.options.narrationId}/images/` + select.selectedOptions.item(0).value;
        }, false);
        if (select.selectedOptions.item(0)) {
            imagePreview.src = `/static/narrations/${this.options.narrationId}/images/` + select.selectedOptions.item(0).value;
        } else {
            imagePreview.src = "/img/no-preview.png";
        }

        const addImageCallback = name => {
            const options = select.querySelectorAll("option");
            options.forEach(opt => opt.selected = false);

            const opt = select.appendChild(document.createElement("option"));
            opt.value = name;
            opt.selected = true;
            opt.textContent = name;

            container.value = name;
            imagePreview.src = `/static/narrations/${this.options.narrationId}/images/${name}`;
            this.options.addImageCallback(name);
        };

        // File upload handling (file element and upload button)
        const fileInput = document.createElement("input");
        fileInput.type = "file";
        fileInput.style.display = "none";
        fileInput.addEventListener("change", () => {
            let xhr = new XMLHttpRequest();
            xhr.open("POST", this.options.uploadUrl);
            xhr.addEventListener("load", function() {
                if (this.status >= 200 && this.status < 400) {
                    const res = JSON.parse(this.responseText);
                    addImageCallback(res.name);
                } else {
                    console.error("Error uploading file: " + this.status);
                }
            });
            const formData = new FormData();
            formData.append("file", fileInput.files[0]);
            xhr.send(formData);
        }, false);
        // Upload button
        const uploadButton = document.createElement("button");
        uploadButton.className = "btn btn-small btn-add";
        uploadButton.textContent = "Upload";
        uploadButton.addEventListener("click", e => {
            e.preventDefault();
            fileInput.click();
        }, false);

        container.appendChild(select);
        container.appendChild(uploadButton);
        container.appendChild(imagePreview);
        return container;
    }
}
exports.ImageSelectorField = ImageSelectorField;

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
            checkboxEl.checked = (selected.indexOf(opt.value) !== -1);
            checkboxEl.addEventListener("change", () => updateMultiValue(container), false);
            labelEl.appendChild(checkboxEl);
            labelEl.appendChild(new Text(" " + opt.label));

            container.appendChild(labelEl);
        });
        updateMultiValue(container);
        return container;
    }
}
exports.MultiSelectField = MultiSelectField;
