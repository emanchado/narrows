module ChapterEditApp.Models exposing (..)

import Json.Encode
import Json.Decode
import Browser.Navigation as Nav

import Common.Models exposing (FullCharacter, Character, Narration, Chapter, Banner, MessageThread)


newEmptyChapter : Narration -> Chapter
newEmptyChapter narration =
    { id = 0
    , narrationId = narration.id
    , title = ""
    , audio = narration.defaultAudio
    , backgroundImage = narration.defaultBackgroundImage
    , text = Json.Encode.object [ ("type", Json.Encode.string "doc")
                                , ("content", Json.Encode.list Json.Encode.string [])
                                ]
    , participants = narration.characters
    , published = Nothing
    }


type alias LastChapter =
    { id : Int
    , title : String
    , text : Json.Decode.Value
    , participants : List Character
    , messageThreads : List MessageThread
    }


type alias LastReactionsResponse =
    { lastChapters : List LastChapter
    }


type alias NarrationChapterSearchResult =
    { id : Int
    , title : String
    }

type alias NarrationChapterSearchResponse =
    { results : List (NarrationChapterSearchResult) }

type alias Model =
    { key : Nav.Key
    , chapter : Maybe Chapter
    , narration : Maybe Narration
    , lastChapters : Maybe (List LastChapter)
    , banner : Maybe Banner
    , chapterModified : Bool
    , flash : Maybe Banner
    , showPublishChapterDialog : Bool
    , savingChapter : Bool
    , uploadingAudio : Bool
    , uploadingBackgroundImage : Bool
    , uploadingFont : Bool
    , narrationChapterSearchTerm : String
    , narrationChapterSearchLoading : Bool
    , narrationChapterSearchResults : Maybe (List NarrationChapterSearchResult)
    , notesModified : Bool
    , notesFlash : Maybe Banner
    }
