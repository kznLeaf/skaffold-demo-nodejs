'use strict';

const express = require('express')
const path = require('path')
const app = express()

// __dirname 是指当前文件所在的目录的绝对路径
// ../public 是相对于当前文件目录的上一级目录下的 public 目录
// path.join 用于拼接路径，确保不同操作系统下路径格式的正确性
app.use(express.static(path.join(__dirname, '../public')));
app.get('/hello', (req, res) => res.send('Hello World'))

const port = 3000
app.listen(port, () => console.log(`Example app listening on port ${port}!`))