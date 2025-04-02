FROM node:18-bullseye-slim

# Instala Firebase CLI globalmente
RUN npm install -g firebase-tools

# Directorio de trabajo
WORKDIR /app

# Copia el código del proyecto al contenedor (opcional si lo montas)
COPY . /app

# Punto de entrada
CMD [ "bash" ]