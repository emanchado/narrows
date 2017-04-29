module ChapterControlApp.Update exposing (..)

import Http
import Json.Decode

import Routing
import Common.Models exposing (Banner, Character)
import Common.Ports exposing (renderText)
import Common.Api.Json exposing (parseChapterMessages)

import ChapterControlApp.Api
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (..)


errorBanner : String -> Maybe Banner
errorBanner errorMessage =
  Just { text = errorMessage
       , type' = "error"
       }

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.ChapterControlPage chapterId ->
        ( model
        , Cmd.batch [ ChapterControlApp.Api.fetchChapterInteractions chapterId
                    ]
        )
      _ ->
        (model, Cmd.none)

messageRecipients : List Character -> List Int
messageRecipients recipients =
  List.map (\r -> r.id) recipients

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    ChapterInteractionsFetchError error ->
      let
        errorString = case error of
                        Http.UnexpectedPayload payload ->
                          "Bad payload: " ++ payload
                        Http.BadResponse status body ->
                          "Got status " ++ (toString status) ++ " with body " ++ body
                        _ ->
                          "Cannot connect to server"
      in
        ({ model | banner = errorBanner errorString }, Cmd.none)
    ChapterInteractionsFetchSuccess interactions ->
      let
        participantIds =
          List.map (\c -> c.id) interactions.chapter.participants
      in
        ( { model | interactions = Just interactions
                  , newMessageRecipients = participantIds
                  }
        , renderText { elemId = "chapter-text"
                     , text = interactions.chapter.text
                     , proseMirrorType = "chapter"
                     }
        )

    ShowReply participants ->
      let
        newReply = case model.reply of
                     Just reply ->
                       { reply | recipients = participants }
                     Nothing ->
                       { recipients = participants
                       , body = ""
                       }
      in
        ({ model | reply = Just newReply }, Cmd.none)
    UpdateReplyText newText ->
      let
        newReply = case model.reply of
                     Just reply ->
                       { reply | body = newText }
                     Nothing ->
                       { recipients = []
                       , body = newText
                       }
      in
        ({ model | reply = Just newReply }, Cmd.none)

    SendReply ->
      case model.interactions of
        Just interactions ->
          case model.reply of
            Just reply ->
              ( model
              , ChapterControlApp.Api.sendReply
                  interactions.chapter.id
                  reply.body
                  (messageRecipients reply.recipients)
              )
            Nothing ->
              (model, Cmd.none)
        Nothing ->
          (model, Cmd.none)
    SendReplyError error ->
      ({ model | banner = Just { text = "Error sending reply"
                               , type' = "error"
                               } }
      , Cmd.none)
    SendReplySuccess resp ->
      case resp.value of
        Http.Text text ->
          let
            decodedResponse =
              Json.Decode.decodeString parseChapterMessages text
          in
            case decodedResponse of
              Ok result ->
                let
                  updatedInteractions = case model.interactions of
                                          Just interactions ->
                                            Just { interactions | messageThreads = result.messages }
                                          Nothing ->
                                            Nothing
                in
                  ( { model | interactions = updatedInteractions
                            , reply = Nothing
                    }
                  , Cmd.none)
              _ ->
                ({ model | banner = Just { text = "Error parsing response while sending message"
                                   , type' = "error"
                                   } }
                , Cmd.none)
        _ ->
          ({ model | banner = Just { text = "Error sending message"
                                   , type' = "error"
                                   } }
          , Cmd.none)

    CloseReply ->
      ({ model | reply = Nothing }, Cmd.none)

    UpdateNewMessageText newText ->
      ({ model | newMessageText = newText }, Cmd.none)
    UpdateNewMessageRecipient characterId on ->
      let
        newRecipientsWithoutCharacter =
          List.filter
            (\r -> r /= characterId)
            model.newMessageRecipients
        newRecipients =
          if on then
            characterId :: newRecipientsWithoutCharacter
          else
            newRecipientsWithoutCharacter
      in
        ({ model | newMessageRecipients = newRecipients }, Cmd.none)
    SendMessage ->
      case model.interactions of
        Just interactions ->
          ( model
          , ChapterControlApp.Api.sendMessage interactions.chapter.id model.newMessageText model.newMessageRecipients
          )
        Nothing ->
          (model, Cmd.none)
    SendMessageError error ->
      ({ model | banner = Just { text = "Error sending message"
                               , type' = "error"
                               } }
      , Cmd.none)
    SendMessageSuccess resp ->
      case resp.value of
        Http.Text text ->
          let
            decodedResponse =
              Json.Decode.decodeString parseChapterMessages text
          in
            case decodedResponse of
              Ok result ->
                let
                  updatedInteractions = case model.interactions of
                                          Just interactions ->
                                            Just { interactions | messageThreads = result.messages }
                                          Nothing ->
                                            Nothing
                in
                  ( { model | interactions = updatedInteractions
                            , newMessageText = ""
                    }
                  , Cmd.none)
              _ ->
                ({ model | banner = Just { text = "Error parsing response while sending message"
                                   , type' = "error"
                                   } }
                , Cmd.none)
        _ ->
          ({ model | banner = Just { text = "Error sending message"
                                   , type' = "error"
                                   } }
          , Cmd.none)
