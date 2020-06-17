module Common.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import ISO8601
import Common.Models exposing (Character, ParticipantCharacter, FullCharacter, Narration, NarrationStatus(..), Chapter, FileSet, ChapterMessages, MessageThread, Message, ChapterOverview, NarrationOverview, UserInfo, CharacterInfo, ChapterSummary, NarrationSummary, StyleSet)


parseUserInfo : Json.Decoder UserInfo
parseUserInfo =
    Json.map6 UserInfo
      (field "id" int)
      (field "email" string)
      (field "displayName" string)
      (field "role" string)
      (field "verified" bool)
      (field "created" parseIso8601Date)


parseCharacter : Json.Decoder Character
parseCharacter =
    Json.map3 Character
      (field "id" int)
      (field "name" string)
      (maybe (field "avatar" string))


parseParticipantCharacter : Json.Decoder ParticipantCharacter
parseParticipantCharacter =
    Json.map5 ParticipantCharacter
        (field "id" int)
        (field "name" string)
        (field "claimed" bool)
        (maybe (field "avatar" string))
        (field "description" Json.value)


parseIso8601Date : Json.Decoder ISO8601.Time
parseIso8601Date =
  let
    convert : String -> Decoder ISO8601.Time
    convert stringTimestamp =
      case ISO8601.fromString stringTimestamp of
        Ok iso8601Time ->
          succeed iso8601Time
        Err message ->
          fail <| "Cannot parse timestamp '" ++ stringTimestamp ++ "': " ++ message
  in
    string |> andThen convert


parseFullCharacter : Json.Decoder FullCharacter
parseFullCharacter =
    Json.map6 FullCharacter
      (field "id" int)
      (field "name" string)
      (maybe (field "displayName" string))
      (field "token" string)
      (field "novelToken" string)
      (maybe (field "avatar" string))


parseFileSet : Json.Decoder FileSet
parseFileSet =
    Json.map4 FileSet
        (field "audio" <| list string)
        (field "backgroundImages" <| list string)
        (field "images" <| list string)
        (field "fonts" <| list string)


parseNarrationStatus : Json.Decoder NarrationStatus
parseNarrationStatus =
  let
    convert : String -> Decoder NarrationStatus
    convert raw =
      case raw of
        "active" -> succeed Active
        "finished" -> succeed Finished
        "abandoned" -> succeed Abandoned
        _ -> fail <| "Unknown narration status " ++ raw
  in
    string |> andThen convert


parseStyleSet : Json.Decoder StyleSet
parseStyleSet =
    Json.map8 StyleSet
        (maybe (field "titleFont" string))
        (maybe (field "titleFontSize" string))
        (maybe (field "titleColor" string))
        (maybe (field "titleShadowColor" string))
        (maybe (field "bodyTextFont" string))
        (maybe (field "bodyTextFontSize" string))
        (maybe (field "bodyTextColor" string))
        (maybe (field "bodyTextBackgroundColor" string))
    |> andThen (\r ->
                  Json.map r
                    (maybe (field "separatorImage" string)))


parseNarration : Json.Decoder Narration
parseNarration =
    Json.map8 Narration
        (field "id" int)
        (field "title" string)
        (field "status" parseNarrationStatus)
        (field "intro" Json.value)
        (field "introUrl" string)
        (maybe (field "introAudio" string))
        (maybe (field "introBackgroundImage" string))
        (field "notes" string)
    |> andThen (\r ->
               Json.map5 r
                 (field "characters" <| list parseFullCharacter)
                 (maybe (field "defaultAudio" string))
                 (maybe (field "defaultBackgroundImage" string))
                 (field "files" parseFileSet)
                 (field "styles" parseStyleSet))


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
        (field "sentAt" parseIso8601Date)
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


parseChapterOverview : Json.Decoder ChapterOverview
parseChapterOverview =
    Json.map6 ChapterOverview
        (field "id" int)
        (field "title" string)
        (maybe (field "published" string))
        (field "participants" <| list parseCharacter)
        (field "activeUsers" <| list parseCharacter)
        (field "numberMessages" int)


parseNarrationOverview : Json.Decoder NarrationOverview
parseNarrationOverview =
    Json.map2 NarrationOverview
        (field "narration" parseNarration)
        (field "chapters" <| list parseChapterOverview)


parseChapterSummary : Json.Decoder ChapterSummary
parseChapterSummary =
    Json.map2 ChapterSummary
        (field "id" int)
        (field "title" string)


parseNarrationSummary : Json.Decoder NarrationSummary
parseNarrationSummary =
    Json.map5 NarrationSummary
        (field "id" int)
        (field "title" string)
        (field "status" parseNarrationStatus)
        (field "chapters" <| list parseChapterSummary)
        (field "characters" <| list parseParticipantCharacter)


parseCharacterInfo : Json.Decoder CharacterInfo
parseCharacterInfo =
    Json.map8 CharacterInfo
        (field "id" int)
        (field "name" string)
        (maybe (field "avatar" string))
        (field "token" string)
        (field "novelToken" string)
        (field "description" Json.value)
        (field "backstory" Json.value)
        (field "narration" parseNarrationSummary)
