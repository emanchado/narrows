module CharacterEditApp.Models exposing (..)

import Browser.Navigation as Nav
import Json.Decode
import ISO8601
import Common.Models exposing (Character, Banner)


type alias ChapterSummary =
    { id : Int
    , title : String
    }


type alias NarrationSummary =
    { id : Int
    , title : String
    , chapters : List ChapterSummary
    }


type alias CharacterInfo =
    { id : Int
    , token : String
    , displayName : Maybe String
    , name : String
    , avatar : Maybe String
    , novelToken : String
    , description : Json.Decode.Value
    , backstory : Json.Decode.Value
    , narration : NarrationSummary
    }


type alias CharacterTokenResponse =
    { token : String
    }


type alias Model =
    { key : Nav.Key
    , characterId : Int
    , characterInfo : Maybe CharacterInfo
    , newAvatarUrl : Maybe String
    , characterModified : Bool
    , showUnclaimCharacterDialog : Bool
    , showResetCharacterTokenDialog : Bool
    , showUnclaimInfoBox : Bool
    , showTokenInfoBox : Bool
    , showNovelTokenInfoBox : Bool
    , showRemoveCharacterDialog : Bool
    , banner : Maybe Banner
    }
