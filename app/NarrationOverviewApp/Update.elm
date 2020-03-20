module NarrationOverviewApp.Update exposing (..)

import Dict exposing (Dict)
import Http
import Browser.Navigation as Nav
import ISO8601

import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner, FullCharacter)
import NarrationOverviewApp.Api
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    NarrationPage narrationId ->
      ( model
      , NarrationOverviewApp.Api.fetchNarrationOverview narrationId
      )

    _ ->
      ( model, Cmd.none )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    NavigateTo url ->
      (model, Nav.pushUrl model.key url)

    NarrationOverviewFetchResult (Err error) ->
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

    NarrationOverviewFetchResult (Ok narrationOverview) ->
      ( { model | narrationOverview = Just narrationOverview }
      , Cmd.none
      )

    MarkNarration status ->
      case model.narrationOverview of
        Just overview ->
          let
            narration = overview.narration
            updatedNarration = { narration | status = status }
            updatedOverview = { overview | narration = updatedNarration }
          in
            ( { model | narrationOverview = Just updatedOverview }
            , NarrationOverviewApp.Api.markNarration narration.id status
            )
        Nothing ->
          (model, Cmd.none)
    MarkNarrationResult (Err error) ->
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
    MarkNarrationResult (Ok _) ->
      (model, Cmd.none)

    ToggleURLInfoBox ->
      ( { model | showUrlInfoBox = not model.showUrlInfoBox }
      , Cmd.none
      )
