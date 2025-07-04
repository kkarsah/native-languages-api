FROM node:18-alpine

WORKDIR /app

# Install packages directly  
RUN npm install express cors helmet multer

# Copy source code
COPY index.js ./

EXPOSE 3001

CMD ["node", "index.js"]
