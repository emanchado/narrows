module NarrationOverviewApp.Update exposing (..)

import Http
import Navigation

import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner)
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
      (model, Navigation.newUrl url)

    NarrationOverviewFetchResult (Err error) ->
      case error of
        Http.BadPayload parserError resp ->
          ( { model | banner = errorBanner <| "Error! " ++ parserError }
          , Cmd.none
          )

        Http.BadStatus resp ->
          ( { model | banner = errorBanner <| "Error! Body: " ++ resp.body }
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
        Http.BadPayload parserError resp ->
          ( { model | banner = errorBanner <| "Error! " ++ parserError }
          , Cmd.none
          )

        Http.BadStatus resp ->
          ( { model | banner = errorBanner <| "Error! Body: " ++ resp.body }
          , Cmd.none
          )

        _ ->
          ( { model | banner = errorBanner "Unknown error!" }
          , Cmd.none
          )
    MarkNarrationResult (Ok _) ->
      (model, Cmd.none)
