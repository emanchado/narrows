module NarrationArchiveApp.Update exposing (..)

import Http
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner)
import NarrationArchiveApp.Api
import NarrationArchiveApp.Messages exposing (..)
import NarrationArchiveApp.Models exposing (..)


urlUpdate : Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
  case route of
    NarrationArchivePage ->
      (model, NarrationArchiveApp.Api.fetchAllNarrations)

    _ ->
      (model, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    NavigateTo url ->
      (model, Nav.pushUrl model.key url)

    NarrationArchiveFetchResult (Err error) ->
      case error of
        Http.BadBody parserError ->
          ( { model | banner = errorBanner <| "Error! " ++ parserError }
          , Cmd.none
          )

        Http.BadStatus status ->
          ( { model | banner = errorBanner <| "Error! Status: " ++ (String.fromInt status) }
          , Cmd.none
          )

        _ ->
          ( { model | banner = errorBanner "Unknown error!" }
          , Cmd.none
          )

    NarrationArchiveFetchResult (Ok narratorOverview) ->
      ( { model | narrations = Just narratorOverview.narrations }
      , Cmd.none
      )
