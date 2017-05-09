module NovelReaderApp.Models exposing (..)

import Json.Decode
import Common.Models exposing (Character, ReplyInformation)


findChapter : Novel -> Int -> Maybe Chapter
findChapter novel chapterIndex =
    List.head <| List.drop chapterIndex novel.chapters


type alias Banner =
    Common.Models.Banner


type PageState
    = Loader
    | StartingNarration
    | Narrating


type alias ParticipantCharacter =
    { id : Int
    , name : String
    , avatar : Maybe String
    , description : Json.Decode.Value
    }


type alias Chapter =
    { id : Int
    , title : String
    , audio : String
    , backgroundImage : String
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
    { state : PageState
    , novel : Maybe Novel
    , currentChapterIndex : Int
    , backgroundMusic : Bool
    , musicPlaying : Bool
    , backgroundBlurriness : Int
    , banner : Maybe Banner
    , referenceInformationVisible : Bool
    }
