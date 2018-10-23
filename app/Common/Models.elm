module Common.Models exposing (..)

import Json.Decode
import Json.Encode
import ISO8601


loadingPlaceholderChapter : Chapter
loadingPlaceholderChapter =
    { id = 0
    , narrationId = 0
    , title = "…"
    , audio = Nothing
    , backgroundImage = Nothing
    , text = Json.Encode.list []
    , participants = []
    , published = Nothing
    }


loadingPlaceholderNarration : Narration
loadingPlaceholderNarration =
    { id = 0
    , title = "…"
    , status = Active
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
    Just
        { text = errorMessage
        , type_ = "error"
        }


successBanner : String -> Maybe Banner
successBanner errorMessage =
    Just
        { text = errorMessage
        , type_ = "success"
        }


narrationStatusString : NarrationStatus -> String
narrationStatusString status =
  case status of
    Active -> "active"
    Finished -> "finished"
    Abandoned -> "abandoned"


type alias Banner =
    { type_ : String
    , text : String
    }


type alias Character =
    { id : Int
    , name : String
    }


type alias FullCharacter =
    { id : Int
    , name : String
    , email : String
    , token : String
    , novelToken : String
    , avatar : Maybe String
    , introSent : Maybe ISO8601.Time
    }


type alias FileSet =
    { audio : List String
    , backgroundImages : List String
    , images : List String
    }


type NarrationStatus
  = Active
  | Finished
  | Abandoned


type alias Narration =
    { id : Int
    , title : String
    , status : NarrationStatus
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


type alias ReplyInformation =
    { recipients : List Character
    , body : String
    }


type alias ChapterOverview =
    { id : Int
    , title : String
    , published : Maybe String
    , participants : List Character
    , activeUsers : List Character
    , numberMessages : Int
    }


type alias NarrationOverview =
    { narration : Narration
    , chapters : List ChapterOverview
    }


type alias UserInfo =
    { id : Int
    , email : String
    , role : String
    }


type alias Breadcrumb =
    { title : String
    , url : String
    }


type MediaType
  = Audio
  | BackgroundImage


mediaTypeString : MediaType -> String
mediaTypeString mediaType =
  case mediaType of
    Audio -> "audio"
    BackgroundImage -> "background-images"


type alias FileUploadError =
    { status : Int
    , message : String
    }


type alias FileUploadSuccess =
    { name : String
    , type_ : String
    }


updateNarrationFiles : FileSet -> FileUploadSuccess -> FileSet
updateNarrationFiles fileSet uploadResponse =
  case uploadResponse.type_ of
    "audio" ->
      { fileSet | audio = uploadResponse.name :: fileSet.audio }

    "backgroundImages" ->
      { fileSet | backgroundImages = uploadResponse.name :: fileSet.backgroundImages }

    _ ->
      fileSet


type alias ParticipantCharacter =
    { id : Int
    , name : String
    , avatar : Maybe String
    , description : Json.Decode.Value
    }


type alias DeviceSettings =
    { backgroundMusic : Bool
    }
