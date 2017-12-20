var express = require('express');
var app = express();
var request = require('request');
var bodyParser = require('body-parser');
require('request-debug')(request);

var MDB_API_TOKEN = process.env.MDB_API_TOKEN;

var server = require('http').Server(app);

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
  extended: true
}));

app.get('/celeb_dob', function(req, res) {
  var name = req.query.name;
  //First search for the celeb  
  const searchUrl = 'https://api.themoviedb.org/3/search/person?api_key=' + MDB_API_TOKEN + '&language=en-US&query=' + name + '&page=1&include_adult=false';
  request(searchUrl, function(error, response, body) {    
    if (response.statusCode === 200) {
      const jsonResult = JSON.parse(body);
      if (jsonResult.results.length === 0) {
        res.json({
          birthday: 'unknown'
        });
        return;
      }
      const celebDetailsUrl = 'https://api.themoviedb.org/3/person/' + jsonResult.results[0].id + '?api_key=' + MDB_API_TOKEN + '&language=en-US';
      request(celebDetailsUrl, function(error, response, body) {         
        if (response.statusCode === 200) {
          const jsonResult = JSON.parse(body);          
          res.json({
            birthday: jsonResult.birthday
          });     
          return;       
        } else {
          res.status(500).json({
                'message': 'TMDB Celeb Details API failed'
              });
          return;          
        }         
      });
    } else {
      res.status(500).json({
            'message': 'TMDB Search API Failed'
          });
    }    
  }); 
});

app.listen(8080, function () {
  console.log('Example app listening on port 8888!');
});
