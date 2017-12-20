var express = require('express');
var app = express();
var request = require('request');
var morgan = require('morgan');
var bodyParser = require('body-parser');
require('request-debug')(request);

var MDB_API_TOKEN = process.env.MDB_API_TOKEN;

var server = require('http').Server(app);

router.use(morgan('dev'));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
  extended: true
}));

app.get('/celeb_dob', function(req, res) {
  var name = req.query.name;
  res.json({
    birthday: '22-09-1998'
  });
});

app.listen(8888, function () {
  console.log('Example app listening on port 8888!');
});
