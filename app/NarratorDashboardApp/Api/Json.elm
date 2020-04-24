module NarratorDashboardApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Common.Api.Json exposing (parseNarrationOverview, parseCharacterInfo)
import NarratorDashboardApp.Models exposing (NarratorOverview)


parseNarratorOverview : Json.Decoder NarratorOverview
parseNarratorOverview =
    Json.map2 NarratorOverview
        (field "narrations" <| list parseNarrationOverview)
        (field "characters" <| list parseCharacterInfo)
