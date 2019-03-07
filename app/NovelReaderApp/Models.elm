module NovelReaderApp.Models exposing (..)

import Json.Decode
import Browser.Navigation as Nav

import Common.Models exposing (Character, ReplyInformation, ParticipantCharacter)
import Common.Models.Reading exposing (PageState)


findChapter : Novel -> Int -> Maybe Chapter
findChapter novel chapterIndex =
  List.head <| List.drop chapterIndex novel.chapters


isFirstChapter : Novel -> Int -> Bool
isFirstChapter novel chapterIndex =
  chapterIndex == 0


isLastChapter : Novel -> Int -> Bool
isLastChapter novel chapterIndex =
  chapterIndex == (List.length novel.chapters) - 1


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
