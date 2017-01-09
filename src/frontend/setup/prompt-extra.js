const {Field} = require("./prompt");

class FileUploaderField extends Field {
    render() {
        const url = this.options.url;

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
