module Common.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Common.Models exposing (Character, FullCharacter, Narration, Chapter, FileSet, ChapterMessages, MessageThread, Message, Reaction, ChapterOverview, NarrationOverview, UserInfo)


parseUserInfo : Json.Decoder UserInfo
parseUserInfo =
    Json.map3 UserInfo (field "id" int) (field "email" string) (field "role" string)


parseCharacter : Json.Decoder Character
parseCharacter =
    Json.map2 Character (field "id" int) (field "name" string)


parseFullCharacter : Json.Decoder FullCharacter
parseFullCharacter =
    Json.map3 FullCharacter (field "id" int) (field "name" string) (field "token" string)


parseFileSet : Json.Decoder FileSet
parseFileSet =
    Json.map3 FileSet
        (field "audio" <| list string)
        (field "backgroundImages" <| list string)
        (field "images" <| list string)


parseNarration : Json.Decoder Narration
parseNarration =
    Json.map6 Narration
        (field "id" int)
        (field "title" string)
        (field "characters" <| list parseFullCharacter)
        (maybe (field "defaultAudio" string))
        (maybe (field "defaultBackgroundImage" string))
        (field "files" parseFileSet)


parseChapter : Json.Decoder Chapter
parseChapter =
    Json.map8 Chapter
        (field "id" int)
        (field "narrationId" int)
        (field "title" string)
        (maybe (field "audio" string))
        (maybe (field "backgroundImage" string))
        (field "text" Json.value)
        (field "participants" <| list parseFullCharacter)
        (maybe (field "published" string))


parseMessage : Json.Decoder Message
parseMessage =
    Json.map5 Message
        (field "id" int)
        (field "body" string)
        (field "sentAt" string)
        (maybe (field "sender" parseCharacter))
        (maybe (field "recipients" <| list parseCharacter))


parseMessageThread : Json.Decoder MessageThread
parseMessageThread =
    Json.map2 MessageThread
        (field "participants" <| list parseCharacter)
        (field "messages" <| list parseMessage)


parseChapterMessages : Json.Decoder ChapterMessages
parseChapterMessages =
    Json.map2 ChapterMessages
        (field "messageThreads" <| list parseMessageThread)
        (maybe (field "characterId" int))


parseReaction : Json.Decoder Reaction
parseReaction =
    Json.map2 Reaction
        (field "character" parseCharacter)
        (maybe (field "text" string))


parseChapterOverview : Json.Decoder ChapterOverview
parseChapterOverview =
    Json.map5 ChapterOverview
        (field "id" int)
        (field "title" string)
        (field "numberMessages" int)
        (maybe (field "published" string))
        (field "reactions" <| list parseReaction)


parseNarrationOverview : Json.Decoder NarrationOverview
parseNarrationOverview =
    Json.map2 NarrationOverview
        (field "narration" parseNarration)
        (field "chapters" <| list parseChapterOverview)
