module ChapterEditApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode

import Common.Models exposing (FullCharacter, Narration, Chapter, FileSet)
import Common.Api.Json exposing (parseCharacter)

import ChapterEditApp.Models exposing (LastReactions, LastReaction, LastReactionChapter)

parseFullCharacter : Json.Decoder FullCharacter
parseFullCharacter =
  Json.object3 FullCharacter ("id" := int) ("name" := string) ("token" := string)

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

parseFileSet : Json.Decoder FileSet
parseFileSet =
  Json.object3 FileSet
    ("audio" := list string)
    ("backgroundImages" := list string)
    ("images" := list string)

parseLastReactionChapter : Json.Decoder LastReactionChapter
parseLastReactionChapter =
  Json.object2 LastReactionChapter
    ("id" := int)
    ("title" := string)

parseLastReaction : Json.Decoder LastReaction
parseLastReaction =
  Json.object3 LastReaction
    ("chapter" := parseLastReactionChapter)
    ("character" := parseCharacter)
    (maybe ("text" := string))

parseLastReactions : Json.Decoder LastReactions
parseLastReactions =
  Json.object2 LastReactions
    ("chapterId" := int)
    ("lastReactions" := list parseLastReaction)

encodeCharacter : FullCharacter -> Json.Encode.Value
encodeCharacter character =
  (Json.Encode.object [ ("id", Json.Encode.int character.id)
                      , ("name", Json.Encode.string character.name)
                      , ("token", Json.Encode.string character.token)
                      ])

encodeChapter : Chapter -> String
encodeChapter chapter =
  (Json.Encode.encode
     0
     (Json.Encode.object [ ("title", Json.Encode.string chapter.title)
                         , ("text", chapter.text)
                         , ("audio", case chapter.audio of
                                       Just audio ->
                                         Json.Encode.string audio
                                       Nothing ->
                                         Json.Encode.null)
                         , ("backgroundImage", case chapter.backgroundImage of
                                                 Just bgImage ->
                                                   Json.Encode.string bgImage
                                                 Nothing ->
                                                   Json.Encode.null)
                         , ("participants", Json.Encode.list <| List.map encodeCharacter chapter.participants)
                         , ("published", case chapter.published of
                                           Just published ->
                                             Json.Encode.string published
                                           Nothing ->
                                             Json.Encode.null)
                         ]))
