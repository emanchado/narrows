module NarratorApp.Update exposing (..)

import Http

import Routing
import NarratorApp.Api
import NarratorApp.Messages exposing (..)
import NarratorApp.Models exposing (..)


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
      ({ model | chapter = Just chapter }, Cmd.none)
