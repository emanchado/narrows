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
    },

    toggleMentionCharacter: (data, state) => {
        const mentionCharacters = state[data.path] || [];
        const newMentionCharacterList =
                  mentionCharacters.includes(data.value) ?
                      mentionCharacters.filter(mc => mc !== data.value) :
                      mentionCharacters.concat(data.value);

        return extend(state, {
            [data.path]: newMentionCharacterList
        });
    },

    addParticipantSuccess: (data, state) => {
        const oldParticipants = state.fragment.participants;
        const newParticipants = oldParticipants.concat(data.character);

        return extend(state, {
            fragment: extend(state.fragment, {
                participants: newParticipants
            })
        });
    },

    removeParticipantSuccess: (data, state) => {
        const oldParticipants = state.fragment.participants;
        const newParticipants =
                  oldParticipants.filter(p => p.id !== data.characterId);

        return extend(state, {
            fragment: extend(state.fragment, {
                participants: newParticipants
            })
        });
    }
};
