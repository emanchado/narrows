module NarrationIntroApp.Update exposing (..)

import Http
import Core.Routes exposing (Route(..))
import Common.Ports exposing (renderText, startNarration, playPauseNarrationMusic)
import Common.Models exposing (UserSession(..), ParticipantCharacter, successBanner, errorBanner, bannerForHttpError)
import Common.Models.Reading exposing (PageState(..))
import NarrationIntroApp.Api
import NarrationIntroApp.Messages exposing (..)
import NarrationIntroApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        NarrationIntroPage narrationToken ->
            ( { model | narrationToken = narrationToken
                      , narrationIntro = Nothing
                      , session = Nothing
                      , banner = Nothing
              }
            , Cmd.batch <|
                [ NarrationIntroApp.Api.fetchNarrationIntro narrationToken
                , NarrationIntroApp.Api.fetchCurrentSession
                ]
            )

        _ ->
            ( model, Cmd.none )


descriptionRenderCommand : ParticipantCharacter -> Cmd Msg
descriptionRenderCommand character =
  renderText { elemId = "description-character-" ++ (String.fromInt character.id)
             , text = character.description
             , proseMirrorType = "description"
             }


maxBlurriness : Int
maxBlurriness = 10


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SessionFetchResult (Err err) ->
            ( { model | session = Just AnonymousSession }
            , Cmd.none
            )

        SessionFetchResult (Ok session) ->
            ( { model | session = Just <| LoggedInSession session }
            , Cmd.none
            )

        NarrationIntroFetchResult (Err error) ->
            ( { model | banner = bannerForHttpError error }
            , Cmd.none
            )

        NarrationIntroFetchResult (Ok resp) ->
            ( { model | narrationIntro = Just resp }
            , Cmd.batch <|
                List.append
                  [ renderText { elemId = "chapter-text"
                               , text = resp.intro
                               , proseMirrorType = "chapter"
                               }
                  ]
                  (List.map descriptionRenderCommand resp.characters)
            )

        ToggleBackgroundMusic ->
            let
                musicOn = not model.backgroundMusic
            in
                ( { model | backgroundMusic = musicOn, musicPlaying = musicOn }
                , Cmd.none
                )

        StartNarration ->
          let
            audioElemId = if model.backgroundMusic then
                            "background-music"
                          else
                            ""
            command =
              case model.narrationIntro of
                Just narrationIntro ->
                  Cmd.batch <|
                    List.append
                      [ renderText { elemId = "chapter-text"
                                   , text = narrationIntro.intro
                                   , proseMirrorType = "chapter"
                                   }
                      , startNarration { audioElemId = audioElemId
                                       , narrationId = narrationIntro.id
                                       }
                      ]
                      (List.map descriptionRenderCommand narrationIntro.characters)
    
                Nothing ->
                  Cmd.none
          in
            ( { model | state = StartingNarration }, command )

        NarrationStarted _ ->
            ( { model | state = Narrating }
            , Cmd.none
            )

        PlayPauseMusic ->
            ( { model | musicPlaying = not model.musicPlaying }
            , playPauseNarrationMusic { audioElemId = "background-music" }
            )

        PageScroll scrollAmount ->
            let
                blurriness =
                  min maxBlurriness (round ((toFloat scrollAmount) / 40))
            in
                ( { model | backgroundBlurriness = blurriness }, Cmd.none )

        UpdateEmail newEmail ->
            ( { model | email = newEmail
                      , banner = Nothing
              }
            , Cmd.none
            )

        ClaimCharacter characterId email ->
            if String.isEmpty email then
              ( { model | banner = errorBanner "Email cannot be empty!" }
              , Cmd.none
              )
            else
              ( { model | banner = Nothing }
              , NarrationIntroApp.Api.claimCharacter characterId email
              )

        ClaimCharacterFetchResult (Err err) ->
            ( { model | banner = errorBanner "Could not claim character. Remember you can only claim one character per story." }
            , NarrationIntroApp.Api.fetchNarrationIntro model.narrationToken
            )

        ClaimCharacterFetchResult (Ok ()) ->
            ( { model | banner = successBanner "Character claimed. See your email for more details (please check your spam folder, too)." }
            , NarrationIntroApp.Api.fetchNarrationIntro model.narrationToken
            )
