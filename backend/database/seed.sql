USE pulseira_localizadora;

INSERT INTO usuarios (nome, email, senha_hash, telefone, ativo) VALUES
('Responsável Demo', 'responsavel@demo.com', '$2a$10$2L5xE7s7eYg8GdY2Z4.jsO0aA7S8EJQ0Wg3w1pZs3E4mQ2hVO1W2W', '(11) 99999-0001', 1),
('Ana Silva', 'ana@demo.com', '$2a$10$2L5xE7s7eYg8GdY2Z4.jsO0aA7S8EJQ0Wg3w1pZs3E4mQ2hVO1W2W', '(11) 99999-0002', 1);

INSERT INTO criancas (nome, data_nascimento, foto_url, ativo) VALUES
('Maria', '2018-05-12', 'https://example.com/maria.png', 1),
('Pedro', '2015-09-09', NULL, 1);

INSERT INTO responsaveis_criancas (usuario_id, crianca_id, tipo_relacao, permissao) VALUES
(1, 1, 'responsavel', 'admin'),
(1, 2, 'responsavel', 'admin');

INSERT INTO pulseiras (crianca_id, identificador, nome_dispositivo, modelo, status, status_conexao, ultima_comunicacao_em, bateria_percentual, ativo) VALUES
(1, 'PULSEIRA-001', 'Pulseira Maria', 'Aster X1', 'ativa', 'conectada', NOW(), 85, 1),
(2, 'PULSEIRA-002', 'Pulseira Pedro', 'Aster X1', 'ativa', 'desconectada', NOW(), 45, 1);

INSERT INTO locais_seguros (crianca_id, nome, latitude, longitude, raio_metros, ativo) VALUES
(1, 'Casa', -23.5505, -46.6333, 150, 1),
(1, 'Escola', -23.5637, -46.6527, 200, 1),
(2, 'Casa da Vó', -23.5488, -46.6199, 120, 1);

INSERT INTO configuracoes_alertas (crianca_id, usuario_id, alerta_saida_local, alerta_entrada_local, alerta_desconexao, alerta_bateria_baixa, limite_bateria_percentual) VALUES
(1, 1, 1, 1, 1, 1, 20),
(2, 1, 1, 1, 1, 1, 20);
