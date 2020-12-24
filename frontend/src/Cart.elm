module Cart exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)


type alias Product =
    { id : Int
    , name : String
    , kind : Maybe String
    , price : Float
    , description : Maybe String
    }


type alias Model =
    { pageStatus : Status
    , products : List Product
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = CartLoaded (Result Http.Error (List Product))
    | FetchCartItems
    | RemoveFromCart Int
    | CartItemRemoved (Result Http.Error ())


init : Model
init =
    Model NotLoaded []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CartLoaded res ->
            case res of
                Ok s ->
                    ( { model | products = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        RemoveFromCart id ->
            ( model, removeProduct id )

        CartItemRemoved _ ->
            ( { model | pageStatus = Loading }, fetchCartItems )

        FetchCartItems ->
            ( { model | pageStatus = Loading }, fetchCartItems )


decodeProduct : D.Decoder Product
decodeProduct =
    D.map5 Product
        (D.field "id" D.int)
        (D.field "name" D.string)
        (D.field "kind" (D.nullable D.string))
        (D.field "price" D.float)
        (D.field "description" (D.nullable D.string))


decodeResponse : D.Decoder (List Product)
decodeResponse =
    D.list decodeProduct


removeProduct : Int -> Cmd Msg
removeProduct id =
    let
        _ =
            Debug.log "cart" "fetching cart items"
    in
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/remove"
        , body = Http.stringBody "application/json" <| String.fromInt id
        , expect = Http.expectWhatever CartItemRemoved
        , timeout = Nothing
        , tracker = Nothing
        }


fetchCartItems : Cmd Msg
fetchCartItems =
    let
        _ =
            Debug.log "cart" "fetching cart items"
    in
    Http.riskyRequest
        { method = "GET"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/items"
        , body = Http.emptyBody
        , expect = Http.expectJson CartLoaded decodeResponse
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


viewProduct : Product -> Html Msg
viewProduct p =
    div []
        [ text p.name
        , div [] [ text <| Maybe.withDefault "" p.kind ]
        , div [] [ text <| Maybe.withDefault "" p.description ]
        , div [] [ text <| String.fromFloat p.price ]
        , div [] [ button [ onClick (RemoveFromCart p.id) ] [ text "Remove" ] ]
        , div [] [ a [ href ("/product/" ++ String.fromInt p.id) ] [ text "View Product" ] ]
        ]


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div []
                [ let
                    cart =
                        List.map viewProduct model.products
                  in
                  if List.isEmpty cart then
                    text "No items in cart"

                  else
                    ul [] cart
                ]
