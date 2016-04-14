var Firebase = require('firebase');
var async = require('async');
var FirebaseTokenGenerator = require("firebase-token-generator");
var moment = require('moment');
var request = require('./request');
var config = require('./pttBotConfig');

var CHANNEL = config.channel;
var tokenGenerator = new FirebaseTokenGenerator(config.firebase.key);
var root = new Firebase(config.firebase.uri);
var token = tokenGenerator.createToken({uid: "1", task: "pttBot"});
root.authWithCustomToken(token, init);

setInterval(function() {
  var token = tokenGenerator.createToken({uid: "1", task: "pttBot"});
  root.authWithCustomToken(token);
}, 60*60*1000);

function init() {
  //setInterval(pttBot, 15*60*1000);
  pttBot();
}

function pttBot() {
  async.auto({
    html: getIndexPage,
    findCount: ['html', findCount],
    posts: ['findCount', parsePosts],
    filterPosts: ['posts', filterPosts],
    getImg: ['filterPosts', getImg],
    sendMsg: ['posts', 'getImg', sendMsg],
    saveData: ['sendMsg', saveData]
  }, done);
}

function saveData(next, data) {
  var posts = data.posts;
  async.each(posts, function(post, next) {
    root.child('post').push(post, next);
  }, next);
}

function sendMsg(next, data) {
  async.each(data.posts, sendSlackMsg, next);
}

function sendSlackMsg(msg, cb) {
  request.post({
    url: CHANNEL.MEN_TALK,
    body: msgFactory(msg),
    json: true
  });

  request.post({
    url: CHANNEL.MEN_TALK2,
    body: msgFactory(msg),
    json: true
  }, cb);
}

function msgFactory(msg) {
  if(typeof msg === 'string') return {text: msg};

  return {
    attachments: [{
      title: msg.title || '',
      fallback: msg.title || '',
      title_link: msg.link || '',
      image_url: msg.img || ''
    }]
  } 
}

function getImg(next, data) {
  var posts = data.posts;
  async.each(posts, getPostContent, next);
  
  function getPostContent(post, next) {
    request.get(post.link, function(err, html) {
      if(err) return next(err);
      if(html.indexOf('i.imgur.com/') == -1) return next();
      var s = html.split('i.imgur.com/')[1].split('.jpg')[0];
      post.img = 'http://i.imgur.com/'+s+'.jpg';
      next();
    });
  }
}


function filterPosts(next, data) {
  var posts = [];
  async.each(data.posts, isExists, done);
  function done(err) {
    if(err) return next(err);
    if(posts.length == 0) return next({message: 'no posts'});
    data.posts = posts;
    next();
  }

  function isExists(post, next) {
    root.child('post')
      .orderByChild('link').equalTo(post.link)
      .once('value', function(data) {
        if(!data.val()) posts.push(post);
        next();
      });
  }
}

function parsePosts(next, data) {
  var page = data.html;
  var posts = [];
  page.split('r-ent').forEach(function(html) {
    if(html.indexOf('"title"') == -1 ||
       html.indexOf('nrec') == -1 ||
       html.indexOf('href') == -1)
       return;
    var s2 = html.split('nrec">')[1].split('</div')[0];
    if(s2.length == 0 || s2.indexOf('X') != -1) return;

    var like = s2.split('>')[1].split('<')[0];
    like = like.indexOf('爆')!=-1 ? 100 : parseInt(like);
    if(like < 30) return;

    var s = html.split('href="')[1].split('</a>')[0].split('">');
    posts.push({
      board: 'Beauty',
      push: like,
      link: 'https://www.ptt.cc'+s[0],
      title: (like==100?'爆':like) + ' ' + s[1],
      time: moment().format(),
      createAt: Firebase.ServerValue.TIMESTAMP
    });
  });
  next(null, posts);
}

function findCount(next, data) {
  var html = data.html;
  var count = html
    .split('index')[5]
    .split('.html')[0];
  count = parseInt(count);
  var i = [count, count-1, count-2, count-3];
  async.eachSeries(i, getBoard, next);

  function getBoard(i, next) {
    request.get('https://www.ptt.cc/bbs/Beauty/index'+i+'.html', function(err, html) {
      data.html += html;
      next();
    });
  }
}

function done(err, res) {
  var log = {
    time: moment().format(),
    status: 'ok'
  };
  if(err) {
    log.err = JSON.stringify(err);
    log.status = 'err';
  }
  console.log(log);
  root.child('log').push(log, function() {
    process.exit(1);
  });
}

function getIndexPage(next) {
  request.get('https://www.ptt.cc/bbs/Beauty/index.html', next);
}

