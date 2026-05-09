import dotenv from 'dotenv'
dotenv.config() // Sabse pehle config load hona chahiye

import express from 'express'
import cors from 'cors'
import connectDB from './config/mongodb.js'
import connectCloudinary from './config/cloudinary.js'
import adminRouter from './routes/adminRoute.js'
import doctorRouter from './routes/doctorRoute.js'
import userRouter from './routes/userRoute.js'

// app config
const app = express()
const port = process.env.PORT || 4000

// Connect to database
connectDB()
connectCloudinary()

// middlewares
app.use(express.json())
app.use(cors({
  origin: true,
  credentials: true
}))

// api endpoints
app.use('/api/admin', adminRouter)
app.use('/api/doctor', doctorRouter)
app.use("/api/user", userRouter)

app.get("/", (req, res) => {
  res.send("API Working")
});

app.listen(port, () => console.log(`Server started on PORT:${port}`))