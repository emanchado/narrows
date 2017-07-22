module ChapterEditApp.Models exposing (..)

import Json.Encode
import Json.Decode
import Common.Models exposing (FullCharacter, Character, Narration, Chapter, Banner)


newEmptyChapter : Narration -> Chapter
newEmptyChapter narration =
    { id = 0
    , narrationId = narration.id
    , title = ""
    , audio = narration.defaultAudio
    , backgroundImage = narration.defaultBackgroundImage
    , text = Json.Encode.object [ ("type", Json.Encode.string "doc")
                                , ("content", Json.Encode.list [])
                                ]
    , participants = narration.characters
    , published = Nothing
    }


type alias LastReactionChapter =
    { id : Int
    , title : String
    }


type alias LastChapter =
    { id : Int
    , title : String
    , text : Json.Decode.Value
    }


type alias LastReaction =
    { chapterInfo : LastReactionChapter
    , character : Character
    , text : Maybe String
    }


type alias LastReactions =
    { chapterId : Int
    , reactions : List LastReaction
    , chapters : List LastChapter
    }


type alias Model =
    { chapter : Maybe Chapter
    , narration : Maybe Narration
    , lastReactions : Maybe LastReactions
    , banner : Maybe Banner
    , flash : Maybe Banner
    , showPublishChapterDialog : Bool
    , uploadingAudio : Bool
    , uploadingBackgroundImage : Bool
    }
