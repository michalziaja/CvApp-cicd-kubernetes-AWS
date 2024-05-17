import axios from 'axios'

//const baseURL = 'http://127.0.0.1:8000/api/v1/' //LOCAL

//const baseURL = 'http://fastapi:8000/api/v1/' //Docker

//const baseURL = ('http://'+`${process.env.API_HOST}`+':'+`${process.env.API_PORT}`+'/api/v1/')

const baseURL =  'http://cvapp-api/api/v1'

//const baseURL = process.env.API_URL

const axiosInstance = axios.create({
    baseURL
})

axiosInstance.interceptors.response.use(
    (response) => response,
    (error) => {
        return Promise.reject(error)
    }
)

export default axiosInstance