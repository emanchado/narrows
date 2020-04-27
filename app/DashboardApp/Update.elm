module DashboardApp.Update exposing (..)

import Http
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner)
import DashboardApp.Api
import DashboardApp.Messages exposing (..)
import DashboardApp.Models exposing (Model, DashboardScreen(..))


urlUpdate : Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
  case route of
    Dashboard ->
      ({ model | screen = IndexScreen
               , banner = Nothing
       }
      , DashboardApp.Api.fetchNarratorOverview
      )

    NarrationArchivePage ->
      ({ model | screen = NarrationArchiveScreen
               , banner = Nothing
       }
      , DashboardApp.Api.fetchAllNarrations
      )

    CharacterArchivePage ->
      ({ model | screen = CharacterArchiveScreen
               , banner = Nothing
       }
      , DashboardApp.Api.fetchAllCharacters
      )

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
      ( { model | allNarrations = Just narratorOverview.narrations }
      , Cmd.none
      )

    CharacterArchive ->
      (model, Nav.pushUrl model.key "/characters")

    CharacterArchiveFetchResult (Err error) ->
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

    CharacterArchiveFetchResult (Ok narratorOverview) ->
      ( { model | allCharacters = Just narratorOverview.characters }
      , Cmd.none
      )
