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
    },

    updateSelectedAudio: (data, state) => {
        return extend(state, {
            fragment: extend(state.fragment, {
                audio: data.value
            })
        });
    },

    updateSelectedBackgroundImage: (data, state) => {
        return extend(state, {
            fragment: extend(state.fragment, {
                backgroundImage: data.value
            })
        });
    },

    receiveMediaFileResponse: (data, state) => {
        const type = data.type;
        const fragmentProperty = type === "images" ?
                  "backgroundImage" : "audio";

        return extend(state, {
            narration: extend(state.narration, {
                files: extend(state.narration.files, {
                    [type]: state.narration.files[type].concat(data.name)
                })
            }),

            fragment: extend(state.fragment, {
                [fragmentProperty]: data.name
            })
        });
    }
};
