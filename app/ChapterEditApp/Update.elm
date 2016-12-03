module ChapterEditApp.Update exposing (..)

import Http
import Json.Decode
import Json.Encode
import Navigation
import Task
import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime, fromTimestamp)

import Routing
import Common.Models exposing (Banner, Chapter, FileSet)

import ChapterEditApp.Api
import ChapterEditApp.Api.Json exposing (parseChapter)
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Models exposing (..)
import ChapterEditApp.Ports exposing (initEditor, addImage, addMention, playPauseAudioPreview, openFileInput, uploadFile)


errorBanner : String -> Maybe Banner
errorBanner errorMessage =
  Just { text = errorMessage
       , type' = "error"
       }

updateNarrationFiles : FileSet -> ChapterEditApp.Ports.FileUploadSuccess -> FileSet
updateNarrationFiles fileSet uploadResponse =
  case uploadResponse.type' of
    "audio" ->
      { fileSet | audio = uploadResponse.name :: fileSet.audio }
    "backgroundImages" ->
      { fileSet | backgroundImages = uploadResponse.name :: fileSet.backgroundImages }
    _ ->
      fileSet


updateChapter : Chapter -> ChapterEditApp.Ports.FileUploadSuccess -> Chapter
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
      Routing.ChapterEditNarratorPage chapterId ->
        ( model
        , ChapterEditApp.Api.fetchChapterInfo chapterId
        )
      Routing.CreateChapterPage narrationId ->
        let
          action = case model.narration of
                     Just narration ->
                       if narration.id == narrationId then
                         Cmd.none
                       else
                         ChapterEditApp.Api.fetchNarrationInfo narrationId
                     Nothing ->
                       ChapterEditApp.Api.fetchNarrationInfo narrationId
        in
          ({ model | chapter = Nothing }, action)
      _ ->
        (model, Cmd.none)

genericHttpErrorHandler : Model -> Http.Error -> (Model, Cmd Msg)
genericHttpErrorHandler model error =
  let
    errorString = case error of
                    Http.UnexpectedPayload payload ->
                      "Bad payload: " ++ payload
                    Http.BadResponse status body ->
                      "Got status " ++ (toString status) ++ " with body " ++ body
                    _ ->
                      "Network stuff"
  in
    ({ model | banner = errorBanner errorString }, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    ChapterFetchError error ->
      genericHttpErrorHandler model error
    ChapterFetchSuccess chapter ->
      ( { model | chapter = Just chapter }
      , Cmd.batch [ initEditor { elemId = "editor-container"
                               , text = chapter.text
                               }
                  , ChapterEditApp.Api.fetchNarrationInfo chapter.narrationId
                  , ChapterEditApp.Api.fetchLastReactions chapter.id
                  ]
      )
    NarrationFetchError error ->
      genericHttpErrorHandler model error
    NarrationFetchSuccess narration ->
      let
        (updatedChapter, action) =
          case model.chapter of
            Nothing -> ( Just (newEmptyChapter narration)
                       , initEditor { elemId = "editor-container"
                                    , text = Json.Encode.null
                                    }
                       )
            _ -> (model.chapter, Cmd.none)
      in
        ( { model | narration = Just narration, chapter = updatedChapter }
        , action
        )
    LastReactionsFetchError error ->
      genericHttpErrorHandler model error
    LastReactionsFetchSuccess lastReactions ->
      ({ model | lastReactions = Just lastReactions }, Cmd.none)

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
            ({ model | chapter = Just chapterWithCharacter }, Cmd.none)
        Nothing ->
          (model, Cmd.none)
    RemoveParticipant character ->
      case model.chapter of
        Just chapter ->
          let
            participantsWithoutCharacter =
              List.filter (\p -> p /= character) chapter.participants
            chapterWithoutCharacter =
              { chapter | participants = participantsWithoutCharacter }
          in
            ({ model | chapter = Just chapterWithoutCharacter }, Cmd.none)
        Nothing ->
          (model, Cmd.none)

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
      ({ model | banner = errorBanner <| "Error upload media file: " ++ error.message }
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
          (model, ChapterEditApp.Api.saveChapter chapter)
        Nothing ->
          (model, Cmd.none)
    PublishChapter ->
      (model, Task.perform (\x -> NoOp) PublishChapterWithTime Time.now)
    PublishChapterWithTime time ->
      case model.chapter of
        Just chapter ->
          let
            updatedChapter = { chapter | published = Just <| DateTime.toISO8601 (fromTimestamp time) }
          in
            ( { model | chapter = Just updatedChapter }
            , ChapterEditApp.Api.saveChapter updatedChapter
            )
        Nothing ->
          (model, Cmd.none)
    SaveChapterError error ->
      ({ model | banner = errorBanner "Error saving chapter" }
      , Cmd.none)
    SaveChapterSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        (model, Cmd.none)
      else
        ( { model | banner = errorBanner <| "Error saving chapter, status code " ++ (toString resp.status) }
        , Cmd.none
        )

    SaveNewChapter ->
      case model.chapter of
        Just chapter ->
          (model, ChapterEditApp.Api.createChapter chapter)
        Nothing ->
          (model, Cmd.none)
    PublishNewChapter ->
      (model, Task.perform (\x -> NoOp) PublishNewChapterWithTime Time.now)
    PublishNewChapterWithTime time ->
      case model.chapter of
        Just chapter ->
          let
            updatedChapter = { chapter | published = Just <| DateTime.toISO8601 (fromTimestamp time) }
          in
            ( { model | chapter = Just updatedChapter }
            , ChapterEditApp.Api.createChapter updatedChapter
            )
        Nothing ->
          (model, Cmd.none)
    SaveNewChapterError error ->
      ({ model | banner = errorBanner "Error saving chapter" }, Cmd.none)
    SaveNewChapterSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        case resp.value of
          Http.Text text ->
            let
              chapterDecoding =
                Json.Decode.decodeString ChapterEditApp.Api.Json.parseChapter text
            in
              case chapterDecoding of
                Ok chapter ->
                  ( { model | banner = Nothing
                    }
                  , Navigation.newUrl <| "/chapters/" ++ (toString chapter.id) ++ "/edit"
                  )
                _ ->
                  ( { model | banner = errorBanner "Error parsing chapter saving result" }
                  , Cmd.none
                  )
          _ ->
            ( { model | banner = errorBanner "Error saving chapter" }
            , Cmd.none
        )
      else
        ( { model | banner = errorBanner <| "Error saving chapter, status code " ++ (toString resp.status) }
        , Cmd.none
        )
