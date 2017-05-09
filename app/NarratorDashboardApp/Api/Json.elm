module NarratorDashboardApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Common.Api.Json exposing (parseReaction, parseNarrationOverview)
import Common.Models exposing (NarrationOverview, ChapterOverview)
import NarratorDashboardApp.Models exposing (NarratorOverview)


parseChapterOverview : Json.Decoder ChapterOverview
parseChapterOverview =
    Json.map5 ChapterOverview
        (field "id" int)
        (field "title" string)
        (field "numberMessages" int)
        (maybe (field "published" string))
        (field "reactions" <| list parseReaction)


parseNarratorOverview : Json.Decoder NarratorOverview
parseNarratorOverview =
    Json.map NarratorOverview
        (field "narrations" <| list parseNarrationOverview)
