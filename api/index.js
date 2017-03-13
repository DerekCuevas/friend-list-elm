const express = require('express');
const friends = require('./friends.json');
const app = express();

const FAILURE_RATE = 0.25;

app.get('/api/friends', (req, res) => {
  const { query } = req;
  const { q = '' } = query;

  const results = friends.filter((friend) => (
    Object.keys(friend).find(key => (
      !!friend[key].toString().toLowerCase().includes(q.toLowerCase())
    ))
  ));

  if (Math.random() < FAILURE_RATE) {
    res.status(500).send(`Sorry! Request for "${q}" failed 😥.`);
  } else {
    res.json({ results, count: results.length });
  }
});

app.listen(8000, () => {
  console.log('Listening on http://localhost:8000');
});
