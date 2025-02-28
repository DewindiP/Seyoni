const mongoose = require("mongoose");

const reservationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  profileImage: {
    type: String,
    required: true,
  },
  rating: {
    type: Number,
    required: true,
  },
  profession: {
    type: String,
    required: true,
  },
  serviceType: {
    type: String,
    required: true,
  },
  location: {
    type: String,
    required: true,
  },
  time: {
    type: String,
    required: true,
  },
  date: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  images: [String],
  seeker: {
    id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Seeker",
      required: true,
    },
    firstName: {
      type: String,
      required: true,
    },
    lastName: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
    },
    profileImageUrl: {
      type: String,
      required: true,
    },
  },
  providerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Provider",
    required: true,
  },
  status: {
    type: String,
    enum: ["pending", "accepted", "rejected", "finished"],
    default: "pending",
  },
  serviceTime: {
    type: Number,
    default: 0,
  },
  amount: {
    type: Number,
    default: 0,
  },
  paymentMethod: {
    type: String,
    enum: ["cash", "card", "pending"],
    default: "pending",
  },
  paymentStatus: {
    type: String,
    enum: ["pending", "paid"],
    default: "pending",
  },
  completedAt: {
    type: Date,
  },
});

module.exports = mongoose.model("Reservation", reservationSchema);
