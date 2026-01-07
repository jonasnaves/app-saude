FROM node:18-alpine

WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
COPY tsconfig.json ./

# Instalar dependências (incluindo devDependencies)
RUN npm install

# Copiar código fonte
COPY src ./src

# Expor porta
EXPOSE 3000

# Comando para desenvolvimento (usando ts-node-dev)
CMD ["npm", "run", "dev"]

