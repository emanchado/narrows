const extend = require("./extend");
const editor = require("./editor");

module.exports = {
    receiveNarrationData: (narrationData, state) => {
        return extend(state, {
            narration: extend(state.narration, narrationData)
        });
    },

    receiveNarrationChaptersData: (narrationChaptersData, state) => {
        return extend(state, {
            narration: extend(state.narration, {
                chapters: narrationChaptersData
            })
        });
    },

    receiveChapterData: (chapterData, state) => {
        return extend(state, {
            chapter: chapterData,
            editor: editor.create(chapterData.text)
        });
    },

    updateChapterTitle: (data, state) => {
        return extend(state, {
            chapter: extend(state.chapter, {
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
            chapter: { title: "" }
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
        const oldParticipants = state.chapter.participants;
        const newParticipants = oldParticipants.concat(data.character);

        return extend(state, {
            chapter: extend(state.chapter, {
                participants: newParticipants
            })
        });
    },

    removeParticipantSuccess: (data, state) => {
        const oldParticipants = state.chapter.participants;
        const newParticipants =
                  oldParticipants.filter(p => p.id !== data.characterId);

        return extend(state, {
            chapter: extend(state.chapter, {
                participants: newParticipants
            })
        });
    },

    updateSelectedAudio: (data, state) => {
        return extend(state, {
            chapter: extend(state.chapter, {
                audio: data.value
            })
        });
    },

    updateSelectedBackgroundImage: (data, state) => {
        return extend(state, {
            chapter: extend(state.chapter, {
                backgroundImage: data.value
            })
        });
    },

    receiveMediaFileResponse: (data, state) => {
        const type = data.type;
        const chapterProperty = type === "backgroundImages" ?
                  "backgroundImage" : "audio";

        return extend(state, {
            narration: extend(state.narration, {
                files: extend(state.narration.files, {
                    [type]: state.narration.files[type].concat(data.name)
                })
            }),

            chapter: extend(state.chapter, {
                [chapterProperty]: data.name
            })
        });
    }
};
