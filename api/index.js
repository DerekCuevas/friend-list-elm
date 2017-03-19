const express = require('express');
const cors = require('cors')
const friends = require('./friends.json');

const FAILURE_RATE = 0.25;
const app = express();

app.use(cors());

app.get('/api/friends', (req, res) => {
  const { query } = req;
  const q = (query.q || '').toLowerCase();

  const results = friends.filter((friend) => (
    Object.keys(friend).find(key => (
      !!friend[key].toString().toLowerCase().includes(q)
    ))
  ));

  setTimeout(() => {
    if (Math.random() < FAILURE_RATE) {
      res.status(500).send(`Request for '${q}' failed 😥.`);
    } else {
      res.json({ results, count: results.length, query: query.q });
    }
  }, Math.random() * 500);
});

app.listen(8000, () => {
  console.log('Listening on http://localhost:8000');
});
