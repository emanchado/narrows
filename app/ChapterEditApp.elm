module ChapterEditApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

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


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , nowMilliseconds = -1
    , chapter = Nothing
    , narration = Nothing
    , lastChapters = Nothing
    , showLastReactions = True
    , banner = Nothing
    , chapterModified = False
    , flash = Nothing
    , showPublishChapterDialog = False
    , savingChapter = False
    , uploadingAudio = False
    , uploadingBackgroundImage = False
    , uploadingFont = False
    , narrationChapterSearchTerm = ""
    , narrationChapterSearchLoading = False
    , narrationChapterSearchResults = Nothing
    , notesModified = False
    , notesFlash = Nothing
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
        , ChapterEditApp.Ports.chapterEditUploadFileError AddMediaFileError
        , ChapterEditApp.Ports.chapterEditUploadFileSuccess AddMediaFileSuccess
        ]
