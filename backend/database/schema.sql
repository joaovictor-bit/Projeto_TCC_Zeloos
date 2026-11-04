CREATE DATABASE IF NOT EXISTS pulseira_localizadora;
USE pulseira_localizadora;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  telefone VARCHAR(30) NULL,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS criancas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  data_nascimento DATE NULL,
  foto_url VARCHAR(255) NULL,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS responsaveis_criancas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  crianca_id INT NOT NULL,
  tipo_relacao VARCHAR(50) NOT NULL DEFAULT 'responsavel',
  permissao VARCHAR(50) NOT NULL DEFAULT 'admin',
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_responsaveis_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_responsaveis_crianca FOREIGN KEY (crianca_id) REFERENCES criancas(id) ON DELETE CASCADE,
  UNIQUE KEY unique_usuario_crianca (usuario_id, crianca_id)
);

CREATE TABLE IF NOT EXISTS pulseiras (
  id INT AUTO_INCREMENT PRIMARY KEY,
  crianca_id INT NOT NULL,
  identificador VARCHAR(80) NOT NULL UNIQUE,
  nome_dispositivo VARCHAR(120) NULL,
  modelo VARCHAR(80) NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'ativa',
  status_conexao VARCHAR(30) NOT NULL DEFAULT 'desconectada',
  ultima_comunicacao_em DATETIME NULL,
  bateria_percentual INT NULL,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pulseiras_crianca FOREIGN KEY (crianca_id) REFERENCES criancas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS localizacoes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pulseira_id INT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  precisao_metros DECIMAL(10,2) NULL,
  bateria_percentual INT NULL,
  origem VARCHAR(50) NOT NULL DEFAULT 'dispositivo',
  registrada_em DATETIME NOT NULL,
  recebida_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_localizacoes_pulseira FOREIGN KEY (pulseira_id) REFERENCES pulseiras(id) ON DELETE CASCADE,
  KEY idx_localizacoes_pulseira_registrada (pulseira_id, registrada_em DESC)
);

CREATE TABLE IF NOT EXISTS locais_seguros (
  id INT AUTO_INCREMENT PRIMARY KEY,
  crianca_id INT NOT NULL,
  nome VARCHAR(120) NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  raio_metros DECIMAL(10,2) NOT NULL,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_locais_crianca FOREIGN KEY (crianca_id) REFERENCES criancas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS alertas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  crianca_id INT NOT NULL,
  pulseira_id INT NULL,
  local_seguro_id INT NULL,
  tipo VARCHAR(60) NOT NULL,
  titulo VARCHAR(150) NOT NULL,
  mensagem TEXT NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'novo',
  ocorrido_em DATETIME NOT NULL,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  visualizado_em DATETIME NULL,
  CONSTRAINT fk_alertas_crianca FOREIGN KEY (crianca_id) REFERENCES criancas(id) ON DELETE CASCADE,
  CONSTRAINT fk_alertas_pulseira FOREIGN KEY (pulseira_id) REFERENCES pulseiras(id) ON DELETE SET NULL,
  CONSTRAINT fk_alertas_local_seguro FOREIGN KEY (local_seguro_id) REFERENCES locais_seguros(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS configuracoes_alertas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  crianca_id INT NOT NULL,
  usuario_id INT NOT NULL,
  alerta_saida_local TINYINT(1) NOT NULL DEFAULT 1,
  alerta_entrada_local TINYINT(1) NOT NULL DEFAULT 1,
  alerta_desconexao TINYINT(1) NOT NULL DEFAULT 1,
  alerta_bateria_baixa TINYINT(1) NOT NULL DEFAULT 1,
  limite_bateria_percentual INT NOT NULL DEFAULT 20,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_config_alertas_crianca FOREIGN KEY (crianca_id) REFERENCES criancas(id) ON DELETE CASCADE,
  CONSTRAINT fk_config_alertas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  UNIQUE KEY unique_config_crianca_usuario (crianca_id, usuario_id)
);

CREATE INDEX idx_pulseiras_crianca ON pulseiras (crianca_id);
CREATE INDEX idx_localizacoes_pulseira ON localizacoes (pulseira_id);
CREATE INDEX idx_locais_crianca ON locais_seguros (crianca_id);
CREATE INDEX idx_alertas_crianca_status ON alertas (crianca_id, status);
