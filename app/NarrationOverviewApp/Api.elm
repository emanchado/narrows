module NarrationOverviewApp.Api exposing (..)

import Task
import Http
import Json.Decode as Json exposing (..)

import NarrationOverviewApp.Messages exposing (Msg, Msg(..))
import NarrationOverviewApp.Models exposing (NarrationNovel, NarrationNovelsResponse)
import Common.Api.Json exposing (parseNarrationOverview)

parseNarrationNovel : Json.Decoder NarrationNovel
parseNarrationNovel =
  Json.object4 NarrationNovel
    ("id" := int)
    ("characterId" := int)
    ("token" := string)
    ("created" := string)

parseNarrationNovelResponse : Json.Decoder NarrationNovelsResponse
parseNarrationNovelResponse =
  Json.object2 NarrationNovelsResponse
    ("narrationId" := int)
    ("novels" := list parseNarrationNovel)

fetchNarrationOverview : Int -> Cmd Msg
fetchNarrationOverview narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId) ++ "/chapters"
  in
    Task.perform NarrationOverviewFetchError NarrationOverviewFetchSuccess
      (Http.get parseNarrationOverview narrationApiUrl)

fetchNarrationNovels : Int -> Cmd Msg
fetchNarrationNovels narrationId =
  let
    narrationNovelsApiUrl = "/api/narrations/" ++ (toString narrationId) ++ "/novels"
  in
    Task.perform NarrationNovelsFetchError NarrationNovelsFetchSuccess
      (Http.get parseNarrationNovelResponse narrationNovelsApiUrl)
