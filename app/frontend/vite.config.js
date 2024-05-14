import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react({
    include: "**/*.jsx"
  })],
  server: {
    watch: {
      usePolling: true,
    },
    host: '0.0.0.0',
    port: 3000,
  },
  // build: {
  //   outDir: 'dist', // katalog wyjściowy dla zbudowanych plików
  //   assetsDir: '.', // katalog zasobów
  //   //sourcemap: false, // wyłącz mapy źródłowe (jeśli nie są potrzebne)
  //   port: 8000
  // }
})