port module ReaderApp.Ports exposing (..)

type alias NarrationMediaInfo =
  { audioElemId : String
  }

port startNarration : NarrationMediaInfo -> Cmd msg
port playPauseNarrationMusic : NarrationMediaInfo -> Cmd msg
port flashElement : String -> Cmd msg
port pageScrollListener : (Int -> msg) -> Sub msg
port markNarrationAsStarted : (Int -> msg) -> Sub msg
