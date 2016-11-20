module ChapterControlApp.Update exposing (..)

import Http

import Routing
import Common.Models exposing (Banner)
import Common.Ports exposing (renderChapter)

import ChapterControlApp.Api
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (..)


errorBanner : String -> Maybe Banner
errorBanner errorMessage =
  Just { text = errorMessage
       , type' = "error"
       }

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.ChapterControlPage chapterId ->
        ( model
        , Cmd.batch [ ChapterControlApp.Api.fetchChapterInteractions chapterId
                    -- , ChapterControlApp.Api.fetchChapter chapterId
                    ]
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    ChapterInteractionsFetchError error ->
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
    ChapterInteractionsFetchSuccess interactions ->
      ( { model | interactions = Just interactions }
      , renderChapter { elemId = "chapter-text"
                      , text = interactions.chapter.text
                      }
      )
