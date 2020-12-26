module Login exposing (..)

import Browser
import Browser.Navigation as Nav
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Icons exposing (..)
import Json.Encode as Encode
import Styles exposing (..)
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)


type alias Model =
    { username : String
    , password : String
    , loginStatus : LoginStatus
    }


type LoginStatus
    = NotLoggedIn
    | LoggedIn
    | InvalidLogin
    | LoggingIn


type Msg
    = PassEntered String
    | UserEntered String
    | LoginPressed
    | LoginSuccess (Result Http.Error ())
    | LoginFail


init : Model
init =
    Model "" "" NotLoggedIn


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PassEntered s ->
            ( { model | password = s }
            , Cmd.none
            )

        UserEntered s ->
            ( { model | username = s }
            , Cmd.none
            )

        LoginPressed ->
            ( { model | loginStatus = LoggingIn }, tryLogin model )

        LoginSuccess res ->
            case res of
                Ok s ->
                    ( { model | loginStatus = LoggedIn }, Cmd.none )

                Err e ->
                    ( { model | loginStatus = InvalidLogin }, Cmd.none )

        LoginFail ->
            ( { model | loginStatus = InvalidLogin }, Cmd.none )


encodeLogin : Model -> Encode.Value
encodeLogin model =
    Encode.object
        [ ( "username", Encode.string model.username )
        , ( "password", Encode.string model.password )
        ]


tryLogin : Model -> Cmd Msg
tryLogin model =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/user/login"
        , body = model |> encodeLogin |> Http.jsonBody
        , expect = Http.expectWhatever LoginSuccess
        , timeout = Nothing
        , tracker = Nothing
        }


viewStatus : LoginStatus -> String
viewStatus ls =
    case ls of
        NotLoggedIn ->
            ""

        InvalidLogin ->
            "Invalid Login"

        LoggedIn ->
            "Logged in!"

        LoggingIn ->
            "Logging In ..."


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    loginInputField [ type_ t, placeholder p, value v, onInput toMsg ] []


fieldPadding =
    css
        [ paddingTop (px 10)
        , paddingBottom (px 10)
        ]


view : Model -> Html Msg
view model =
    div
        [ css
            [ margin auto
            , marginTop (pct 10)
            , padding (px 20)
            , Css.width (pct 30)
            ]
        ]
        [ div [ fieldPadding, css [ bigHeading ] ] [ text "Login" ]
        , div [ fieldPadding ] [ viewInput "text" "Enter name here" model.username UserEntered ]
        , div [ fieldPadding ] [ viewInput "password" "Password" model.password PassEntered ]
        , div [ css [ textAlign center ], fieldPadding ] [ furbyButton [ onClick LoginPressed ] [ text "Login" ] ]
        , div [ css [ textAlign center ] ] [ text (viewStatus model.loginStatus) ]
        , div [ fieldPadding ] [ text "Don't have an account? ", a [ href "/signup" ] [ text "Register now!" ] ]
        ]
