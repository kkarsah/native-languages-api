FROM node:18-alpine

WORKDIR /app

# Install dependencies
RUN npm install express cors helmet uuid

# Copy source code
COPY index.js package.json ./

EXPOSE 3003

CMD ["node", "index.js"]
