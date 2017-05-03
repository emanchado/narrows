module ChapterEditApp.Update exposing (..)

import Http
import Json.Decode
import Json.Encode
import Navigation
import Task
import Process
import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime, fromTimestamp)

import Routing
import Common.Models exposing (Banner, Narration, Chapter, FileSet, errorBanner, successBanner)
import Common.Ports exposing (initEditor, renderText)

import ChapterEditApp.Api
import ChapterEditApp.Api.Json exposing (parseChapter)
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Models exposing (..)
import ChapterEditApp.Ports exposing (updateParticipants, playPauseAudioPreview, openFileInput, uploadFile)


updateNarrationFiles : FileSet -> ChapterEditApp.Ports.FileUploadSuccess -> FileSet
updateNarrationFiles fileSet uploadResponse =
  case uploadResponse.type' of
    "audio" ->
      { fileSet | audio = uploadResponse.name :: fileSet.audio }
    "backgroundImages" ->
      { fileSet | backgroundImages = uploadResponse.name :: fileSet.backgroundImages }
    _ ->
      fileSet


initNewChapterCmd : Narration -> Cmd Msg
initNewChapterCmd narration =
  Task.perform (\_ -> NoOp) (\_ -> InitNewChapter narration) (Task.succeed 1)

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
        , Cmd.batch [ ChapterEditApp.Api.fetchChapterInfo chapterId
                    , ChapterEditApp.Api.fetchLastReactions chapterId
                    ]
        )
      Routing.CreateChapterPage narrationId ->
        let
          command = case model.narration of
                      Just narration ->
                        if narration.id == narrationId then
                          initNewChapterCmd narration
                        else
                          ChapterEditApp.Api.fetchNarrationInfo narrationId
                      Nothing ->
                        ChapterEditApp.Api.fetchNarrationInfo narrationId
        in
          ( { model | chapter = Nothing
                    , lastReactions = Nothing
            }
          , Cmd.batch [ command
                      , ChapterEditApp.Api.fetchNarrationLastReactions narrationId
                      ]
          )
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
                      "Cannot connect to server"
  in
    ({ model | banner = errorBanner errorString }, Cmd.none)

showFlashMessage : Maybe Banner -> Cmd Msg
showFlashMessage maybeBanner =
  Cmd.batch
    [ Process.sleep (Time.second * 0)
        |> Task.perform (\_ -> SetFlashMessage maybeBanner) (\_ -> SetFlashMessage maybeBanner)
    , Process.sleep (Time.second * 2)
        |> Task.perform (\_ -> RemoveFlashMessage) (\_ -> RemoveFlashMessage)
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    NavigateTo url ->
      (model, Navigation.newUrl url)
    SetFlashMessage maybeBanner ->
      ( { model | flash = maybeBanner }
      , Cmd.none
      )
    RemoveFlashMessage ->
      ( { model | flash = Nothing }
      , Cmd.none
      )
    ChapterFetchError error ->
      genericHttpErrorHandler model error
    ChapterFetchSuccess chapter ->
      ( { model | chapter = Just chapter }
      , ChapterEditApp.Api.fetchNarrationInfo chapter.narrationId
      )
    InitNewChapter narration ->
      ( { model | chapter = Just (newEmptyChapter narration)
                , banner = Nothing
                , flash = Nothing
        }
      , initEditor { elemId = "editor-container"
                   , narrationId = narration.id
                   , narrationImages = narration.files.images
                   , chapterParticipants = []
                   , text = Json.Encode.null
                   , editorType = "chapter"
                   , updatePortName = "editorContentChanged"
                   }
      )
    NarrationFetchError error ->
      genericHttpErrorHandler model error
    NarrationFetchSuccess narration ->
      let
        action =
          case model.chapter of
            Nothing -> initNewChapterCmd narration
            Just ch -> initEditor { elemId = "editor-container"
                                  , narrationId = narration.id
                                  , narrationImages = narration.files.images
                                  , chapterParticipants = ch.participants
                                  , text = ch.text
                                  , editorType = "chapter"
                                  , updatePortName = "editorContentChanged"
                                  }
      in
        ( { model | narration = Just narration }
        , action
        )
    NarrationLastReactionsFetchError error ->
      genericHttpErrorHandler model error
    NarrationLastReactionsFetchSuccess lastReactions ->
      ( { model | lastReactions = Just <| Debug.log "Last narration reactions" lastReactions }
      , Cmd.batch
          (List.map
             (\c -> renderText { elemId = "chapter-text-" ++ (toString c.id)
                               , text = c.text
                               , proseMirrorType = "chapter"
                               })
             lastReactions.chapters)
      )
    LastReactionsFetchError error ->
      genericHttpErrorHandler model error
    LastReactionsFetchSuccess lastReactions ->
      ( { model | lastReactions = Just lastReactions }
      , Cmd.batch
          (List.map
             (\c -> renderText { elemId = "chapter-text-" ++ (toString c.id)
                               , text = c.text
                               , proseMirrorType = "chapter"
                               })
             lastReactions.chapters)
      )

    UpdateChapterTitle newTitle ->
      case model.chapter of
        Just chapter ->
          let
            newChapter = { chapter | title = newTitle }
          in
            ( { model | chapter = Just newChapter
                      , banner = Nothing
              }
            , Cmd.none
            )
        Nothing ->
          (model, Cmd.none)
    UpdateEditorContent newText ->
      case model.chapter of
        Just chapter ->
          let
            updatedChapter = { chapter | text = newText }
          in
            ( { model | chapter = Just updatedChapter
                      , banner = Nothing
              }
            , Cmd.none
            )
        Nothing ->
          (model, Cmd.none)

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
            , updateParticipants { editor = "editor-container"
                                 , participantList = participantsWithCharacter
                                 }
            )
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
            ( { model | chapter = Just chapterWithoutCharacter }
            , updateParticipants { editor = "editor-container"
                                 , participantList = participantsWithoutCharacter
                                 }
            )
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
          ({ model | banner = Nothing, flash = Nothing }
           , ChapterEditApp.Api.saveChapter chapter
           )
        Nothing ->
          (model, Cmd.none)
    PublishChapter ->
      ({ model | banner = Nothing, flash = Nothing }
      , Task.perform (\_ -> NoOp) PublishChapterWithTime Time.now
      )
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
      (model, showFlashMessage <| errorBanner "Error saving chapter")
    SaveChapterSuccess resp ->
      case model.chapter of
        Just chapter ->
          if (resp.status >= 200) && (resp.status < 300) then
            case chapter.published of
              Just published ->
                ( model
                , Navigation.newUrl <| "/chapters/" ++ (toString chapter.id)
                )
              Nothing ->
                ( model
                , showFlashMessage <| successBanner "Saved"
                )
          else
            ( model
            , showFlashMessage <| errorBanner <| "Error saving chapter, status code " ++ (toString resp.status)
            )
        Nothing ->
          (model, Cmd.none)

    SaveNewChapter ->
      case model.chapter of
        Just chapter ->
          (model, ChapterEditApp.Api.createChapter chapter)
        Nothing ->
          (model, Cmd.none)
    PublishNewChapter ->
      (model, Task.perform (\_ -> NoOp) PublishNewChapterWithTime Time.now)
    PublishNewChapterWithTime time ->
      case model.chapter of
        Just chapter ->
          let
            publishTimestamp = Just <| DateTime.toISO8601 (fromTimestamp time)
            updatedChapter = { chapter | published = publishTimestamp }
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
