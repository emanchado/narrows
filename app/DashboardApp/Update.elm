module DashboardApp.Update exposing (..)

import Http
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner)
import DashboardApp.Api
import DashboardApp.Messages exposing (..)
import DashboardApp.Models exposing (..)


urlUpdate : Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
  case route of
    Dashboard ->
      (model, DashboardApp.Api.fetchNarratorOverview)

    _ ->
      (model, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    NavigateTo url ->
      (model, Nav.pushUrl model.key url)

    NarratorOverviewFetchResult (Err error) ->
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

    NarratorOverviewFetchResult (Ok narratorOverview) ->
      ( { model | narrations = Just narratorOverview.narrations
                , characters = Just narratorOverview.characters
        }
      , Cmd.none
      )

    NarrationArchive ->
      (model, Nav.pushUrl model.key "/narrations")

    NewNarration ->
      (model, Nav.pushUrl model.key "/narrations/new")
