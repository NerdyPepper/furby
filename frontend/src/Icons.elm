module Icons exposing (..)

import FeatherIcons exposing (toHtml, withSize)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)


convert =
    Html.Styled.fromUnstyled << toHtml [] << withSize 14


loginIcon =
    convert FeatherIcons.logIn


starIcon =
    convert FeatherIcons.star
