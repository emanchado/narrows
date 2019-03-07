module CharacterApp.Models exposing (..)

import Browser.Navigation as Nav
import Json.Decode
import Common.Models exposing (Character, ParticipantCharacter, Banner)


type alias ChapterSummary =
    { id : Int
    , title : String
    }


type alias NarrationSummary =
    { id : Int
    , title : String
    , chapters : List ChapterSummary
    , characters : List ParticipantCharacter
    }


type alias CharacterInfo =
    { id : Int
    , name : String
    , avatar : Maybe String
    , novelToken : String
    , description : Json.Decode.Value
    , backstory : Json.Decode.Value
    , narration : NarrationSummary
    }


type alias Model =
    { key : Nav.Key
    , characterToken : String
    , characterInfo : Maybe CharacterInfo
    , newAvatarUrl : Maybe String
    , banner : Maybe Banner
    , showNovelTip : Bool
    }
