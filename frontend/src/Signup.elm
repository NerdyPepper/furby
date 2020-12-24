module Signup exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Encode as Encode
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)


type alias Model =
    { username : String
    , password : String
    , phoneNumber : String
    , emailId : String
    , address : Maybe String
    , status : Status
    }


type Status
    = UsernameTaken
    | InvalidPhone
    | InvalidEmail
    | CreatedSuccessfully
    | CreatingUser
    | Empty


type Msg
    = UserEntered String
    | PassEntered String
    | PhoneEntered String
    | EmailEntered String
    | AddressEntered String
    | CreatePressed
    | CreationSuccess (Result Http.Error ())
    | UsernameExists (Result Http.Error String)
    | CreationFail


init : Model
init =
    Model "" "" "" "" Nothing Empty


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserEntered s ->
            ( { model | username = s }
            , Cmd.none
            )

        PassEntered s ->
            ( { model | password = s }
            , Cmd.none
            )

        PhoneEntered s ->
            let
                status =
                    if String.length s /= 10 || (List.all (not << Char.isDigit) <| String.toList s) then
                        InvalidPhone

                    else
                        Empty
            in
            ( { model | phoneNumber = s, status = status }
            , Cmd.none
            )

        EmailEntered s ->
            let
                status =
                    if not <| String.contains "@" s then
                        InvalidEmail

                    else
                        Empty
            in
            ( { model | emailId = s, status = status }
            , Cmd.none
            )

        AddressEntered s ->
            ( { model | address = Just s }
            , Cmd.none
            )

        CreatePressed ->
            ( { model | status = CreatingUser }, checkExists model )

        CreationSuccess res ->
            case res of
                Ok _ ->
                    ( { model | status = CreatedSuccessfully }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        CreationFail ->
            ( init, Cmd.none )

        UsernameExists res ->
            case res of
                Ok "true" ->
                    ( { model | status = UsernameTaken }, Cmd.none )

                Ok "false" ->
                    let
                        _ =
                            Debug.log "signup" "Hit create user ..."
                    in
                    ( { model | status = CreatingUser }, createUser model )

                _ ->
                    ( model, Cmd.none )


encodeCreateUser : Model -> Encode.Value
encodeCreateUser model =
    Encode.object
        [ ( "username", Encode.string model.username )
        , ( "password", Encode.string model.password )
        , ( "phone_number", Encode.string model.phoneNumber )
        , ( "email_id", Encode.string model.emailId )
        , ( "address", Encode.string <| Maybe.withDefault "" model.address )
        ]


checkExists : Model -> Cmd Msg
checkExists model =
    Http.post
        { url = "http://127.0.0.1:7878/user/existing"
        , body = Http.stringBody "application/json" model.username
        , expect = Http.expectString UsernameExists
        }


createUser : Model -> Cmd Msg
createUser model =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/user/new"
        , body = model |> encodeCreateUser |> Http.jsonBody
        , expect = Http.expectWhatever CreationSuccess
        , timeout = Nothing
        , tracker = Nothing
        }


viewStatus : Status -> String
viewStatus s =
    case s of
        UsernameTaken ->
            "This username is taken!"

        InvalidPhone ->
            "Invalid phone number!"

        InvalidEmail ->
            "Invalid email address!"

        CreatedSuccessfully ->
            "User created successfully"

        CreatingUser ->
            "Creating user ..."

        Empty ->
            ""


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg ] []


view : Model -> Html Msg
view model =
    div []
        [ viewInput "text" "Enter Username" model.username UserEntered
        , viewInput "password" "Password" model.password PassEntered
        , viewInput "text" "Email" model.emailId EmailEntered
        , viewInput "text" "Enter your Phone number" model.phoneNumber PhoneEntered
        , viewInput "text" "Enter Shipping address" (Maybe.withDefault "" model.address) AddressEntered
        , button [ onClick CreatePressed ] [ text "Create" ]
        , text (viewStatus model.status)
        ]
