module CharacterEditApp exposing (..)

import Html exposing (Html)
import Core.Routes exposing (Route(..))
import CharacterEditApp.Messages exposing (..)
import CharacterEditApp.Models exposing (..)
import CharacterEditApp.Update
import CharacterEditApp.Views
import CharacterEditApp.Ports


type alias Model =
    CharacterEditApp.Models.Model


type alias Msg =
    CharacterEditApp.Messages.Msg


initialState : Model
initialState =
    { characterId = 0
    , characterInfo = Nothing
    , newAvatarUrl = Nothing
    , showResetCharacterTokenDialog = False
    , showTokenInfoBox = False
    , showNovelTokenInfoBox = False
    , banner = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    CharacterEditApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    CharacterEditApp.Update.urlUpdate


view : Model -> Html Msg
view =
    CharacterEditApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ CharacterEditApp.Ports.narratorDescriptionContentChanged UpdateDescriptionText
        , CharacterEditApp.Ports.narratorBackstoryContentChanged UpdateBackstoryText
        , CharacterEditApp.Ports.narratorReceiveAvatarAsUrl ReceiveAvatarAsUrl
        , CharacterEditApp.Ports.narratorUploadAvatarError UploadAvatarError
        , CharacterEditApp.Ports.narratorUploadAvatarSuccess UploadAvatarSuccess
        ]
