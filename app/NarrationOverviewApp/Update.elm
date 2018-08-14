module NarrationOverviewApp.Update exposing (..)

import Dict exposing (Dict)
import Http
import Navigation
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

cleanCharacterDict : Dict String SendIntroDate -> Dict Int ISO8601.Time
cleanCharacterDict origDict =
  let
    serialisedOrig = Dict.toList origDict
  in
    Dict.fromList <|
      List.map
        (\(stringId, sendIntroDate) -> ((Result.withDefault 0 <| String.toInt stringId), sendIntroDate.sendIntroDate))
        serialisedOrig

updateCharactersSendIntro : List FullCharacter -> Dict String SendIntroDate -> List FullCharacter
updateCharactersSendIntro characters updatedTimes =
  let
    cleanDict = cleanCharacterDict updatedTimes
  in
    List.map
      (\character -> if Dict.member character.id cleanDict then
                       { character | introSent = Dict.get character.id cleanDict }
                     else
                       character)
      characters

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

    SendPendingIntroEmails ->
      case model.narrationOverview of
        Just overview ->
          let
            narration = overview.narration
          in
            ( { model | sendingPendingIntroEmails = True }
            , NarrationOverviewApp.Api.sendPendingIntroEmails narration.id
            )
        Nothing ->
          (model, Cmd.none)

    SendPendingIntroEmailsResult (Err error) ->
      ( { model | sendingPendingIntroEmails = False }
      , Cmd.none
      )

    SendPendingIntroEmailsResult (Ok response) ->
      case model.narrationOverview of
        Just overview ->
          let
            updatedCharacters = updateCharactersSendIntro overview.narration.characters response.characters
            overviewNarration = overview.narration
            updatedNarration = { overviewNarration | characters = updatedCharacters }
            updatedOverview = { overview | narration = updatedNarration }
          in
            ( { model | narrationOverview = Just updatedOverview
                      , sendingPendingIntroEmails = False
              }
            , Cmd.none
            )
        Nothing ->
          ( { model | sendingPendingIntroEmails = False }
          , Cmd.none
          )
