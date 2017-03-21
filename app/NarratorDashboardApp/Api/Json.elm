module NarratorDashboardApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)

import Common.Api.Json exposing (parseReaction, parseNarrationOverview)
import Common.Models exposing (NarrationOverview, ChapterOverview)
import NarratorDashboardApp.Models exposing (NarratorOverview)

parseChapterOverview : Json.Decoder ChapterOverview
parseChapterOverview =
  Json.object5 ChapterOverview
    ("id" := int)
    ("title" := string)
    ("numberMessages" := int)
    (maybe ("published" := string))
    ("reactions" := list parseReaction)

parseNarratorOverview : Json.Decoder NarratorOverview
parseNarratorOverview =
  Json.object1 NarratorOverview
    ("narrations" := list parseNarrationOverview)
