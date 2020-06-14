module Common.Models exposing (..)

import Http
import Json.Decode
import Json.Encode
import ISO8601 exposing (Time)
import Time exposing (utc, toYear, toMonth, toDay, toHour, toMinute, toSecond)


loadingPlaceholderChapter : Chapter
loadingPlaceholderChapter =
    { id = 0
    , narrationId = 0
    , title = "…"
    , audio = Nothing
    , backgroundImage = Nothing
    , text = Json.Encode.null
    , participants = []
    , published = Nothing
    }


loadingPlaceholderNarration : Narration
loadingPlaceholderNarration =
    { id = 0
    , title = "…"
    , status = Active
    , intro = Json.Encode.null
    , introUrl = ""
    , introAudio = Nothing
    , introBackgroundImage = Nothing
    , characters = []
    , defaultAudio = Nothing
    , defaultBackgroundImage = Nothing
    , notes = ""
    , files = { audio = []
              , backgroundImages = []
              , images = []
              , fonts = []
              }
    , styles = { titleFont = Nothing
               , titleFontSize = Nothing
               , titleColor = Nothing
               , titleShadowColor = Nothing
               , bodyTextFont = Nothing
               , bodyTextFontSize = Nothing
               , bodyTextColor = Nothing
               , bodyTextBackgroundColor = Nothing
               , separatorImage = Nothing
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


bannerForHttpError : Http.Error -> Maybe Banner
bannerForHttpError error =
  let
    errorMessage = case error of
                     Http.BadBody parserError ->
                       "Bad payload: " ++ parserError

                     Http.BadStatus status ->
                       "Got status " ++ (String.fromInt status)

                     _ ->
                       "Cannot connect to server"
  in
    errorBanner errorMessage


narrationStatusString : NarrationStatus -> String
narrationStatusString status =
  case status of
    Active -> "active"
    Finished -> "finished"
    Abandoned -> "abandoned"


toMonthNumber : Time.Month -> Int
toMonthNumber month =
  case month of
    Time.Jan -> 1
    Time.Feb -> 2
    Time.Mar -> 3
    Time.Apr -> 4
    Time.May -> 5
    Time.Jun -> 6
    Time.Jul -> 7
    Time.Aug -> 8
    Time.Sep -> 9
    Time.Oct -> 10
    Time.Nov -> 11
    Time.Dec -> 12


toUtcString : Time.Posix -> String
toUtcString time =
  String.fromInt (toYear utc time)
  ++ "-" ++
  String.padLeft 2 '0' (String.fromInt (toMonthNumber <| toMonth utc time))
  ++ "-" ++
  String.padLeft 2 '0' (String.fromInt (toDay utc time))
  ++ " " ++
  String.padLeft 2 '0' (String.fromInt (toHour utc time))
  ++ ":" ++
  String.padLeft 2 '0' (String.fromInt (toMinute utc time))
  ++ ":" ++
  String.padLeft 2 '0' (String.fromInt (toSecond utc time))


type alias Banner =
    { type_ : String
    , text : String
    }


type alias Character =
    { id : Int
    , name : String
    , avatar : Maybe String
    }


type alias FullCharacter =
    { id : Int
    , name : String
    , displayName : Maybe String
    , token : String
    , novelToken : String
    , avatar : Maybe String
    }


type alias FileSet =
    { audio : List String
    , backgroundImages : List String
    , images : List String
    , fonts : List String
    }


type NarrationStatus
  = Active
  | Finished
  | Abandoned


type alias StyleSet =
    { titleFont : Maybe String
    , titleFontSize : Maybe String
    , titleColor : Maybe String
    , titleShadowColor : Maybe String
    , bodyTextFont : Maybe String
    , bodyTextFontSize : Maybe String
    , bodyTextColor : Maybe String
    , bodyTextBackgroundColor : Maybe String
    , separatorImage : Maybe String
    }


type alias Narration =
    { id : Int
    , title : String
    , status : NarrationStatus
    , intro : Json.Decode.Value
    , introUrl : String
    , introAudio : Maybe String
    , introBackgroundImage : Maybe String
    , notes : String
    , characters : List FullCharacter
    , defaultAudio : Maybe String
    , defaultBackgroundImage : Maybe String
    , files : FileSet
    , styles : StyleSet
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
    , displayName : String
    , role : String
    , verified : Bool
    , created : ISO8601.Time
    }


type UserSession
  = AnonymousSession
  | LoggedInSession UserInfo


type alias Breadcrumb =
    { title : String
    , url : String
    }


type MediaType
  = Audio
  | Image
  | BackgroundImage
  | Font


mediaTypeString : MediaType -> String
mediaTypeString mediaType =
  case mediaType of
    Audio -> "audio"
    Image -> "images"
    BackgroundImage -> "background-images"
    Font -> "fonts"


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

    "images" ->
      { fileSet | images = uploadResponse.name :: fileSet.images }

    "backgroundImages" ->
      { fileSet | backgroundImages = uploadResponse.name :: fileSet.backgroundImages }

    "fonts" ->
      { fileSet | fonts = uploadResponse.name :: fileSet.fonts }

    _ ->
      fileSet


type alias ParticipantCharacter =
    { id : Int
    , name : String
    , claimed : Bool
    , avatar : Maybe String
    , description : Json.Decode.Value
    }


type alias ChapterSummary =
    { id : Int
    , title : String
    }


type alias NarrationSummary =
    { id : Int
    , title : String
    , status : NarrationStatus
    , chapters : List ChapterSummary
    , characters : List ParticipantCharacter
    }


type alias CharacterInfo =
    { id : Int
    , name : String
    , avatar : Maybe String
    , token : String
    , novelToken : String
    , description : Json.Decode.Value
    , backstory : Json.Decode.Value
    , narration : NarrationSummary
    }


type alias DeviceSettings =
    { backgroundMusic : Bool
    }
