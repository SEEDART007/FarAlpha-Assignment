// src/server.js
const express = require('express');
const app = express();

// single route /sayHello
app.get('/sayHello', (req, res) => {
  res.json({ message: 'Hello User' });
});

// Use port 80 as required by the challenge
const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 80;

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
