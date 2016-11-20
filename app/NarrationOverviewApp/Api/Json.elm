module NarrationOverviewApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)

import Common.Models exposing (Narration, FileSet, FullCharacter)
import Common.Api.Json exposing (parseFullCharacter, parseNarration)
import NarrationOverviewApp.Models exposing (NarrationOverview, ChapterOverview, Reaction)

parseReaction : Json.Decoder Reaction
parseReaction =
  Json.object2 Reaction
    ("characterId" := int)
    (maybe ("text" := string))

parseChapterOverview : Json.Decoder ChapterOverview
parseChapterOverview =
  Json.object5 ChapterOverview
    ("id" := int)
    ("title" := string)
    ("numberMessages" := int)
    (maybe ("published" := string))
    ("reactions" := list parseReaction)

parseNarrationOverview : Json.Decoder NarrationOverview
parseNarrationOverview =
  Json.object1 NarrationOverview
    ("chapters" := list parseChapterOverview)
