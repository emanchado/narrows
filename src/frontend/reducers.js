const extend = require("./extend");
const editor = require("./editor");

module.exports = {
    receiveNarrationData: (narrationData, state) => {
        return extend(state, {
            narration: extend(state.narration, narrationData)
        });
    },

    receiveNarrationFragmentsData: (narrationFragmentsData, state) => {
        return extend(state, {
            narration: extend(state.narration, {
                fragments: narrationFragmentsData
            })
        });
    },

    receiveFragmentData: (fragmentData, state) => {
        return extend(state, {
            fragment: fragmentData,
            editor: editor.create(fragmentData.text)
        });
    },

    updateFragmentTitle: (data, state) => {
        return extend(state, {
            fragment: extend(state.fragment, {
                title: data.value
            })
        });
    },

    updateNewImageUrl: (data, state) => {
        return extend(state, { newImageUrl: data.value });
    },

    createEmptyEditor: (_, state) => {
        return extend(state, {
            editorNew: editor.create(editor.importText("")),
            fragment: { title: "" }
        });
    }
};
