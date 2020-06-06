module CharacterApp.Models exposing (..)

import Browser.Navigation as Nav
import Json.Decode
import Common.Models exposing (Character, ParticipantCharacter, Banner, CharacterInfo)


type alias Model =
    { key : Nav.Key
    , characterToken : String
    , characterInfo : Maybe CharacterInfo
    , newAvatarUrl : Maybe String
    , banner : Maybe Banner
    , showNovelTip : Bool
    , showAbandonCharacterDialog : Bool
    }
