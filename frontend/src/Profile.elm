module Profile exposing (..)

import Browser
import Browser.Navigation as Nav
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Icons exposing (..)
import Json.Decode as D
import Json.Encode as Encode
import Styles exposing (..)
import Utils exposing (..)


emptyProfile =
    UserProfile "" "" "" Nothing 0 []


type alias Transaction =
    { amount : Float
    , transactionId : Int
    , orderDate : String
    , paymentMode : String
    }


type alias UserProfile =
    { username : String
    , phoneNumber : String
    , emailId : String
    , address : Maybe String
    , ratingsGiven : Int
    , transactions : List Transaction
    }


type alias Model =
    { profile : UserProfile
    , status : Status
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = ProfileLoaded (Result Http.Error UserProfile)
    | FetchProfile


init : Model
init =
    Model emptyProfile NotLoaded


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ProfileLoaded res ->
            case res of
                Ok p ->
                    ( { model | profile = p }, Cmd.none )

                Err _ ->
                    ( { model | status = NotLoaded }, Cmd.none )

        FetchProfile ->
            ( { model | status = Loading }, tryFetchProfile )


decodeProfile : D.Decoder UserProfile
decodeProfile =
    D.map6 UserProfile
        (D.field "username" D.string)
        (D.field "phone_number" D.string)
        (D.field "email_id" D.string)
        (D.field "address" (D.nullable D.string))
        (D.field "ratings_given" D.int)
        (D.field "transactions" (D.list decodeTransaction))


decodeTransaction : D.Decoder Transaction
decodeTransaction =
    D.map4 Transaction
        (D.field "amount" D.float)
        (D.field "id" D.int)
        (D.field "order_date" D.string)
        (D.field "payment_type" D.string)


tryFetchProfile : Cmd Msg
tryFetchProfile =
    let
        _ =
            Debug.log "err" <| "fetching user profile"
    in
    Http.riskyRequest
        { method = "GET"
        , headers = []
        , url = "http://127.0.0.1:7878/user/profile"
        , body = Http.emptyBody
        , expect = Http.expectJson ProfileLoaded decodeProfile
        , timeout = Nothing
        , tracker = Nothing
        }


viewStatus : Status -> String
viewStatus s =
    case s of
        Loading ->
            "Loading"

        Loaded ->
            "Ready!"

        NotLoaded ->
            "Not loaded ..."


viewTransactions : List Transaction -> Html Msg
viewTransactions ts =
    let
        headings =
            [ "Order ID", "Date", "Amount (₹)", "Payment Mode" ]
                |> List.map (th [] << List.singleton << text)

        transactionRow t =
            List.map (td [] << List.singleton)
                [ text <| String.fromInt t.transactionId
                , text t.orderDate
                , text <| String.fromFloat t.amount
                , text t.paymentMode
                ]
    in
    div []
        [ div
            [ css [ bigHeading, marginTop (px 20), marginBottom (px 12) ] ]
            [ text "Transactions" ]
        , Html.Styled.table
            [ css
                [ Css.width (pct 100)
                , maxWidth (px 650)
                ]
            ]
            ([ tr [ style "text-align" "right" ] headings
             ]
                ++ List.map (tr [ style "text-align" "right" ] << transactionRow) ts
            )
        ]


profileField : String -> String -> Html Msg
profileField fieldName entry =
    div []
        [ div
            [ css
                [ cardSecondaryText
                , textTransform uppercase
                , paddingBottom (px 3)
                ]
            ]
            [ text fieldName ]
        , div
            [ css
                [ cardPrimaryText
                , paddingBottom (px 12)
                ]
            ]
            [ text entry ]
        ]


viewProfile : UserProfile -> Html Msg
viewProfile u =
    div
        []
        [ div
            [ css [ bigHeading, marginTop (px 20), marginBottom (px 12) ] ]
            [ text "Profile" ]
        , profileField "name" u.username
        , profileField "email" u.emailId
        , profileField "contact number" u.phoneNumber
        , profileField "address" <| Maybe.withDefault "No address provided" u.address
        , profileField "Total Reviews" <| String.fromInt u.ratingsGiven
        , hr [] []
        , viewTransactions u.transactions
        ]


view : Model -> Html Msg
view model =
    case model.status of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div
                [ css
                    [ margin auto
                    , marginTop (pct 5)
                    , Css.width (pct 40)
                    ]
                ]
                [ viewProfile model.profile ]
