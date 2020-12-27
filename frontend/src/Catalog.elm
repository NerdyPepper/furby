module Catalog exposing (..)

import Browser
import Browser.Navigation as Nav
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Styles exposing (..)
import Tuple exposing (..)
import Utils exposing (..)


type Order
    = Rating
    | Price


type alias Product =
    { id : Int
    , name : String
    , kind : Maybe String
    , price : Float
    , description : Maybe String
    , averageRating : Maybe Float
    , src : String
    , iosSrc : String
    }


type alias Filters =
    { price : ( Float, Float )
    , rating : ( Float, Float )
    }


defaultFilters : Filters
defaultFilters =
    Filters ( -1, 100000 ) ( 0, 5 )


type alias Model =
    { pageStatus : Status
    , products : List Product
    , filters : Filters
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = ProductsLoaded (Result Http.Error (List Product))
    | FetchProducts
    | ChangePriceLower Float
    | ChangePriceUpper Float
    | ChangeRatingLower Float
    | ChangeRatingUpper Float


init : Model
init =
    Model NotLoaded [] defaultFilters


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

        ChangePriceLower v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | price = mapFirst (always v) fs.price }
            in
            ( { model | filters = nfs }, Cmd.none )

        ChangePriceUpper v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | price = mapSecond (always v) fs.price }
            in
            ( { model | filters = nfs }, Cmd.none )

        ChangeRatingLower v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | rating = mapFirst (always v) fs.rating }
            in
            ( { model | filters = nfs }, Cmd.none )

        ChangeRatingUpper v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | rating = mapSecond (always v) fs.rating }
            in
            ( { model | filters = nfs }, Cmd.none )


decodeProduct : D.Decoder Product
decodeProduct =
    D.map8 Product
        (D.field "id" D.int)
        (D.field "name" D.string)
        (D.field "kind" (D.nullable D.string))
        (D.field "price" D.float)
        (D.field "description" (D.nullable D.string))
        (D.field "average_rating" (D.nullable D.float))
        (D.field "src" D.string)
        (D.field "ios_src" D.string)


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
    div
        [ css
            [ marginBottom (px 20)
            , border3 (px 1) solid theme.primary
            , borderRadius (px 4)
            , padding (px 20)
            , Css.width (pct 100)
            , maxWidth (px 650)
            ]
        ]
        [ div
            [ css
                [ float left
                , Css.width (pct 50)
                ]
            ]
            [ modelViewer
                [ cameraControls
                , autoRotate
                , arSrc p.src
                , arIosSrc p.iosSrc
                , loading "eager"
                , arModes "webxr"
                ]
                []
            ]
        , div
            [ css
                [ float left
                , Css.width (pct 50)
                ]
            ]
            [ div
                [ css
                    [ cardSecondaryText
                    , paddingBottom (px 3)
                    , textTransform uppercase
                    ]
                ]
                [ text <| Maybe.withDefault "" p.kind ]
            , div
                [ css
                    [ cardPrimaryText
                    , paddingBottom (px 3)
                    ]
                ]
                [ a [ href ("/product/" ++ String.fromInt p.id) ] [ text p.name ] ]
            , div
                [ css
                    [ cardSecondaryText
                    , paddingBottom (px 12)
                    ]
                ]
                [ case p.averageRating of
                    Just v ->
                        text <| "Avg Rating: " ++ String.fromFloat v

                    Nothing ->
                        text "No Ratings"
                ]
            , div
                [ css
                    [ cardSupportingText
                    , paddingBottom (px 6)
                    ]
                ]
                [ text <| Maybe.withDefault "No description provided" p.description ]
            , div
                [ css
                    [ fontWeight bold
                    , fontSize (px 14)
                    , money
                    ]
                ]
                [ text <| String.fromFloat p.price ]
            ]
        , div [ style "clear" "both" ] []
        ]


viewFilters : Model -> Html Msg
viewFilters model =
    let
        priceRange =
            range 0 55000 5000

        ratingRange =
            range 1 6 1

        viewRange default scale =
            List.map (\i -> option [ selected (i == default) ] [ text <| String.fromInt i ]) scale

        inp =
            Maybe.withDefault 0 << String.toFloat
    in
    div
        []
        [ div
            [ css
                [ bigHeading
                , paddingBottom (px 12)
                ]
            ]
            [ text "Filters" ]
        , div []
            [ div [] [ text "Price" ]
            , furbySelect [ onInput (ChangePriceLower << inp), style "appearance" "none" ] (viewRange 0 priceRange)
            , text "to"
            , furbySelect [ onInput (ChangePriceUpper << inp), style "appearance" "none" ] (viewRange 50000 priceRange)
            ]
        , div []
            [ div [] [ text "Rating" ]
            , furbySelect [ onInput (ChangeRatingLower << inp), style "appearance" "none" ] (viewRange 1 ratingRange)
            , text "to"
            , furbySelect [ onInput (ChangeRatingUpper << inp), style "appearance" "none" ] (viewRange 5 ratingRange)
            ]
        ]


filterProducts : Model -> List Product
filterProducts model =
    model.products
        |> List.filter (between model.filters.price << .price)
        |> List.filter
            (\p ->
                p.averageRating
                    |> Maybe.withDefault 5.0
                    |> between model.filters.rating
            )


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div
                [ css [ padding (px 40) ] ]
                [ div
                    [ css
                        [ float left
                        , Css.width (pct 20)
                        ]
                    ]
                    [ viewFilters model ]
                , div
                    [ css
                        [ float left
                        , Css.width (pct 80)
                        ]
                    ]
                    [ div [ css [ bigHeading ] ] [ text "Products" ]
                    , ul
                        [ css
                            [ padding (px 0)
                            , listStyle Css.none
                            ]
                        ]
                        (filterProducts model |> List.map viewProduct)
                    ]
                ]
