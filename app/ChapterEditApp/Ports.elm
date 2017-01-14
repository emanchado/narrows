port module ChapterEditApp.Ports exposing (..)

import Json.Encode
import Json.Decode

import Common.Models exposing (FullCharacter)

type alias InitEditorInfo =
  { elemId : String
  , narrationId : Int
  , narrationImages : List String
  , chapterParticipants : List FullCharacter
  , text : Json.Decode.Value
  }

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
  , type' : String
  }

port initEditor : InitEditorInfo -> Cmd msg
port addImage : AddImageInfo -> Cmd msg
port updateParticipants : UpdateParticipantsInfo -> Cmd msg
port addMention : AddMentionInfo -> Cmd msg
port playPauseAudioPreview : String -> Cmd msg
port openFileInput : String -> Cmd msg
port uploadFile : FileUploadInfo -> Cmd msg
port editorContentChanged : (Json.Encode.Value -> msg) -> Sub msg
port uploadFileError : (FileUploadError -> msg) -> Sub msg
port uploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
