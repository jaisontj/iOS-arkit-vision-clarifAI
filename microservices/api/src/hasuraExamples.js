var express = require('express');
var router = express.Router();
var config = require('./config');
var request = require('request');

router.route("/").get(function (req, res) {
  res.send("Hello world from nodejs-express")
})

//Tweak this to send details about the celebrity - like top movies, upcoming movies etc
router.route("/celeb_details").get(function (req, res) {
  console.log(req.query.name);
  res.send(req.query.name);
});

module.exports = router;
