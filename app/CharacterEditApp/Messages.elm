module CharacterEditApp.Messages exposing (..)

import Http
import Json.Encode
import Browser
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
    | ResetCharacterToken
    | ConfirmResetCharacterToken
    | CancelResetCharacterToken
    | ResetCharacterTokenResult (Result Http.Error CharacterTokenResponse)
    | UnclaimCharacter
    | ConfirmUnclaimCharacter
    | CancelUnclaimCharacter
    | UnclaimCharacterResult (Result Http.Error ())
    | ToggleUnclaimInfoBox
    | ToggleTokenInfoBox
    | ToggleNovelTokenInfoBox
    | SaveCharacter
    | SaveCharacterResult (Result Http.Error ())
    | RemoveCharacter
    | ConfirmRemoveCharacter
    | CancelRemoveCharacter
    | RemoveCharacterResult (Result Http.Error ())
