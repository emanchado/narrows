module NarratorApp.Update exposing (..)

import Http

import Routing
import NarratorApp.Api
import NarratorApp.Messages exposing (..)
import NarratorApp.Models exposing (..)
import NarratorApp.Ports exposing (initEditor, addImage, addMention, playPauseAudioPreview, openFileInput, uploadFile)


updateNarrationFiles : FileSet -> NarratorApp.Ports.FileUploadSuccess -> FileSet
updateNarrationFiles fileSet uploadResponse =
  case uploadResponse.type' of
    "audio" ->
      { fileSet | audio = uploadResponse.name :: fileSet.audio }
    "backgroundImages" ->
      { fileSet | backgroundImages = uploadResponse.name :: fileSet.backgroundImages }
    _ ->
      fileSet


updateChapter : Chapter -> NarratorApp.Ports.FileUploadSuccess -> Chapter
updateChapter chapter uploadResponse =
  case uploadResponse.type' of
    "audio" ->
      { chapter | audio = Just uploadResponse.name }
    "backgroundImages" ->
      { chapter | backgroundImage = Just uploadResponse.name }
    _ ->
      chapter


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.ChapterNarratorPage chapterId ->
        ( model
        , NarratorApp.Api.fetchChapterInfo chapterId
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    ChapterFetchError error ->
      let
        errorString = case error of
                        Http.UnexpectedPayload payload ->
                          "Bad payload: " ++ payload
                        Http.BadResponse status body ->
                          "Got status " ++ (toString status) ++ " with body " ++ body
                        _ ->
                          "Network stuff"
      in
        ( { model | banner = Just { type' = "error", text = errorString } }
        , Cmd.none)
    ChapterFetchSuccess chapter ->
      ( { model | chapter = Just chapter }
      , Cmd.batch [ initEditor { elemId = "editor-container"
                               , text = chapter.text
                               }
                  , NarratorApp.Api.fetchNarrationInfo chapter.narrationId
                  ]
      )
    NarrationFetchError error ->
      let
        errorString = case error of
                        Http.UnexpectedPayload payload ->
                          "Bad payload: " ++ payload
                        Http.BadResponse status body ->
                          "Got status " ++ (toString status) ++ " with body " ++ body
                        _ ->
                          "Network stuff"
      in
        ( { model | banner = Just { type' = "error", text = errorString } }
        , Cmd.none)
    NarrationFetchSuccess narration ->
      ( { model | narration = Just narration }
      , Cmd.none
      )
    UpdateChapterTitle newTitle ->
      case model.chapter of
        Just chapter ->
          let
            newChapter = { chapter | title = newTitle }
          in
            ({ model | chapter = Just newChapter }, Cmd.none)
        Nothing ->
          (model, Cmd.none)
    UpdateEditorContent newText ->
      case model.chapter of
        Just chapter ->
          let
            updatedChapter = { chapter | text = newText }
          in
            ({ model | chapter = Just updatedChapter }, Cmd.none)
        Nothing ->
          (model, Cmd.none)

    UpdateNewImageUrl newUrl ->
      let
        oldEditorToolState = model.editorToolState
        newEditorToolState = { oldEditorToolState | newImageUrl = newUrl }
      in
        ({ model | editorToolState = newEditorToolState }, Cmd.none)
    AddImage ->
      (model, addImage { editor = "editor-container"
                       , imageUrl = model.editorToolState.newImageUrl
                       })

    AddNewMentionCharacter character ->
      let
        oldEditorToolState = model.editorToolState
        newMentionList = character :: oldEditorToolState.newMentionTargets
        newEditorToolState =
          { oldEditorToolState | newMentionTargets = newMentionList }
      in
        ({ model | editorToolState = newEditorToolState }, Cmd.none)
    RemoveNewMentionCharacter character ->
      let
        oldEditorToolState = model.editorToolState
        newMentionList =
          List.filter
            (\t -> t /= character)
            oldEditorToolState.newMentionTargets
        newEditorToolState =
          { oldEditorToolState | newMentionTargets = newMentionList }
      in
        ({ model | editorToolState = newEditorToolState }, Cmd.none)
    AddMention ->
      (model, addMention { editor = "editor-container"
                         , targets = model.editorToolState.newMentionTargets
                         })

    AddParticipant character ->
      case model.chapter of
        Just chapter ->
          let
            participantsWithoutCharacter =
              List.filter (\p -> p /= character) chapter.participants
            participantsWithCharacter =
              character :: participantsWithoutCharacter
            chapterWithCharacter =
              { chapter | participants = participantsWithCharacter }
          in
            ( { model | chapter = Just chapterWithCharacter }
            , NarratorApp.Api.addParticipant chapter character
            )
        Nothing ->
          (model, Cmd.none)
    AddParticipantError error ->
      ({ model | banner = Just { text = "Error adding participant"
                               , type' = "error"
                               }
       }
      , Cmd.none)
    AddParticipantSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        (model, Cmd.none)
      else
        ({ model | banner = Just { text = "Error adding participant"
                                 , type' = "error"
                                 }
         }
        , Cmd.none)
    RemoveParticipant character ->
      case model.chapter of
        Just chapter ->
          let
            participantsWithoutCharacter =
              List.filter (\p -> p /= character) chapter.participants
            chapterWithoutCharacter =
              { chapter | participants = participantsWithoutCharacter }
          in
            ( { model | chapter = Just chapterWithoutCharacter }
            , NarratorApp.Api.removeParticipant chapter character
            )
        Nothing ->
          (model, Cmd.none)
    RemoveParticipantError error ->
      ({ model | banner = Just { text = "Error removing participant"
                               , type' = "error"
                               }
       }
      , Cmd.none)
    RemoveParticipantSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        (model, Cmd.none)
      else
        ({ model | banner = Just { text = "Error removing participant"
                                 , type' = "error"
                                 }
         }
        , Cmd.none)

    UpdateSelectedBackgroundImage imageUrl ->
      case model.chapter of
        Just chapter ->
          let
            newBgImage = if imageUrl == "" then
                           Nothing
                         else
                           Just imageUrl
            updatedChapter = { chapter | backgroundImage = newBgImage }
          in
            ({ model | chapter = Just updatedChapter }, Cmd.none)
        Nothing ->
            (model, Cmd.none)
    UpdateSelectedAudio audioUrl ->
      case model.chapter of
        Just chapter ->
          let
            newAudio = if audioUrl == "" then
                         Nothing
                       else
                         Just audioUrl
            updatedChapter = { chapter | audio = newAudio }
          in
            ({ model | chapter = Just updatedChapter }, Cmd.none)
        Nothing ->
            (model, Cmd.none)
    PlayPauseAudioPreview ->
      (model, playPauseAudioPreview "audio-preview")
    OpenMediaFileSelector fileInputId ->
      (model, openFileInput fileInputId)
    AddMediaFile fileInputId ->
      case model.chapter of
        Just chapter ->
          (model, uploadFile { fileInputId = fileInputId
                             , narrationId = chapter.narrationId
                             })
        Nothing ->
          (model, Cmd.none)
    AddMediaFileError error ->
      ({ model | banner = Just { text = "Error upload media file: " ++ error.message
                               , type' = "error"
                               }
       }
      , Cmd.none)
    AddMediaFileSuccess resp ->
      case model.narration of
        Just narration ->
          case model.chapter of
            Just chapter ->
              let
                updatedFiles = updateNarrationFiles narration.files resp
                updatedNarration = { narration | files = updatedFiles }
                updatedChapter = updateChapter chapter resp
              in
                ( { model | narration = Just updatedNarration
                          , chapter = Just updatedChapter
                  }
                , Cmd.none)
            Nothing ->
              (model, Cmd.none)
        Nothing ->
          (model, Cmd.none)

    SaveChapter ->
      case model.chapter of
        Just chapter ->
          (model, NarratorApp.Api.saveChapter chapter)
        Nothing ->
          (model, Cmd.none)
    SaveChapterError error ->
      ({ model | banner = Just { text = "Error saving chapter"
                               , type' = "error"
                               }
       }
      , Cmd.none)
    SaveChapterSuccess resp ->
      let
        newBanner = if (resp.status >= 200) && (resp.status < 300) then
                      Just { text = "Chapter saved", type' = "success" }
                    else
                      Just { text = "Error saving chapter"
                           , type' = "error"
                           }
      in
        ({ model | banner = newBanner }, Cmd.none)
