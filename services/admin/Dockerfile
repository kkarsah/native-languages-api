FROM node:18-alpine

WORKDIR /app

# Install dependencies
RUN npm install express cors helmet

# Copy source code
COPY index.js package.json ./

EXPOSE 3004

CMD ["node", "index.js"]
