module Product exposing (..)

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
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)
import Utils exposing (..)


type SubmitStatus
    = SubmitSuccess
    | SubmitFail
    | Submitting
    | NotSubmitted


type alias Product =
    { id : Int
    , name : String
    , kind : Maybe String
    , price : Float
    , description : Maybe String
    , src : String
    , iosSrc : String
    }


emptyProduct =
    Product -1 "" Nothing 0 Nothing "" ""


type alias Rating =
    { commentDate : String
    , commentText : Maybe String
    , customerName : String
    , productName : String
    , stars : Int
    }


type alias Model =
    { pageStatus : Status
    , listing : Product
    , ratings : List Rating
    , ratingStars : Int
    , ratingText : String
    , addRatingStatus : SubmitStatus
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = ListingLoaded (Result Http.Error Product)
    | RatingsLoaded (Result Http.Error (List Rating))
    | FetchProduct Int
    | FetchRatings Int
    | AddRatingStars Int
    | AddRatingComment String
    | AddRatingPressed
    | AddRatingSuccess (Result Http.Error ())
    | AddRatingFail
    | AddToCartSuccess (Result Http.Error ())
    | AddToCartPressed


init : Model
init =
    Model NotLoaded emptyProduct [] 5 "" NotSubmitted


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ListingLoaded res ->
            case res of
                Ok s ->
                    ( { model | listing = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        RatingsLoaded res ->
            case res of
                Ok s ->
                    ( { model | ratings = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        FetchProduct id ->
            ( { model | pageStatus = Loading }, fetchListing id )

        FetchRatings id ->
            ( { model | pageStatus = Loading }, fetchRatings id )

        AddRatingStars i ->
            ( { model | ratingStars = i }, Cmd.none )

        AddRatingComment s ->
            ( { model | ratingText = s }, Cmd.none )

        AddRatingPressed ->
            ( { model | addRatingStatus = Submitting }
            , submitRating model
            )

        AddRatingSuccess res ->
            case res of
                Ok _ ->
                    ( { model | addRatingStatus = SubmitSuccess }, fetchRatings model.listing.id )

                Err _ ->
                    ( { model | addRatingStatus = SubmitFail }, Cmd.none )

        AddRatingFail ->
            ( { model | addRatingStatus = SubmitFail }, Cmd.none )

        AddToCartPressed ->
            ( model, addToCart model )

        AddToCartSuccess _ ->
            ( model, Cmd.none )


decodeProduct : D.Decoder Product
decodeProduct =
    D.map7 Product
        (D.field "id" D.int)
        (D.field "name" D.string)
        (D.field "kind" (D.nullable D.string))
        (D.field "price" D.float)
        (D.field "description" (D.nullable D.string))
        (D.field "src" D.string)
        (D.field "ios_src" D.string)


decodeRating : D.Decoder Rating
decodeRating =
    D.map5 Rating
        (D.field "comment_date" D.string)
        (D.field "comment_text" (D.nullable D.string))
        (D.field "customer_name" D.string)
        (D.field "product_name" D.string)
        (D.field "stars" D.int)


decodeRatings : D.Decoder (List Rating)
decodeRatings =
    D.list decodeRating


fetchListing : Int -> Cmd Msg
fetchListing id =
    let
        _ =
            Debug.log "err" <| "fetching listing " ++ String.fromInt id
    in
    Http.get
        { url = "http://127.0.0.1:7878/product/" ++ String.fromInt id
        , expect = Http.expectJson ListingLoaded decodeProduct
        }


fetchRatings : Int -> Cmd Msg
fetchRatings id =
    let
        _ =
            Debug.log "err" <| "fetching ratings " ++ String.fromInt id
    in
    Http.get
        { url = "http://127.0.0.1:7878/product/reviews/" ++ String.fromInt id
        , expect = Http.expectJson RatingsLoaded decodeRatings
        }


encodeRatingForm : Model -> Encode.Value
encodeRatingForm model =
    Encode.object
        [ ( "product_id", Encode.int model.listing.id )
        , ( "stars", Encode.int model.ratingStars )
        , ( "comment_text", Encode.string model.ratingText )
        ]


submitRating : Model -> Cmd Msg
submitRating model =
    let
        _ =
            Debug.log "err" <| "submitting rating for" ++ String.fromInt model.listing.id
    in
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/rating/add"
        , body = model |> encodeRatingForm |> Http.jsonBody
        , expect = Http.expectWhatever AddRatingSuccess
        , timeout = Nothing
        , tracker = Nothing
        }


addToCart : Model -> Cmd Msg
addToCart model =
    let
        _ =
            Debug.log "err" <| "adding to cart: " ++ String.fromInt model.listing.id
    in
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/add"
        , body = Http.stringBody "applcation/json" <| String.fromInt <| model.listing.id
        , expect = Http.expectWhatever AddToCartSuccess
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
    div
        [ css
            [ marginBottom (px 20)
            , paddingTop (px 20)
            , Css.width (pct 100)
            ]
        ]
        [ div
            [ css
                [ float left
                , Css.width (pct 50)
                , Css.height (px 400)
                ]
            ]
            [ modelViewer
                [ cameraControls
                , autoRotate
                , arSrc p.src
                , arIosSrc p.iosSrc
                , loading "eager"
                , arModes "webxr"
                , css [ Css.height (pct 100), Css.width (pct 100) ]
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
                    , paddingBottom (px 12)
                    ]
                ]
                [ text p.name ]
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
        , div
            [ css [ textAlign center, float bottom ] ]
            [ furbyButton [ onClick AddToCartPressed, style "width" "100%" ] [ text "Add To Cart" ] ]
        , div [ style "clear" "both" ] []
        ]


viewStarRating : Int -> Html Msg
viewStarRating i =
    div []
        (List.repeat i starIcon)


viewRating : Rating -> Html Msg
viewRating r =
    -- div []
    --     [ text <| r.customerName ++ " posted on "
    --     , text <| r.commentDate ++ " "
    --     , text <| Maybe.withDefault "" r.commentText
    --     , text <| " Stars: " ++ String.fromInt r.stars
    --     ]
    div
        [ css
            [ border3 (px 1) solid theme.primary
            , borderRadius (px 4)
            , marginBottom (px 20)
            , padding (px 20)
            ]
        ]
        [ div
            [ css
                [ fontSize (px 16)
                , fontWeight bold
                , paddingBottom (px 3)
                ]
            ]
            [ text r.customerName ]
        , viewStarRating r.stars
        , div
            [ css
                [ cardSecondaryText
                , paddingBottom (px 12)
                ]
            ]
            [ text <| "Reviewed on " ++ r.commentDate ]
        , if r.commentText /= Nothing then
            div
                [ css [ cardSupportingText ] ]
                [ text <| Maybe.withDefault "" <| r.commentText ]

          else
            text ""
        ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input
        [ type_ t
        , placeholder p
        , value v
        , onInput toMsg
        , css [ Css.width (pct 100) ]
        ]
        []


viewStars : Model -> Html Msg
viewStars model =
    let
        activeStyle =
            [ border3 (px 3) solid theme.fg ]

        inactiveStyle =
            [ border3 (px 3) solid theme.primary ]

        buttonStyle =
            [ borderRadius (px 6), margin (px 6), backgroundColor theme.bg, padding2 (px 4) (px 8) ]
    in
    div
        [ css
            [ Css.width (pct 100)
            , margin auto
            , padding (px 12)
            , textAlign center
            ]
        ]
        (List.map
            (\i ->
                button
                    [ onClick (AddRatingStars i)
                    , (if i == model.ratingStars then
                        activeStyle

                       else
                        inactiveStyle
                      )
                        ++ buttonStyle
                        |> css
                    ]
                    [ text <| String.fromInt i ]
            )
            [ 1, 2, 3, 4, 5 ]
        )


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div
                [ css
                    [ Css.width (pct 50)
                    , margin auto
                    ]
                ]
                [ div [] [ viewProduct model.listing ]
                , div
                    [ css [ cardPrimaryText ] ]
                    [ text "User Reviews" ]
                , if model.ratings == [] then
                    text "Be the first to add a review."

                  else
                    ul
                        [ css
                            [ padding (px 0)
                            , listStyle Css.none
                            ]
                        ]
                        (List.map viewRating model.ratings)
                , div
                    [ css [ cardPrimaryText, margin2 (px 20) (px 0) ] ]
                    [ text "Rate this product" ]
                , div
                    []
                    [ viewStars model
                    , div
                        []
                        [ textarea
                            [ onInput AddRatingComment
                            , rows 5
                            , placeholder "Enter comment text"
                            , css [ Css.width (pct 100) ]
                            ]
                            [ text model.ratingText ]
                        ]
                    , div
                        [ css
                            [ textAlign center ]
                        ]
                        [ furbyButton [ onClick AddRatingPressed ] [ text "Submit Rating" ] ]
                    ]
                ]
