module DashboardApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Common.Api.Json exposing (parseNarrationOverview, parseCharacterInfo)
import DashboardApp.Models exposing (NarratorOverview, NarrationArchive, CharacterArchive)


parseNarratorOverview : Json.Decoder NarratorOverview
parseNarratorOverview =
    Json.map2 NarratorOverview
        (field "narrations" <| list parseNarrationOverview)
        (field "characters" <| list parseCharacterInfo)


parseNarrationArchive : Json.Decoder NarrationArchive
parseNarrationArchive =
    Json.map NarrationArchive
        (field "narrations" <| list parseNarrationOverview)


parseCharacterArchive : Json.Decoder CharacterArchive
parseCharacterArchive =
    Json.map CharacterArchive
        (field "characters" <| list parseCharacterInfo)
