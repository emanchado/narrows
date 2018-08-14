module NarrationOverviewApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode

import Common.Models exposing (NarrationStatus, narrationStatusString)
import Common.Api.Json exposing (parseNarrationOverview, parseNarration, parseIso8601Date)
import NarrationOverviewApp.Messages exposing (Msg, Msg(..))
import NarrationOverviewApp.Models exposing (NarrationNovel, SendPendingIntroEmailsResponse, SendIntroDate)

parseNarrationNovel : Json.Decoder NarrationNovel
parseNarrationNovel =
  Json.map4 NarrationNovel
    (field "id" int)
    (field "characterId" int)
    (field "token" string)
    (field "created" string)


encodeNarrationStatus : NarrationStatus -> Json.Encode.Value
encodeNarrationStatus status =
    (Json.Encode.object
        [ ( "status", Json.Encode.string <| narrationStatusString status )
        ]
    )

fetchNarrationOverview : Int -> Cmd Msg
fetchNarrationOverview narrationId =
  let
    narrationApiUrl =
      "/api/narrations/" ++ (toString narrationId) ++ "/chapters"
  in
    Http.send NarrationOverviewFetchResult (Http.get narrationApiUrl parseNarrationOverview)

markNarration : Int -> NarrationStatus -> Cmd Msg
markNarration narrationId status =
  Http.send MarkNarrationResult <|
    Http.request { method = "PUT"
                 , url = "/api/narrations/" ++ (toString narrationId)
                 , headers = []
                 , body = Http.jsonBody <| encodeNarrationStatus status
                 , expect = Http.expectJson parseNarration
                 , timeout = Nothing
                 , withCredentials = False
                 }

parseSendIntroDate : Json.Decoder SendIntroDate
parseSendIntroDate =
  Json.map SendIntroDate
    (field "sendIntroDate" parseIso8601Date)

parseSendPendingIntroEmailsResponse : Json.Decoder SendPendingIntroEmailsResponse
parseSendPendingIntroEmailsResponse =
  Json.map SendPendingIntroEmailsResponse
    (field "characters" (dict parseSendIntroDate))

sendPendingIntroEmails : Int -> Cmd Msg
sendPendingIntroEmails narrationId =
  Http.send SendPendingIntroEmailsResult <|
    Http.post
      ("/api/narrations/" ++ (toString narrationId) ++ "/intro-emails")
      Http.emptyBody
      parseSendPendingIntroEmailsResponse
