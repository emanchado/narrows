module Common.Models exposing (..)

import Json.Decode
import Json.Encode

loadingPlaceholderChapter : Chapter
loadingPlaceholderChapter =
  { id = 0
  , narrationId = 0
  , title = ""
  , audio = Nothing
  , backgroundImage = Nothing
  , text = Json.Encode.list []
  , participants = []
  , published = Nothing
  }

loadingPlaceholderNarration : Narration
loadingPlaceholderNarration =
  { id = 0
  , title = ""
  , characters = []
  , defaultAudio = Nothing
  , defaultBackgroundImage = Nothing
  , files = { audio = []
            , backgroundImages = []
            , images = []
            }
  }

errorBanner : String -> Maybe Banner
errorBanner errorMessage =
  Just { text = errorMessage
       , type' = "error"
       }

type alias Banner =
  { type' : String
  , text : String
  }

type alias Character =
  { id : Int
  , name : String
  }

type alias FullCharacter =
  { id : Int
  , name : String
  , token : String
  }

type alias FileSet =
  { audio : List String
  , backgroundImages : List String
  , images : List String
  }

type alias Narration =
  { id : Int
  , title : String
  , characters : List FullCharacter
  , defaultAudio : Maybe String
  , defaultBackgroundImage : Maybe String
  , files : FileSet
  }

type alias Chapter =
  { id : Int
  , narrationId : Int
  , title : String
  , audio : Maybe String
  , backgroundImage : Maybe String
  , text : Json.Decode.Value
  , participants : List FullCharacter
  , published : Maybe String
  }

type alias Message =
  { id : Int
  , body : String
  , sentAt : String
  , sender : Maybe Character
  , recipients : Maybe (List Character)
  }

type alias MessageThread =
  { participants : List Character
  , messages : List Message
  }

-- Only used for JSON response decoding
type alias ChapterMessages =
  { messages : List MessageThread
  , characterId : Maybe Int
  }

type alias Reaction =
  { character : Character
  , text : Maybe String
  }

type alias ReplyInformation =
  { recipients : List Character
  , body : String
  }
