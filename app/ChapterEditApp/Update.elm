module ChapterEditApp.Update exposing (..)

import Http
import Json.Encode
import Browser.Navigation as Nav
import Task
import Process
import ISO8601 exposing (Time)
import Time exposing (utc, toYear, toMonth, toDay, toHour, toMinute, toSecond)

import Core.Routes exposing (Route(..))
import Common.Models exposing (Banner, Narration, Chapter, FileSet, FileUploadError, FileUploadSuccess, MediaType(..), errorBanner, successBanner, mediaTypeString, updateNarrationFiles)
import Common.Ports exposing (initEditor, renderText, openFileInput, uploadFile)
import ChapterEditApp.Api
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Models exposing (..)
import ChapterEditApp.Ports exposing (updateParticipants, playPauseAudioPreview)


initNewChapterCmd : Narration -> Cmd Msg
initNewChapterCmd narration =
  Task.perform (\_ -> InitNewChapter narration) (Task.succeed 1)


updateChapter : Chapter -> FileUploadSuccess -> Chapter
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
                  , lastChapters = Nothing
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
        Http.BadBody parserError ->
          "Bad payload: " ++ parserError

        Http.BadStatus status ->
          "Got status " ++ (String.fromInt status)

        _ ->
          "Cannot connect to server"
  in
    ( { model | banner = errorBanner errorString }, Cmd.none )


showFlashMessage : Maybe Banner -> Cmd Msg
showFlashMessage maybeBanner =
  Cmd.batch
    [ Process.sleep 0
      |> Task.perform (\_ -> SetFlashMessage maybeBanner)
    , Process.sleep 2000
      |> Task.perform (\_ -> RemoveFlashMessage)
    ]


toMonthNumber : Time.Month -> Int
toMonthNumber month =
  case month of
    Time.Jan -> 1
    Time.Feb -> 2
    Time.Mar -> 3
    Time.Apr -> 4
    Time.May -> 5
    Time.Jun -> 6
    Time.Jul -> 7
    Time.Aug -> 8
    Time.Sep -> 9
    Time.Oct -> 10
    Time.Nov -> 11
    Time.Dec -> 12


toUtcString : Time.Posix -> String
toUtcString time =
  String.fromInt (toYear utc time)
  ++ "-" ++
  String.padLeft 2 '0' (String.fromInt (toMonthNumber <| toMonth utc time))
  ++ "-" ++
  String.padLeft 2 '0' (String.fromInt (toDay utc time))
  ++ " " ++
  String.padLeft 2 '0' (String.fromInt (toHour utc time))
  ++ ":" ++
  String.padLeft 2 '0' (String.fromInt (toMinute utc time))
  ++ ":" ++
  String.padLeft 2 '0' (String.fromInt (toSecond utc time))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    NavigateTo url ->
      ( model, Nav.pushUrl model.key url )

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
      ( { model | lastChapters = Just lastReactions.lastChapters }
      , Cmd.batch <|
          List.map
            (\c -> renderText { elemId = "chapter-text-" ++ (String.fromInt c.id)
                              , text = c.text
                              , proseMirrorType = "chapter"
                              })
            lastReactions.lastChapters
      )

    LastReactionsFetchResult (Err error) ->
      genericHttpErrorHandler model error

    LastReactionsFetchResult (Ok lastReactions) ->
      ( { model | lastChapters = Just lastReactions.lastChapters }
      , Cmd.batch <|
          (List.map
             (\c -> renderText { elemId = "chapter-text-" ++ (String.fromInt c.id)
                               , text = c.text
                               , proseMirrorType = "chapter"
                               })
             lastReactions.lastChapters)
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
                         , portType = "chapterEdit"
                         , fileInputId = fileInputId
                         , narrationId = chapter.narrationId
                         }
            )

        Nothing ->
          ( model, Cmd.none )

    AddMediaFileError error ->
      -- Bah. We don't know which type was uploaded, so we assume we
      -- can safely turn off both spinners. Sigh.
      ( { model | banner = errorBanner error.message
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
            publishTimestamp = Just <| toUtcString time
            updatedChapter =
              { chapter | published = publishTimestamp }
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
          case resp of
            Http.GoodStatus_ _ _ ->
              case chapter.published of
                Just published ->
                  ( model
                  , Nav.pushUrl model.key <| "/chapters/" ++ (String.fromInt chapter.id)
                  )

                Nothing ->
                  ( model
                  , showFlashMessage <| successBanner "Saved"
                  )
            Http.BadStatus_ metadata _ ->
              ( model
              , showFlashMessage <| errorBanner <| "Error saving chapter, status code " ++ (String.fromInt metadata.statusCode)
              )

            _ ->
              ( model
              , showFlashMessage <| errorBanner <| "Error saving chapter, network error"
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
            publishTimestamp = Just <| toUtcString time
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
      , Nav.pushUrl model.key <| "/chapters/" ++ (String.fromInt chapter.id) ++ "/edit"
      )
