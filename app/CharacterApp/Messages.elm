module CharacterApp.Messages exposing (..)

import Http
import Json.Encode
import Common.Models exposing (CharacterInfo)
import CharacterApp.Ports


type Msg
    = NoOp
    | NavigateTo String
    | CharacterFetchResult (Result Http.Error CharacterInfo)
    | UpdateCharacterName String
    | UpdateCharacterAvatar String
    | ReceiveAvatarAsUrl String
    | UploadAvatarError CharacterApp.Ports.UploadError
    | UploadAvatarSuccess String
    | UpdateDescriptionText Json.Encode.Value
    | UpdateBackstoryText Json.Encode.Value
    | SaveCharacter
    | SaveCharacterResult (Result Http.Error (Http.Response String))
    | ToggleNovelTip
    | AbandonCharacter
    | ConfirmAbandonCharacter
    | CancelAbandonCharacter
    | AbandonCharacterResult (Result Http.Error (Http.Response String))
