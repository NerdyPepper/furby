module Utils exposing (..)

import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)


between : ( Float, Float ) -> Float -> Bool
between ( l, u ) v =
    v >= l && v <= u


flip : (a -> b -> c) -> (b -> a -> c)
flip f =
    \b a -> f a b


range : Int -> Int -> Int -> List Int
range start stop step =
    if start >= stop then
        []

    else
        start :: range (start + step) stop step


modelViewer : List (Attribute msg) -> List (Html msg) -> Html msg
modelViewer attributes children =
    node "model-viewer" attributes children


cameraControls : Attribute msg
cameraControls =
    attribute "camera-controls" ""


autoRotate : Attribute msg
autoRotate =
    attribute "auto-rotate" ""


ar : Attribute msg
ar =
    attribute "ar" ""


arSrc : String -> Attribute msg
arSrc src =
    attribute "src" src


arIosSrc : String -> Attribute msg
arIosSrc src =
    attribute "ios-src" src


arModes : String -> Attribute msg
arModes mode =
    attribute "ar-modes" mode


loading : String -> Attribute msg
loading mode =
    attribute "loading" mode
