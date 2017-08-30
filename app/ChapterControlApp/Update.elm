module ChapterControlApp.Update exposing (..)

import Http
import Navigation
import Core.Routes exposing (Route(..))
import Common.Models exposing (Banner, Character, errorBanner)
import Common.Ports exposing (renderText)
import ChapterControlApp.Api
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    ChapterControlPage chapterId ->
      ( model
      , Cmd.batch
        [ ChapterControlApp.Api.fetchChapterInteractions chapterId
        ]
      )
    _ ->
      ( model, Cmd.none )


messageRecipients : List Character -> List Int
messageRecipients recipients =
  List.map (\r -> r.id) recipients


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    NavigateTo url ->
      ( model, Navigation.newUrl url )

    ChapterInteractionsFetchResult (Err error) ->
      let
        errorString =
          case error of
            Http.BadPayload parserError _ ->
              "Bad payload: " ++ parserError
            Http.BadStatus resp ->
              "Got status " ++ (toString resp.status) ++ " with body " ++ resp.body
            _ ->
              "Cannot connect to server"
      in
        ( { model | banner = errorBanner errorString }, Cmd.none )

    ChapterInteractionsFetchResult (Ok interactions) ->
      let
        participantIds =
          List.map (\c -> c.id) interactions.chapter.participants
      in
        ( { model | interactions = Just interactions
                  , newMessageRecipients = participantIds
          }
        , Cmd.batch
            [ renderText
                { elemId = "chapter-text"
                , text = interactions.chapter.text
                , proseMirrorType = "chapter"
                }
            , ChapterControlApp.Api.fetchNarrationInfo interactions.chapter.narrationId
            ]
        )

    NarrationFetchResult (Err error) ->
      let
        errorString =
          case error of
            Http.BadPayload parserError _ ->
              "Bad payload: " ++ parserError
            Http.BadStatus resp ->
              "Got status " ++ (toString resp.status) ++ " with body " ++ resp.body
            _ ->
              "Cannot connect to server"
      in
        ( { model | banner = Just { type_ = "error", text = errorString } }
        , Cmd.none
        )

    NarrationFetchResult (Ok narration) ->
      ( { model | narration = Just narration }, Cmd.none )

    ShowReply participants ->
      let
        newReply =
          case model.reply of
            Just reply -> { reply | recipients = participants }
            Nothing -> { recipients = participants
                       , body = ""
                       }
      in
        ( { model | reply = Just newReply }, Cmd.none )

    UpdateReplyText newText ->
      let
        newReply =
          case model.reply of
            Just reply -> { reply | body = newText }
            Nothing -> { recipients = []
                       , body = newText
                       }
      in
        ( { model | reply = Just newReply }, Cmd.none )

    SendReply ->
      case model.interactions of
        Just interactions ->
          case model.reply of
            Just reply -> ( { model | replySending = True }
                          , ChapterControlApp.Api.sendReply
                              interactions.chapter.id
                              reply.body
                              (messageRecipients reply.recipients)
                          )
            Nothing -> ( model, Cmd.none )
        Nothing ->
          ( model, Cmd.none )

    SendReplyResult (Err error) ->
      ( { model | banner = Just { text = "Error sending reply"
                                , type_ = "error"
                                }
                , replySending = False
        }
      , Cmd.none
      )

    SendReplyResult (Ok resp) ->
      let
        updatedInteractions =
          case model.interactions of
            Just interactions ->
              Just { interactions | messageThreads = resp.messages }
            Nothing ->
              Nothing
      in
        ( { model | interactions = updatedInteractions
                  , reply = Nothing
                  , replySending = False
          }
        , Cmd.none
        )

    CloseReply ->
      ( { model | reply = Nothing }, Cmd.none )

    UpdateNewMessageText newText ->
      ( { model | newMessageText = newText }, Cmd.none )

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
        ( { model | newMessageRecipients = newRecipients }, Cmd.none )

    SendMessage ->
      case model.interactions of
        Just interactions ->
          ( { model | newMessageSending = True }
          , ChapterControlApp.Api.sendMessage interactions.chapter.id model.newMessageText model.newMessageRecipients
          )
        Nothing ->
          ( model, Cmd.none )

    SendMessageResult (Err error) ->
      ( { model | banner = errorBanner "Error sending message"
                , newMessageSending = False
        }
      , Cmd.none
      )

    SendMessageResult (Ok resp) ->
      let
        updatedInteractions =
          case model.interactions of
            Just interactions ->
              Just { interactions | messageThreads = resp.messages }
            Nothing ->
              Nothing
      in
        ( { model | interactions = updatedInteractions
                  , newMessageText = ""
                  , newMessageSending = False
          }
        , Cmd.none
        )
