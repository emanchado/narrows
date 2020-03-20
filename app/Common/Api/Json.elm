module Common.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import ISO8601
import Common.Models exposing (Character, ParticipantCharacter, FullCharacter, Narration, NarrationStatus(..), Chapter, FileSet, ChapterMessages, MessageThread, Message, ChapterOverview, NarrationOverview, UserInfo)


parseUserInfo : Json.Decoder UserInfo
parseUserInfo =
    Json.map3 UserInfo
      (field "id" int)
      (field "email" string)
      (field "role" string)


parseCharacter : Json.Decoder Character
parseCharacter =
    Json.map2 Character (field "id" int) (field "name" string)


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
      (maybe (field "email" string))
      (field "token" string)
      (field "novelToken" string)
      (maybe (field "avatar" string))


parseFileSet : Json.Decoder FileSet
parseFileSet =
    Json.map3 FileSet
        (field "audio" <| list string)
        (field "backgroundImages" <| list string)
        (field "images" <| list string)


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
        (field "characters" <| list parseFullCharacter)
    |> andThen (\r ->
               Json.map3 r
                 (maybe (field "defaultAudio" string))
                 (maybe (field "defaultBackgroundImage" string))
                 (field "files" parseFileSet))


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
