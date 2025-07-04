FROM node:18-alpine

WORKDIR /app

# Install packages directly
RUN npm install express cors helmet

# Copy source code
COPY index.js ./

EXPOSE 3000

CMD ["node", "index.js"]
