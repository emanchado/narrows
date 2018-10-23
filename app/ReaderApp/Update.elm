module ReaderApp.Update exposing (..)

import String
import Http
import Navigation
import Json.Decode exposing (decodeString)

import Core.Routes exposing (Route(..))
import Common.Ports exposing (readDeviceSettings, setDeviceSetting, renderText, startNarration, playPauseNarrationMusic, flashElement)
import Common.Models exposing (Character, ParticipantCharacter, errorBanner, successBanner)
import Common.Models.Reading exposing (PageState(Loader, StartingNarration, Narrating))
import ReaderApp.Api
import ReaderApp.Messages exposing (..)
import ReaderApp.Models exposing (..)


messageRecipients : List Character -> Int -> List Int
messageRecipients recipients senderId =
  List.filter
    (\r -> r /= senderId)
    (List.map (\r -> r.id) recipients)


maxBlurriness : Int
maxBlurriness =
  10


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    ChapterReaderPage chapterId characterToken ->
      ( { model | state = Loader }
      , Cmd.batch
          [ ReaderApp.Api.fetchChapterInfo chapterId characterToken
          , readDeviceSettings "receiveDeviceSettingsReader"
          ]
      )

    _ ->
      ( model, Cmd.none )


descriptionRenderCommand : ParticipantCharacter -> Cmd Msg
descriptionRenderCommand character =
    renderText
        { elemId = "description-character-" ++ (toString character.id)
        , text = character.description
        , proseMirrorType = "description"
        }


formatError : Http.Error -> String
formatError httpError =
  case httpError of
    Http.BadStatus response ->
      case decodeString ReaderApp.Api.parseApiError response.body of
        Ok value -> value.errorMessage
        Err error -> "Cannot parse server error: " ++ error
    _ ->
      "Unknown network error"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NavigateTo url ->
      ( model, Navigation.newUrl url )


    ReceiveDeviceSettings newSettings ->
      ( { model | backgroundMusic = newSettings.backgroundMusic
                , musicPlaying = newSettings.backgroundMusic
        }
      , Cmd.none
      )

    ChapterFetchResult (Err error) ->
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
        ( { model | banner = errorBanner errorString }
        , Cmd.none
        )

    ChapterFetchResult (Ok chapterData) ->
      ( { model | chapter = Just chapterData }
      , ReaderApp.Api.fetchChapterMessages chapterData.id chapterData.character.token
      )

    ChapterMessagesFetchResult (Err error) ->
      ( { model | banner = Just { text = "Error fetching chapter messages"
                                , type_ = "error"
                                }
        }
      , Cmd.none
      )

    ChapterMessagesFetchResult (Ok chapterMessageData) ->
      let
        allRecipients =
          case model.chapter of
            Just chapter ->
              let
                allParticipantIds = List.map (\p -> p.id) chapter.participants
              in
                List.filter (\p -> p /= chapter.character.id) allParticipantIds
            Nothing ->
              []
      in
        ( { model | messageThreads = Just chapterMessageData.messages
                  , newMessageRecipients = allRecipients
          }
        , Cmd.none
        )

    StartNarration ->
      let
        audioElemId = if model.backgroundMusic then
                        "background-music"
                      else
                        ""
        command =
          case model.chapter of
            Just chapterData ->
              Cmd.batch <|
                List.append
                  [ renderText { elemId = "chapter-text"
                               , text = chapterData.text
                               , proseMirrorType = "chapter"
                               }
                  , startNarration { audioElemId = audioElemId }
                  , setDeviceSetting { name = "backgroundMusic"
                                     , value = if model.backgroundMusic then
                                                 "1"
                                               else
                                                 ""
                                     }
                  ]
                  (List.map descriptionRenderCommand chapterData.participants)

            Nothing ->
              Cmd.none
      in
        ( { model | state = StartingNarration }, command )

    NarrationStarted _ ->
      ( { model | state = Narrating }, Cmd.none )

    ToggleBackgroundMusic ->
      let
        musicOn = not model.backgroundMusic
      in
        ( { model | backgroundMusic = musicOn, musicPlaying = musicOn }
        , Cmd.none
        )

    PlayPauseMusic ->
      ( { model | musicPlaying = not model.musicPlaying }
      , playPauseNarrationMusic { audioElemId = "background-music" }
      )

    PageScroll scrollAmount ->
      let
        blurriness = min maxBlurriness (round ((toFloat scrollAmount) / 40))
      in
        ( { model | backgroundBlurriness = blurriness }, Cmd.none )

    UpdateNotesText newText ->
      case model.chapter of
        Just chapter ->
          let
            ownCharacter = chapter.character
            updatedOwnCharacter = { ownCharacter | notes = Just newText }
            updatedChapter = { chapter | character = updatedOwnCharacter }
          in
            ( { model | chapter = Just updatedChapter }, Cmd.none )

        Nothing ->
          ( model, Cmd.none )

    SendNotes ->
      case model.chapter of
        Just chapter ->
          case chapter.character.notes of
            Just notes ->
              ( model
              , ReaderApp.Api.sendNotes chapter.character.token notes
              )
            Nothing ->
              ( model, Cmd.none )
        Nothing ->
          ( model, Cmd.none )

    SendNotesResult (Err error) ->
      ( { model | banner = errorBanner <| formatError error }
      , Cmd.none
      )

    SendNotesResult (Ok _) ->
      ( { model | banner = Nothing }, flashElement "save-notes-message" )

    ShowReply participants ->
      let
        newReply = case model.reply of
                     Just reply -> { reply | recipients = participants }
                     Nothing -> { recipients = participants
                                , body = ""
                                }
      in
        ( { model | reply = Just newReply }, Cmd.none )

    UpdateReplyText newText ->
      let
        newReply = case model.reply of
                     Just reply -> { reply | body = newText }
                     Nothing -> { recipients = []
                                , body = newText
                                }
      in
        ( { model | reply = Just newReply }, Cmd.none )

    SendReply ->
      case model.reply of
        Just reply ->
          if String.isEmpty <| String.trim reply.body then
            ( model, Cmd.none )
          else
            case model.chapter of
              Just chapter ->
                ( { model | replySending = True }
                , ReaderApp.Api.sendReply
                    chapter.id
                    chapter.character.token
                    reply.body
                    (messageRecipients reply.recipients chapter.character.id)
                )
              Nothing ->
                ( model, Cmd.none )

        Nothing ->
          ( model, Cmd.none )

    SendReplyResult (Err error) ->
      ( { model | banner = errorBanner "Error sending reply"
                , replySending = False
        }
      , Cmd.none
      )

    SendReplyResult (Ok result) ->
      ( { model | messageThreads = Just result.messages
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
          List.filter (\r -> r /= characterId) model.newMessageRecipients
        newRecipients = if on then
                          characterId :: newRecipientsWithoutCharacter
                        else
                          newRecipientsWithoutCharacter
      in
        ( { model | newMessageRecipients = newRecipients }, Cmd.none )

    SendMessage ->
      case model.chapter of
        Just chapter ->
          if String.isEmpty <| String.trim model.newMessageText then
            ( model, Cmd.none )
          else
            ( model
            , ReaderApp.Api.sendMessage chapter.id chapter.character.token model.newMessageText model.newMessageRecipients
            )
        Nothing ->
          ( model, Cmd.none )

    SendMessageResult (Err error) ->
      ( { model | banner = errorBanner "Error sending message" }
      , Cmd.none
      )

    SendMessageResult (Ok result) ->
        ( { model | messageThreads = Just result.messages
                  , newMessageText = ""
                  , banner = Nothing
          }
        , Cmd.none
        )

    ToggleReactionTip ->
      ( { model | showReactionTip = not model.showReactionTip }
      , Cmd.none
      )

    ShowReferenceInformation ->
      ( { model | referenceInformationVisible = True }, Cmd.none )

    HideReferenceInformation ->
      ( { model | referenceInformationVisible = False }, Cmd.none )
