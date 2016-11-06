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
      , initEditor { elemId = "editor-container"
                   , text = chapter.text
                   }
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
