CREATE TABLE `perfis` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nome` varchar(40) UNIQUE NOT NULL,
  `descricao` varchar(200),
  `ativo` boolean NOT NULL DEFAULT true,
  `criado_em` timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE `usuarios` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `email` varchar(150) UNIQUE NOT NULL,
  `perfil_id` int NOT NULL,
  `ativo` boolean NOT NULL DEFAULT true,
  `criado_em` timestamp NOT NULL DEFAULT (now()),
  `atualizado_em` timestamp
);

CREATE TABLE `contas_financeiras` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nome` varchar(100) UNIQUE NOT NULL,
  `tipo_conta` varchar(40) NOT NULL COMMENT 'Ex.: CAIXA, CONTA_CORRENTE, POUPANCA, APLICACAO',
  `saldo_inicial` decimal(14,2) NOT NULL DEFAULT 0,
  `data_saldo_inicial` date NOT NULL,
  `ativo` boolean NOT NULL DEFAULT true,
  `criado_em` timestamp NOT NULL DEFAULT (now()),
  `atualizado_em` timestamp
);

CREATE TABLE `categorias_financeiras` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `tipo` ENUM ('RECEITA', 'DESPESA') NOT NULL,
  `descricao` varchar(250),
  `ativo` boolean NOT NULL DEFAULT true,
  `criado_em` timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE `centros_custo` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `codigo` varchar(20) UNIQUE,
  `nome` varchar(100) UNIQUE NOT NULL,
  `descricao` varchar(250),
  `ativo` boolean NOT NULL DEFAULT true,
  `criado_em` timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE `formas_pagamento` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nome` varchar(50) UNIQUE NOT NULL,
  `descricao` varchar(200),
  `ativo` boolean NOT NULL DEFAULT true
);

CREATE TABLE `periodos_financeiros` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `conta_id` int NOT NULL,
  `data_inicio` date NOT NULL,
  `data_fim` date NOT NULL,
  `status` ENUM ('ABERTO', 'FECHADO') NOT NULL DEFAULT 'ABERTO',
  `fechado_em` timestamp,
  `fechado_por_usuario_id` int,
  `observacao_fechamento` text,
  `criado_em` timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE `receitas_despesas_diretas` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `tipo_operacao` ENUM ('RECEITA', 'DESPESA') NOT NULL,
  `descricao` varchar(160) NOT NULL,
  `data_movimento` date NOT NULL,
  `valor` decimal(14,2) NOT NULL,
  `conta_id` int NOT NULL,
  `categoria_id` int NOT NULL,
  `centro_custo_id` int,
  `forma_pagamento_id` int NOT NULL,
  `periodo_id` int NOT NULL,
  `status` ENUM ('CONSOLIDADO', 'CANCELADO') NOT NULL DEFAULT 'CONSOLIDADO',
  `observacoes` text,
  `criado_em` timestamp NOT NULL DEFAULT (now()),
  `criado_por_usuario_id` int NOT NULL,
  `atualizado_em` timestamp,
  `atualizado_por_usuario_id` int,
  `cancelado_em` timestamp,
  `cancelado_por_usuario_id` int,
  `justificativa_cancelamento` text
);

CREATE TABLE `movimentos_conta_financeira` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `conta_id` int NOT NULL,
  `lancamento_id` int,
  `movimento_original_id` int UNIQUE COMMENT 'Preenchido somente para estorno; aponta para o movimento original estornado',
  `direcao` ENUM ('ENTRADA', 'SAIDA') NOT NULL,
  `origem` ENUM ('LANCAMENTO', 'ESTORNO', 'AJUSTE') NOT NULL DEFAULT 'LANCAMENTO',
  `data_movimento` date NOT NULL,
  `valor` decimal(14,2) NOT NULL,
  `descricao` varchar(200) NOT NULL,
  `chave_idempotencia` varchar(100) UNIQUE NOT NULL,
  `criado_em` timestamp NOT NULL DEFAULT (now()),
  `criado_por_usuario_id` int NOT NULL
);

CREATE TABLE `log_auditoria_financeira` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `lancamento_id` int,
  `movimento_id` int,
  `periodo_id` int,
  `usuario_id` int NOT NULL,
  `acao` ENUM ('INCLUSAO', 'ALTERACAO', 'CANCELAMENTO', 'ESTORNO', 'AJUSTE', 'FECHAMENTO_PERIODO', 'REABERTURA_PERIODO') NOT NULL,
  `justificativa` text,
  `dados_anteriores` json,
  `dados_novos` json,
  `identificador_operacao` varchar(100) NOT NULL,
  `criado_em` timestamp NOT NULL DEFAULT (now())
);

CREATE UNIQUE INDEX `categorias_financeiras_index_0` ON `categorias_financeiras` (`nome`, `tipo`);

CREATE UNIQUE INDEX `periodos_financeiros_index_1` ON `periodos_financeiros` (`conta_id`, `data_inicio`, `data_fim`);

CREATE INDEX `log_auditoria_financeira_index_2` ON `log_auditoria_financeira` (`identificador_operacao`);

CREATE INDEX `log_auditoria_financeira_index_3` ON `log_auditoria_financeira` (`lancamento_id`, `criado_em`);

CREATE INDEX `log_auditoria_financeira_index_4` ON `log_auditoria_financeira` (`usuario_id`, `criado_em`);

ALTER TABLE `usuarios` COMMENT = 'Usuários inativos não podem realizar novas operações. Registros históricos devem ser preservados.';

ALTER TABLE `contas_financeiras` COMMENT = 'O saldo atual deve ser calculated a partir do saldo inicial e dos movimentos; não deve ser editado diretamente.';

ALTER TABLE `categorias_financeiras` COMMENT = 'A categoria deve ter o mesmo tipo do lançamento: RECEITA ou DESPESA.';

ALTER TABLE `periodos_financeiros` COMMENT = 'A aplicação/BD deve impedir data_fim anterior a data_inicio e períodos sobrepostos para a mesma conta.';

ALTER TABLE `receitas_despesas_diretas` COMMENT = 'Não apagar fisicamente. O cancelamento é lógico e exige justificativa.';

ALTER TABLE `movimentos_conta_financeira` COMMENT = 'Livro histórico append-only: não alterar nem excluir movimentos contabilizados.';

ALTER TABLE `log_auditoria_financeira` COMMENT = 'Registro histórico append-only. Não apagar logs em cascata.';

ALTER TABLE `usuarios` ADD FOREIGN KEY (`perfil_id`) REFERENCES `perfis` (`id`) ON DELETE RESTRICT;

ALTER TABLE `periodos_financeiros` ADD FOREIGN KEY (`conta_id`) REFERENCES `contas_financeiras` (`id`) ON DELETE RESTRICT;

ALTER TABLE `periodos_financeiros` ADD FOREIGN KEY (`fechado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`conta_id`) REFERENCES `contas_financeiras` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`categoria_id`) REFERENCES `categorias_financeiras` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`centro_custo_id`) REFERENCES `centros_custo` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`forma_pagamento_id`) REFERENCES `formas_pagamento` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`periodo_id`) REFERENCES `periodos_financeiros` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`atualizado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT;

ALTER TABLE `receitas_despesas_diretas` ADD FOREIGN KEY (`cancelado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT;

ALTER TABLE `movimentos_conta_financeira` ADD FOREIGN KEY (`conta_id`) REFERENCES `contas_financeiras` (`id`) ON DELETE RESTRICT;

ALTER TABLE `movimentos_conta_financeira` ADD FOREIGN KEY (`lancamento_id`) REFERENCES `receitas_despesas_diretas` (`id`) ON DELETE RESTRICT;

ALTER TABLE `movimentos_conta_financeira` ADD FOREIGN KEY (`movimento_original_id`) REFERENCES `movimentos_conta_financeira` (`id`) ON DELETE RESTRICT;

ALTER TABLE `movimentos_conta_financeira` ADD FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT;

ALTER TABLE `log_auditoria_financeira` ADD FOREIGN KEY (`lancamento_id`) REFERENCES `receitas_despesas_diretas` (`id`) ON DELETE RESTRICT;

ALTER TABLE `log_auditoria_financeira` ADD FOREIGN KEY (`movimento_id`) REFERENCES `movimentos_conta_financeira` (`id`) ON DELETE RESTRICT;

ALTER TABLE `log_auditoria_financeira` ADD FOREIGN KEY (`periodo_id`) REFERENCES `periodos_financeiros` (`id`) ON DELETE RESTRICT;

ALTER TABLE `log_auditoria_financeira` ADD FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT;
