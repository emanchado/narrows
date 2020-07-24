module ProfileApp.Views exposing (..)

import Html exposing (Html, main_, aside, h1, h2, div, form, input, label, button, a, strong, text)
import Html.Attributes exposing (id, class, href, type_, placeholder, value, checked, for, readonly)
import Html.Events exposing (onInput, onClick, onCheck, onSubmit)
import Common.Models exposing (UserInfo)
import Common.Views exposing (bannerView)
import ProfileApp.Messages exposing (..)
import ProfileApp.Models exposing (..)


userView : UserInfo -> String -> Html Msg
userView user password =
  div [ class "user" ]
    [ form [ class "narrow-form vertical-form"
           , onSubmit SaveUser
           ]
        [ div [ class "form-line" ]
            [ label [ for "email" ] [ text "Email" ]
            , input [ id "email"
                    , type_ "text"
                    , readonly True
                    , value user.email
                    ]
                []
            ]
        , div [ class "form-line" ]
            [ label [ for "role" ] [ text "Admin?" ]
            , input [ id "role"
                    , type_ "text"
                    , readonly True
                    , value <| if user.role == "admin" then "Yes" else "No"
                    ]
                []
            ]
        , div [ class "form-line" ]
            [ label [ for "display-name" ] [ text "New display name" ]
            , input [ id "display-name"
                    , type_ "text"
                    , onInput UpdateDisplayName
                    , value user.displayName
                    ]
                []
            ]
        , div [ class "form-line" ]
            [ label [ for "password" ] [ text "New password" ]
            , input [ id "password"
                    , type_ "password"
                    , onInput UpdatePassword
                    , value password
                    ]
                []
            ]
        , div [ class "btn-bar" ]
            [ button [ type_ "submit"
                     , class "btn btn-default"
                     ]
                [ text "Save" ]
            ]
        ]
    ]


mainView : Model -> Html Msg
mainView model =
  main_ [ class "app-container app-container-simple" ]
    [ h1 [] [ text "Profile" ]
    , bannerView model.banner
    , case model.user of
        Just user -> userView user model.newPassword
        Nothing -> text "Loading…"
    ]
