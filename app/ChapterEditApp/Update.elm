module ChapterEditApp.Update exposing (..)

import Http
import Json.Encode
import Navigation
import Task
import Process
import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime, fromTimestamp)
import Core.Routes exposing (Route(..))
import Common.Models exposing (Banner, Narration, Chapter, FileSet, errorBanner, successBanner)
import Common.Ports exposing (initEditor, renderText)
import ChapterEditApp.Api
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Models exposing (..)
import ChapterEditApp.Ports exposing (updateParticipants, playPauseAudioPreview, openFileInput, uploadFile)


updateNarrationFiles : FileSet -> ChapterEditApp.Ports.FileUploadSuccess -> FileSet
updateNarrationFiles fileSet uploadResponse =
  case uploadResponse.type_ of
    "audio" ->
      { fileSet | audio = uploadResponse.name :: fileSet.audio }

    "backgroundImages" ->
      { fileSet | backgroundImages = uploadResponse.name :: fileSet.backgroundImages }

    _ ->
      fileSet


initNewChapterCmd : Narration -> Cmd Msg
initNewChapterCmd narration =
  Task.perform (\_ -> InitNewChapter narration) (Task.succeed 1)


updateChapter : Chapter -> ChapterEditApp.Ports.FileUploadSuccess -> Chapter
updateChapter chapter uploadResponse =
  case uploadResponse.type_ of
    "audio" ->
      { chapter | audio = Just uploadResponse.name }

    "backgroundImages" ->
      { chapter | backgroundImage = Just uploadResponse.name }

    _ ->
      chapter


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    ChapterEditNarratorPage chapterId ->
      ( model
      , Cmd.batch
        [ ChapterEditApp.Api.fetchChapterInfo chapterId
        , ChapterEditApp.Api.fetchLastReactions chapterId
        ]
      )

    CreateChapterPage narrationId ->
      let
        command =
          case model.narration of
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
        , Cmd.batch
          [ command
          , ChapterEditApp.Api.fetchNarrationLastReactions narrationId
          ]
        )

    _ ->
      ( model, Cmd.none )


genericHttpErrorHandler : Model -> Http.Error -> ( Model, Cmd Msg )
genericHttpErrorHandler model error =
  let
    errorString =
      case error of
        Http.BadPayload parserError _ ->
          "Bad payload: " ++ parserError

        Http.BadStatus resp ->
          "Got status " ++ (toString resp.status) ++ " with body " ++ resp.body

        _ ->
          "Cannot connect to server"
  in
    ( { model | banner = errorBanner errorString }, Cmd.none )


showFlashMessage : Maybe Banner -> Cmd Msg
showFlashMessage maybeBanner =
  Cmd.batch
    [ Process.sleep (Time.second * 0)
      |> Task.perform (\_ -> SetFlashMessage maybeBanner)
    , Process.sleep (Time.second * 2)
      |> Task.perform (\_ -> RemoveFlashMessage)
    ]


mediaTypeString : MediaType -> String
mediaTypeString mediaType =
  case mediaType of
    Audio -> "audio"
    BackgroundImage -> "background-images"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    NavigateTo url ->
      ( model, Navigation.newUrl url )

    SetFlashMessage maybeBanner ->
      ( { model | flash = maybeBanner }
      , Cmd.none
      )

    RemoveFlashMessage ->
      ( { model | flash = Nothing }
      , Cmd.none
      )

    ChapterFetchResult (Err error) ->
      genericHttpErrorHandler model error

    ChapterFetchResult (Ok chapter) ->
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
                   , chapterParticipants = narration.characters
                   , text = Json.Encode.null
                   , editorType = "chapter"
                   , updatePortName = "editorContentChanged"
                   }
      )

    NarrationFetchResult (Err error) ->
      genericHttpErrorHandler model error

    NarrationFetchResult (Ok narration) ->
      let
        action =
          case model.chapter of
            Nothing ->
              initNewChapterCmd narration

            Just ch ->
              initEditor { elemId = "editor-container"
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

    NarrationLastReactionsFetchResult (Err error) ->
      genericHttpErrorHandler model error

    NarrationLastReactionsFetchResult (Ok lastReactions) ->
      ( { model | lastReactions = Just lastReactions }
      , Cmd.batch <|
          List.map
            (\c -> renderText { elemId = "chapter-text-" ++ (toString c.id)
                              , text = c.text
                              , proseMirrorType = "chapter"
                              })
            lastReactions.chapters
      )

    LastReactionsFetchResult (Err error) ->
      genericHttpErrorHandler model error

    LastReactionsFetchResult (Ok lastReactions) ->
      ( { model | lastReactions = Just lastReactions }
      , Cmd.batch <|
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
            newChapter =
              { chapter | title = newTitle }
          in
            ( { model | chapter = Just newChapter
                      , banner = Nothing
              }
            , Cmd.none
            )

        Nothing ->
          ( model, Cmd.none )

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
          ( model, Cmd.none )

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
          ( model, Cmd.none )

    RemoveParticipant character ->
      case model.chapter of
        Just chapter ->
          let
            updatedParticipantList =
              List.filter (\p -> p /= character) chapter.participants

            updatedChapter =
              { chapter | participants = updatedParticipantList }
          in
            ( { model | chapter = Just updatedChapter }
            , updateParticipants { editor = "editor-container"
                                 , participantList = updatedParticipantList
                                 }
            )

        Nothing ->
          ( model, Cmd.none )

    UpdateSelectedBackgroundImage imageUrl ->
      case model.chapter of
        Just chapter ->
          let
            newBgImage = if imageUrl == "" then Nothing else Just imageUrl

            updatedChapter = { chapter | backgroundImage = newBgImage }
          in
            ( { model | chapter = Just updatedChapter }, Cmd.none )

        Nothing ->
          ( model, Cmd.none )

    UpdateSelectedAudio audioUrl ->
      case model.chapter of
        Just chapter ->
          let
            newAudio = if audioUrl == "" then Nothing else Just audioUrl

            updatedChapter = { chapter | audio = newAudio }
          in
            ( { model | chapter = Just updatedChapter }, Cmd.none )

        Nothing ->
          ( model, Cmd.none )

    PlayPauseAudioPreview ->
      ( model, playPauseAudioPreview "audio-preview" )

    OpenMediaFileSelector fileInputId ->
      ( model, openFileInput fileInputId )

    AddMediaFile mediaType fileInputId ->
      case model.chapter of
        Just chapter ->
          let
            modelWithUploadFlag =
              case mediaType of
                Audio -> { model | uploadingAudio = True }
                BackgroundImage -> { model | uploadingBackgroundImage = True }
          in
            ( modelWithUploadFlag
            , uploadFile { type_ = mediaTypeString mediaType
                         , fileInputId = fileInputId
                         , narrationId = chapter.narrationId
                         }
            )

        Nothing ->
          ( model, Cmd.none )

    AddMediaFileError error ->
      let
        newBanner = errorBanner <| "Error upload media file: " ++ error.message
      in
        -- Bah. We don't know which type was uploaded, so we assume we
        -- can safely turn off both spinners. Sigh.
        ( { model | banner = newBanner
                  , uploadingAudio = False
                  , uploadingBackgroundImage = False
          }
        , Cmd.none
        )

    AddMediaFileSuccess resp ->
      case model.narration of
        Just narration ->
          case model.chapter of
            Just chapter ->
              let
                updatedFiles = updateNarrationFiles narration.files resp
                updatedNarration = { narration | files = updatedFiles }
                updatedChapter = updateChapter chapter resp
                modelWithoutUploadFlag =
                  if resp.type_ == "audio" then
                    { model | uploadingAudio = False }
                  else
                    { model | uploadingBackgroundImage = False }
              in
                ( { modelWithoutUploadFlag | narration = Just updatedNarration
                                           , chapter = Just updatedChapter
                  }
                , Cmd.none
                )

            Nothing ->
              ( model, Cmd.none )

        Nothing ->
          ( model, Cmd.none )

    SaveChapter ->
      case model.chapter of
        Just chapter ->
          ( { model | banner = Nothing, flash = Nothing }
          , ChapterEditApp.Api.saveChapter chapter
          )

        Nothing ->
          ( model, Cmd.none )

    PublishChapter ->
      ( { model | showPublishChapterDialog = True }
      , Cmd.none
      )

    CancelPublishChapter ->
      ( { model | showPublishChapterDialog = False }
      , Cmd.none
      )

    ConfirmPublishChapter ->
      ( { model | banner = Nothing
                , flash = Nothing
                , showPublishChapterDialog = False
        }
      , Task.perform PublishChapterWithTime Time.now
      )

    PublishChapterWithTime time ->
      case model.chapter of
        Just chapter ->
          let
            updatedChapter =
              { chapter | published = Just <| DateTime.toISO8601 (fromTimestamp time) }
          in
            ( { model | chapter = Just updatedChapter }
            , ChapterEditApp.Api.saveChapter updatedChapter
            )

        Nothing ->
          ( model, Cmd.none )

    SaveChapterResult (Err error) ->
      ( model, showFlashMessage <| errorBanner "Error saving chapter" )

    SaveChapterResult (Ok resp) ->
      case model.chapter of
        Just chapter ->
          if (resp.status.code >= 200) && (resp.status.code < 300) then
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
          ( model, Cmd.none )

    SaveNewChapter ->
      case model.chapter of
        Just chapter ->
          ( { model | savingChapter = True }
          , if model.savingChapter then
              Cmd.none
            else
              ChapterEditApp.Api.createChapter chapter
          )

        Nothing ->
          ( model, Cmd.none )

    PublishNewChapter ->
      ( { model | savingChapter = True }
      , if model.savingChapter then
          Cmd.none
        else
          Task.perform PublishNewChapterWithTime Time.now
      )

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
          ( model, Cmd.none )

    SaveNewChapterResult (Err error) ->
      ( { model | banner = errorBanner "Error saving chapter"
                , savingChapter = False
        }
      , Cmd.none
      )

    SaveNewChapterResult (Ok chapter) ->
      ( { model | banner = Nothing
                , savingChapter = False
        }
      , Navigation.newUrl <| "/chapters/" ++ (toString chapter.id) ++ "/edit"
      )
