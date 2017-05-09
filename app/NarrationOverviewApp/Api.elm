module NarrationOverviewApp.Api exposing (..)

import Task
import Http
import Json.Decode as Json exposing (..)
import NarrationOverviewApp.Messages exposing (Msg, Msg(..))
import NarrationOverviewApp.Models exposing (NarrationNovel, NarrationNovelsResponse)
import Common.Api.Json exposing (parseNarrationOverview)

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
