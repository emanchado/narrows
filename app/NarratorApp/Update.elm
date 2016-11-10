module NarratorApp.Update exposing (..)

import Http

import Routing
import NarratorApp.Api
import NarratorApp.Messages exposing (..)
import NarratorApp.Models exposing (..)
import NarratorApp.Ports exposing (initEditor)


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
        ( { model | banner = Just { type' = "error", text = Debug.log "ERROR" errorString } }
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
        ( { model | banner = Just { type' = "error", text = Debug.log "ERROR" errorString } }
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
                               } }
      , Cmd.none)
    AddParticipantSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        (model, Cmd.none)
      else
        ({ model | banner = Just { text = "Error adding participant"
                                 , type' = "error"
                                 } }
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
                               } }
      , Cmd.none)
    RemoveParticipantSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        (model, Cmd.none)
      else
        ({ model | banner = Just { text = "Error removing participant"
                                 , type' = "error"
                                 } }
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

    SaveChapter ->
      case model.chapter of
        Just chapter ->
          (model, NarratorApp.Api.saveChapter chapter)
        Nothing ->
          (model, Cmd.none)
    SaveChapterError error ->
      ({ model | banner = Just { text = "Error saving chapter"
                               , type' = "error"
                               } }
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
