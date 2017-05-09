port module ChapterEditApp.Ports exposing (..)

import Json.Encode
import Common.Models exposing (FullCharacter)


type alias AddImageInfo =
    { editor : String
    , imageUrl : String
    }


type alias UpdateParticipantsInfo =
    { editor : String
    , participantList : List FullCharacter
    }


type alias AddMentionInfo =
    { editor : String
    , targets : List FullCharacter
    }


type alias FileUploadInfo =
    { fileInputId : String
    , narrationId : Int
    }


type alias FileUploadError =
    { status : Int
    , message : String
    }


type alias FileUploadSuccess =
    { name : String
    , type_ : String
    }


port updateParticipants : UpdateParticipantsInfo -> Cmd msg


port playPauseAudioPreview : String -> Cmd msg


port openFileInput : String -> Cmd msg


port uploadFile : FileUploadInfo -> Cmd msg


port editorContentChanged : (Json.Encode.Value -> msg) -> Sub msg


port uploadFileError : (FileUploadError -> msg) -> Sub msg


port uploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
