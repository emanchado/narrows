module Common.Api.Json exposing (..)

import Json.Decode as Json exposing (..)

import Common.Models exposing (Character, FullCharacter, Narration, Chapter, FileSet, ChapterMessages, MessageThread, Message, Reaction, ChapterOverview, NarrationOverview)

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

parseMessage : Json.Decoder Message
parseMessage =
  Json.object5 Message
    ("id" := int)
    ("body" := string)
    ("sentAt" := string)
    (maybe ("sender" := parseCharacter))
    (maybe ("recipients" := (list parseCharacter)))

parseMessageThread : Json.Decoder MessageThread
parseMessageThread =
  Json.object2 MessageThread
    ("participants" := list parseCharacter)
    ("messages" := list parseMessage)

parseChapterMessages : Json.Decoder ChapterMessages
parseChapterMessages =
  Json.object2 ChapterMessages
    ("messageThreads" := list parseMessageThread)
    (maybe ("characterId" := int))

parseReaction : Json.Decoder Reaction
parseReaction =
  Json.object2 Reaction
    ("character" := parseCharacter)
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
  Json.object2 NarrationOverview
    ("narration" := parseNarration)
    ("chapters" := list parseChapterOverview)
