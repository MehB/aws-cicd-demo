const express = require('express')
const app = express()
const port = process.env.PORT || 3000 ;
const config = require('config')
console.log(config);

app.get('/', (req, res) => {
  var str = '<p style="color:#C00;text-align:center;">CI/CD DEMO App V1!</p>';
  var result = str.fontsize(7);
  res.send(result)
})

app.get('/status', (req, res) => {
    res.send('ok')
  })

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`)
})