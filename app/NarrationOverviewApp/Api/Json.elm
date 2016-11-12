module NarrationOverviewApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)

import Common.Models exposing (Narration, FileSet, Character)
import NarrationOverviewApp.Models exposing (NarrationOverview, ChapterOverview, Reaction)

parseCharacter : Json.Decoder Character
parseCharacter =
  Json.object3 Character ("id" := int) ("name" := string) ("token" := string)

parseFileSet : Json.Decoder FileSet
parseFileSet =
  Json.object3 FileSet
    ("audio" := list string)
    ("backgroundImages" := list string)
    ("images" := list string)

parseNarration : Json.Decoder Narration
parseNarration =
  Json.object6 Narration
    ("id" := int)
    ("title" := string)
    ("characters" := list parseCharacter)
    (maybe ("defaultAudio" := string))
    (maybe ("defaultBackgroundImage" := string))
    ("files" := parseFileSet)

parseReaction : Json.Decoder Reaction
parseReaction =
  Json.object3 Reaction
    ("chapterId" := int)
    ("characterId" := int)
    (maybe ("text" := string))

parseChapterOverview : Json.Decoder ChapterOverview
parseChapterOverview =
  Json.object5 ChapterOverview
    ("id" := int)
    ("title" := string)
    ("numberMessages" := int)
    (maybe ("published" := int))
    ("reactions" := list parseReaction)

parseNarrationOverview : Json.Decoder NarrationOverview
parseNarrationOverview =
  Json.object1 NarrationOverview
    ("chapters" := list parseChapterOverview)
