port module ChapterEditApp.Ports exposing (..)

import Json.Encode
import Common.Models exposing (FullCharacter, FileUploadError, FileUploadSuccess)


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


port updateParticipants : UpdateParticipantsInfo -> Cmd msg
port playPauseAudioPreview : String -> Cmd msg
port editorContentChanged : (Json.Encode.Value -> msg) -> Sub msg

port chapterEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port chapterEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
