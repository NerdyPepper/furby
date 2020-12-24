module Catalog exposing (..)

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
    = ProductsLoaded (Result Http.Error (List Product))
    | FetchProducts


init : Model
init =
    Model NotLoaded []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ProductsLoaded res ->
            case res of
                Ok s ->
                    ( { model | products = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        FetchProducts ->
            ( { model | pageStatus = Loading }, fetchProducts )


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


fetchProducts : Cmd Msg
fetchProducts =
    let
        _ =
            Debug.log "err" "fetching products"
    in
    Http.get
        { url = "http://127.0.0.1:7878/product/catalog"
        , expect = Http.expectJson ProductsLoaded decodeResponse
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
        , text <| Maybe.withDefault "" p.kind
        , text <| Maybe.withDefault "" p.description
        , text <| String.fromFloat p.price
        , a [ href ("/product/" ++ String.fromInt p.id) ] [ text "View Product" ]
        ]


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div []
                [ ul [] (List.map viewProduct model.products)
                ]
