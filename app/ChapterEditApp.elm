module ChapterEditApp exposing (..)

import Html exposing (Html)
import Core.Routes exposing (Route(..))
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Models exposing (..)
import ChapterEditApp.Update
import ChapterEditApp.Views
import ChapterEditApp.Ports


type alias Model =
    ChapterEditApp.Models.Model


type alias Msg =
    ChapterEditApp.Messages.Msg


initialState : Model
initialState =
    { chapter = Nothing
    , narration = Nothing
    , lastReactions = Nothing
    , banner = Nothing
    , flash = Nothing
    , showPublishChapterDialog = False
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    ChapterEditApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    ChapterEditApp.Update.urlUpdate


view : Model -> Html Msg
view =
    ChapterEditApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ ChapterEditApp.Ports.editorContentChanged UpdateEditorContent
        , ChapterEditApp.Ports.uploadFileError AddMediaFileError
        , ChapterEditApp.Ports.uploadFileSuccess AddMediaFileSuccess
        ]
