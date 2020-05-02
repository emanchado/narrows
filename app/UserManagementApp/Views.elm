module UserManagementApp.Views exposing (..)

import ISO8601

import Html exposing (Html, main_, aside, h1, h2, div, form, input, label, button, ul, li, a, strong, text)
import Html.Attributes exposing (id, class, href, type_, placeholder, value, checked, for, title)
import Html.Events exposing (onInput, onClick, onCheck, onSubmit)

import Common.Models exposing (UserInfo, toUtcString)
import Common.Views exposing (bannerView, showDialog)
import UserManagementApp.Messages exposing (..)
import UserManagementApp.Models exposing (..)


userView : Maybe UserChanges -> UserInfo -> Html Msg
userView maybeUserChanges user =
  let
    userLabel =
      label [ class <| "user" ++ (if user.verified then "" else " unverified")  ++ (if user.role == "admin" then " admin" else "")
            , for <| "default-btn-user-" ++ (String.fromInt user.id)
            , title <| if user.verified then "" else "Joined on " ++ (toUtcString <| ISO8601.toPosix user.created)
            ]
        [ text user.email ]

    userChanges = case maybeUserChanges of
                    Just changes ->
                      changes
                    Nothing ->
                      { userId = -1
                      , displayName = user.displayName
                      , password = ""
                      , isAdmin = user.role == "admin"
                      }
  in
    if userChanges.userId == user.id then
      li [ class "expanded-user" ]
        [ form [ class "vertical-form"
               , onSubmit SaveUser
               ]
            [ div [ class "form-line" ]
                [ userLabel ]
            , div [ class "form-line" ]
                [ label [ for "display-name" ] [ text "Display name: " ]
                , input
                    [ id "display-name"
                    , type_ "text"
                    , onInput UpdateDisplayName
                    , value userChanges.displayName
                    ]
                    []
                ]
            , div [ class "form-line" ]
                [ label [ for "password" ] [ text "Password: " ]
                , input
                    [ id "password"
                    , type_ "password"
                    , onInput UpdatePassword
                    , value userChanges.password
                    ]
                    []
                ]
            , div [ class "form-line" ]
                [ label [ for "is-admin" ] [ text "Admin?" ]
                , input
                    [ id "is-admin"
                    , type_ "checkbox"
                    , onCheck UpdateIsAdmin
                    , checked userChanges.isAdmin
                    ]
                    []
                ]
            , div [ class "btn-bar" ]
                [ button
                    [ class "btn btn-default"
                    , type_ "submit"
                    ]
                    [ text "Save" ]
                , button
                    [ class "btn btn-remove"
                    , type_ "button"
                    , onClick DeleteUserDialog
                    ]
                    [ text "Delete" ]
                , button
                    [ class "btn"
                    , type_ "button"
                    , id <| "default-btn-user-" ++ (String.fromInt user.id)
                    , onClick UnselectUser
                    ]
                    [ text "Cancel" ]
                ]
            ]
        ]
    else
      li []
          [ userLabel
          , div [ class "btn-bar" ]
              [ button
                  [ class "btn"
                  , id <| "default-btn-user-" ++ (String.fromInt user.id)
                  , onClick (SelectUser user.id)
                  ]
                  [ text "Edit" ]
              ]
          ]


userListView : Maybe (List UserInfo) -> Maybe UserChanges -> Html Msg
userListView maybeUsers maybeUserChanges =
    case maybeUsers of
        Just users ->
            ul [ class "user-list" ]
                (List.map (userView maybeUserChanges) users)

        Nothing ->
            text "Loading users…"


mainView : Model -> Html Msg
mainView model =
    main_
        [ id "narrator-app"
        , class "app-container app-container-simple"
        ]
        [ h1 [] [ text "Users" ]
        , bannerView model.banner
        , if model.showDeleteUserDialog then
            showDialog
              "Delete user?"
              NoOp
              "Delete"
              DeleteUser
              "Cancel"
              CancelDeleteUser
          else
            text ""
        , userListView model.users model.userUi
        , form [ class "vertical-form alt-background"
               , onSubmit SaveNewUser
               ]
            [ h2 [] [ text "Create new user" ]
            , div [ class "form-line" ]
                [ label [ for "new-user-email" ] [ text "E-mail: " ]
                , input
                    [ id "new-user-email"
                    , type_ "email"
                    , placeholder "user@example.com"
                    , value model.newUserEmail
                    , onInput UpdateNewUserEmail
                    ]
                    []
                ]
            , div [ class "form-line" ]
                [ label [ for "new-user-display-name" ] [ text "Display name: " ]
                , input [ id "new-user-display-name"
                        , type_ "text"
                        , placeholder "Magnificent Roleplayer"
                        , value model.newUserDisplayName
                        , onInput UpdateNewUserDisplayName
                        ]
                    []
                ]
            , div [ class "form-line" ]
                [ label [ for "new-user-is-admin" ] [ text "Admin? " ]
                , input [ id "new-user-is-admin"
                        , type_ "checkbox"
                        , checked model.newUserIsAdmin
                        , onCheck UpdateNewUserIsAdmin
                        ]
                    []
                ]
            , div [ class "btn-bar" ]
                [ button [ class "btn btn-default"
                         , type_ "submit"
                         ]
                    [ text "New user" ]
                ]
            ]
        ]
