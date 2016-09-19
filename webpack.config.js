var path = require("path");

module.exports = {
    entry: {narrator: "./src/frontend/narrator.js",
            reader: "./src/frontend/reader.js"},
    output: {
        path: path.join(__dirname, "public", "compiled"),
        filename: "[name].bundle.js"
    },
    module: {
        loaders: [
            { test: /\.css$/, loader: "style!css" }
        ]
    }
};
