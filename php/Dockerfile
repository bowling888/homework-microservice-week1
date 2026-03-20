FROM php:8.3-cli
WORKDIR /app

COPY public ./public
COPY composer.json ./composer.json

EXPOSE 8080
CMD ["php","-S","0.0.0.0:8080","-t","public"]

