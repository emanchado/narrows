module CharacterApp exposing (..)

import Html exposing (Html)
import Core.Routes exposing (Route(..))
import CharacterApp.Messages exposing (..)
import CharacterApp.Models exposing (..)
import CharacterApp.Update
import CharacterApp.Views
import CharacterApp.Ports


type alias Model =
    CharacterApp.Models.Model


type alias Msg =
    CharacterApp.Messages.Msg


initialState : Model
initialState =
    { characterToken = ""
    , characterInfo = Nothing
    , newAvatarUrl = Nothing
    , banner = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    CharacterApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    CharacterApp.Update.urlUpdate


view : Model -> Html Msg
view =
    CharacterApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ CharacterApp.Ports.descriptionContentChanged UpdateDescriptionText
        , CharacterApp.Ports.backstoryContentChanged UpdateBackstoryText
        , CharacterApp.Ports.receiveAvatarAsUrl ReceiveAvatarAsUrl
        , CharacterApp.Ports.uploadAvatarError UploadAvatarError
        , CharacterApp.Ports.uploadAvatarSuccess UploadAvatarSuccess
        ]
