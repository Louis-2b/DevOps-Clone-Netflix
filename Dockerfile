# Utilise l'image officielle de Node.js version 16.17.0 basée sur Alpine Linux pour créer une image légère
FROM node:16.17.0-alpine AS builder

# Définit le répertoire de travail à "/app" dans le conteneur
WORKDIR /app

# Copie les fichiers `package.json` et `yarn.lock` dans le répertoire de travail pour installer les dépendances
COPY ./package.json .
COPY ./yarn.lock .

ARG TMDB_V3_API_KEY
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"

# Exécute la commande pour installer toutes les dépendances définies dans `package.json`
RUN yarn install

# Copie le reste du projet dans le répertoire de travail du conteneur (y compris le code source)
COPY . .

# Exécute la commande pour construire le projet (transpilation du code, minification, etc.)
RUN yarn build

# Déclare une nouvelle étape de construction à partir de l'image NGINX stable, toujours basée sur Alpine Linux
FROM nginx:stable-alpine

# Définit le répertoire de travail à "/usr/share/nginx/html", qui est le répertoire par défaut où NGINX sert les fichiers
WORKDIR /usr/share/nginx/html

# Supprime tous les fichiers existants dans le répertoire NGINX pour s'assurer qu'il est vide avant de copier les nouveaux fichiers
RUN rm -rf ./*

# Copie les fichiers générés lors de l'étape précédente (build) depuis le répertoire `/app/dist` dans le conteneur vers le répertoire NGINX
COPY --from=builder /app/dist .

# Expose le port 80 du conteneur pour permettre à NGINX de servir l'application web sur ce port
EXPOSE 80

# Définit l'entrée du conteneur, c'est-à-dire la commande qui sera exécutée lorsque le conteneur démarre.
# Ici, `nginx -g "daemon off;"` est utilisé pour que NGINX reste en exécution en avant-plan dans le conteneur.
ENTRYPOINT ["nginx", "-g", "daemon off;"]