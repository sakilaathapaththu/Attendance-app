import axios from "axios";
import { BASE_URL } from "../utils/config";

export const loginUser = async (email, password) => {
  const response = await axios.post(`${BASE_URL}/auth/login`, {
    email,
    password,
  });
  return response.data;
};
