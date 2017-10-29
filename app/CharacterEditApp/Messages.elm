module CharacterEditApp.Messages exposing (..)

import Http
import Json.Encode
import CharacterEditApp.Models exposing (..)
import CharacterEditApp.Ports


type Msg
    = NoOp
    | NavigateTo String
    | CharacterFetchResult (Result Http.Error CharacterInfo)
    | UpdateCharacterName String
    | UpdateCharacterAvatar String
    | ReceiveAvatarAsUrl String
    | UploadAvatarError CharacterEditApp.Ports.UploadError
    | UploadAvatarSuccess String
    | UpdateDescriptionText Json.Encode.Value
    | UpdateBackstoryText Json.Encode.Value
    | UpdatePlayerEmail String
    | SaveCharacter
    | SaveCharacterResult (Result Http.Error (Http.Response String))
