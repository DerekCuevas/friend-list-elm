require("./main.css");
var Elm = require("./Main.elm");

var root = document.getElementById("root");

Elm.Main.App.embed(root);
