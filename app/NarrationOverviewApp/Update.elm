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
import NarrationOverviewApp.Ports exposing (copyText)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    NarrationPage narrationId ->
      ( { model | notesModified = False }
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

    RemoveNarration ->
      ( { model | showRemoveNarrationDialog = True
                , banner = Nothing
        }
      , Cmd.none
      )

    ConfirmRemoveNarration ->
      case model.narrationOverview of
        Just overview ->
          ( { model | showRemoveNarrationDialog = False }
          , NarrationOverviewApp.Api.removeNarration overview.narration.id
          )

        Nothing ->
          ( model, Cmd.none )

    CancelRemoveNarration ->
      ( { model | showRemoveNarrationDialog = False }
      , Cmd.none
      )

    RemoveNarrationResult (Err error) ->
      ( { model | banner = errorBanner "Error deleting narration" }
      , Cmd.none
      )

    RemoveNarrationResult (Ok resp) ->
      ( model
      , case model.narrationOverview of
          Just info ->
            Nav.pushUrl model.key "/"
          Nothing ->
            Cmd.none
      )

    CopyText text ->
      ( model
      , copyText text
      )

    UpdateNarrationNotes newNotes ->
      let
        updatedOverview =
          case model.narrationOverview of
            Just overview -> 
              let
                narration = overview.narration
                updatedNarration = { narration | notes = newNotes }
              in
                Just { overview | narration = updatedNarration }
            Nothing -> Nothing
      in
        ( { model | narrationOverview = updatedOverview
                  , notesModified = True
          }
        , Cmd.none
        )

    SaveNarrationNotes ->
      ( model
      , case model.narrationOverview of
          Just overview ->
            NarrationOverviewApp.Api.saveNarrationNotes
              overview.narration.id
              overview.narration.notes
          Nothing ->
            Cmd.none
      )

    SaveNarrationNotesResult (Err error) ->
      ( { model | banner = errorBanner "Error saving narration notes" }
      , Cmd.none
      )

    SaveNarrationNotesResult (Ok _) ->
      ( { model | notesModified = False
                , banner = Nothing
        }
      , Cmd.none
      )
