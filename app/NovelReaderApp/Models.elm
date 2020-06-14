module NovelReaderApp.Models exposing (..)

import Json.Decode
import Json.Encode
import Browser.Navigation as Nav

import Common.Models exposing (ReplyInformation, ParticipantCharacter)
import Common.Models.Reading exposing (PageState)


hasIntro : Novel -> Bool
hasIntro novel =
  novel.narration.intro /= Json.Encode.null


firstChapterIndex : Novel -> Int
firstChapterIndex novel =
  if hasIntro novel then -1 else 0


isFirstChapter : Novel -> Int -> Bool
isFirstChapter novel chapterIndex =
  let
    firstIndex = firstChapterIndex novel
  in
    chapterIndex == firstIndex


isLastChapter : Novel -> Int -> Bool
isLastChapter novel chapterIndex =
  chapterIndex == (List.length novel.chapters) - 1


novelChapterUrl : Novel -> Int -> String
novelChapterUrl novel chapterIndex =
  if chapterIndex < 0 then
    "/novels/" ++ novel.token
  else
    "/novels/" ++ novel.token ++ "/chapters/" ++ (String.fromInt chapterIndex)


findChapter : Novel -> Int -> Maybe Chapter
findChapter novel chapterIndex =
  if hasIntro novel && chapterIndex == -1 then
    Just { id = -1
         , title = novel.narration.title
         , text = novel.narration.intro
         , audio = novel.narration.introAudio
         , backgroundImage = novel.narration.introBackgroundImage
         }
  else
    List.head <| List.drop chapterIndex novel.chapters


type alias Banner =
  Common.Models.Banner


type alias Chapter =
  { id : Int
  , title : String
  , audio : Maybe String
  , backgroundImage : Maybe String
  , text : Json.Decode.Value
  }


type alias Narration =
  { id : Int
  , title : String
  , intro : Json.Decode.Value
  , introAudio : Maybe String
  , introBackgroundImage : Maybe String
  , characters : List ParticipantCharacter
  , defaultAudio : Maybe String
  , defaultBackgroundImage : Maybe String
  }


type alias Novel =
  { token : String
  , characterId : Int
  , narration : Narration
  , chapters : List Chapter
  }


type alias Model =
  { key : Nav.Key
  , state : PageState
  , novel : Maybe Novel
  , currentChapterIndex : Int
  , backgroundMusic : Bool
  , musicPlaying : Bool
  , backgroundBlurriness : Int
  , banner : Maybe Banner
  , referenceInformationVisible : Bool
  }
