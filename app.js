import express from 'express'
import cors from 'cors'
import fileUpload from 'express-fileupload'
import {exec} from 'child_process';
import path from 'path';
import url from 'url';

const __filename = url.fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);


const app = express()
app.use(express.json())
app.use(cors())
app.use(fileUpload())



app.get("/", (req, res) => {

    res.sendFile(__dirname+'/index.html')
}) 


app.post("/",  async (req, res) => {
    if(req.files) {
        const search_pattern = req.body.search_pattern
        const filename = req.files.file.name
        req.files.file.mv('./input/' + req.files.file.name)
        const command = "bash shellScript.sh -f ./input/"+filename + " -s " + search_pattern

        const script = await exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(`exec error: ${error}`);
                res.send('error parsing')

            }
            else {
                console.log(`stdout: ${stdout}`);
                console.error(`stderr: ${stderr}`);
                res.sendFile(__dirname + '/input/' + filename + "_mem_leaks")
            }

        });

    }
}) 





app.use((err, req, res, next) => {
    console.error(err.stack)
    res.status(500).send("something broke!").end()
})

const port = 5000

app.listen(port, () => {
    console.log("server is running on the port:", port)
})