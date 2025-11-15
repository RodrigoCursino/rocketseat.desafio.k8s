# Variáveis de ambiente para configuração inicial
FROM mysql:8.0
ENV MYSQL_ROOT_PASSWORD=root123
ENV MYSQL_DATABASE=restaurante
ENV MYSQL_HOST=mysql
ENV MYSQL_USER=rocketseat
ENV MYSQL_PASSWORD=rocketseat123
ENV TZ=America/Sao_Paulo
ENV MYSQL_ROOT_HOST=mysql
ENV MYSQL_PORT=3306
# Copia scripts SQL personalizados (opcional)
# Esses scripts serão executados automaticamente na primeira inicialização
COPY ./init.sql /docker-entrypoint-initdb.d/

EXPOSE 3306

# docker build -t mysql-desafio-rocketseat:v1 .
# docker run -d --name mysql8-desafio-rocketseat -p 3306:3306 mysql-desafio-rocketseat:v1
# docker exec -it mysql8-desafio-rocketseat bash
# mysql -u root -p
# Enter password: root123
# SHOW DATABASES;
# USE restaurante;
# SHOW TABLES;
# SELECT * FROM produtos;   
# docker exec -it mysql8-desafio-rocketseat mysql -u root -p