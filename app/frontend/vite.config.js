// import { defineConfig } from 'vite'
// import react from '@vitejs/plugin-react-swc'

// // https://vitejs.dev/config/
// export default defineConfig({
//   plugins: [react({
//     include: "**/*.jsx"
//   })],
//   base: "/",
//   // server: {
//   //   watch: {
//   //     usePolling: true,
//   //   },
//   //   host: '0.0.0.0',
//   //   port: 3000,
//   // },
//   build: {
//     outDir: 'dist', // katalog wyjściowy dla zbudowanych plików
//     assetsDir: '.', // katalog zasobów
//     sourcemap: false, // wyłącz mapy źródłowe (jeśli nie są potrzebne)
//     port: 3000
//   }
// })


import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react({
    include: "**/*.jsx"
  })],
  base: "/",
  preview: {
    port: 80,
    strictPort: true,
  },
  server: {
    port: 80,
    strictPort: true,
    host: true,
    origin: "http://0.0.0.0:80",
  },
});