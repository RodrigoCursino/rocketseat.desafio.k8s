-- Criação de uma tabela de exemplo
CREATE DATABASE IF NOT EXISTS restaurante;

USE restaurante;

CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  price DECIMAL(10,2),
  create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  update_at TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

-- Inserir dados iniciais
-- INSERT INTO produtos (nome, preco) VALUES ('Hamburguer', 25.90), ('Suco', 8.50);
