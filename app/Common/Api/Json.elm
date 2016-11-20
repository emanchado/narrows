module Common.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
-- import Json.Encode

import Common.Models exposing (Character, FullCharacter, Narration, Chapter, FileSet)

parseCharacter : Json.Decoder Character
parseCharacter =
  Json.object2 Character ("id" := int) ("name" := string)

parseFullCharacter : Json.Decoder FullCharacter
parseFullCharacter =
  Json.object3 FullCharacter ("id" := int) ("name" := string) ("token" := string)

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
    ("characters" := list parseFullCharacter)
    (maybe ("defaultAudio" := string))
    (maybe ("defaultBackgroundImage" := string))
    ("files" := parseFileSet)

parseChapter : Json.Decoder Chapter
parseChapter =
  Json.object8 Chapter
    ("id" := int)
    ("narrationId" := int)
    ("title" := string)
    (maybe ("audio" := string))
    (maybe ("backgroundImage" := string))
    ("text" := Json.value)
    ("participants" := list parseFullCharacter)
    (maybe ("published" := string))
