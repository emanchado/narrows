module NarrationOverviewApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode

import Common.Models exposing (NarrationStatus, narrationStatusString)
import Common.Api.Json exposing (parseNarrationOverview, parseNarration)
import NarrationOverviewApp.Messages exposing (Msg, Msg(..))
import NarrationOverviewApp.Models exposing (NarrationNovel, NarrationNovelsResponse)

parseNarrationNovel : Json.Decoder NarrationNovel
parseNarrationNovel =
  Json.map4 NarrationNovel
    (field "id" int)
    (field "characterId" int)
    (field "token" string)
    (field "created" string)


parseNarrationNovelResponse : Json.Decoder NarrationNovelsResponse
parseNarrationNovelResponse =
  Json.map2 NarrationNovelsResponse
    (field "narrationId" int)
    (field "novels" <| list parseNarrationNovel)


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


fetchNarrationNovels : Int -> Cmd Msg
fetchNarrationNovels narrationId =
  let
    narrationNovelsApiUrl =
      "/api/narrations/" ++ (toString narrationId) ++ "/novels"
  in
    Http.send NarrationNovelsFetchResult <|
      Http.get narrationNovelsApiUrl parseNarrationNovelResponse

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

createNovel : Int -> Cmd Msg
createNovel characterId =
  let
    createNovelUrl = "/api/characters/" ++ (toString characterId) ++ "/novels"
  in
    Http.send CreateNovelResult <|
      Http.post
        createNovelUrl
        Http.emptyBody
        parseNarrationNovel
