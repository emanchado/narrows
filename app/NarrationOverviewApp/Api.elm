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

encodeNarrationNotes : String -> Json.Encode.Value
encodeNarrationNotes notes =
    (Json.Encode.object
        [ ( "notes", Json.Encode.string notes )
        ]
    )

fetchNarrationOverview : Int -> Cmd Msg
fetchNarrationOverview narrationId =
  let
    narrationApiUrl =
      "/api/narrations/" ++ (String.fromInt narrationId) ++ "/chapters"
  in
    Http.get { url = narrationApiUrl
             , expect = Http.expectJson NarrationOverviewFetchResult parseNarrationOverview
             }


markNarration : Int -> NarrationStatus -> Cmd Msg
markNarration narrationId status =
  Http.request { method = "PUT"
               , headers = []
               , url = "/api/narrations/" ++ (String.fromInt narrationId)
               , body = Http.jsonBody <| encodeNarrationStatus status
               , expect = Http.expectJson MarkNarrationResult parseNarration
               , timeout = Nothing
               , tracker = Nothing
               }


removeNarration : Int -> Cmd Msg
removeNarration narrationId =
  Http.request { method = "DELETE"
               , url = "/api/narrations/" ++ (String.fromInt narrationId)
               , headers = []
               , body = Http.emptyBody
               , expect = Http.expectWhatever RemoveNarrationResult
               , timeout = Nothing
               , tracker = Nothing
               }


saveNarrationNotes : Int -> String -> Cmd Msg
saveNarrationNotes narrationId notes =
  Http.request { method = "PUT"
               , headers = []
               , url = "/api/narrations/" ++ (String.fromInt narrationId)
               , body = Http.jsonBody <| encodeNarrationNotes notes
               , expect = Http.expectJson SaveNarrationNotesResult parseNarration
               , timeout = Nothing
               , tracker = Nothing
               }
