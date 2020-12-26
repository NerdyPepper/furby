module Icons exposing (..)

import FeatherIcons exposing (toHtml)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)


convert =
    Html.Styled.fromUnstyled << toHtml []


loginIcon =
    convert FeatherIcons.logIn
