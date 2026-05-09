import mongoose from "mongoose";
import dns from "dns";

dns.setServers(['8.8.8.8', '8.8.4.4']);

const connectDB = async () => {
  mongoose.connection.on("connected", () => console.log("Database Connected ✅"));
  mongoose.connection.on("error", (err) => console.error("Database connection error ❌:", err));

  try {
    // Sirf process.env.MONGO_URI use karna hai, aur { family: 4 } add kiya hai network issue ke liye
    await mongoose.connect(process.env.MONGO_URI, {
      family: 4 
    });
    console.log("MongoDB connection function executed");
  } catch (error) {
    console.error("Initial database connection failed ❌:", error.message);
  }
};

export default connectDB;