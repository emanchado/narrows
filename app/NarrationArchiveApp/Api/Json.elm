module NarrationArchiveApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Common.Api.Json exposing (parseReaction, parseNarrationOverview)
import Common.Models exposing (NarrationOverview, ChapterOverview)
import NarrationArchiveApp.Models exposing (NarrationArchive)


parseNarrationArchive : Json.Decoder NarrationArchive
parseNarrationArchive =
    Json.map NarrationArchive
        (field "narrations" <| list parseNarrationOverview)
