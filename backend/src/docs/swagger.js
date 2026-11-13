const { PORT } = require('../config/env');

const idParam = (name = 'id', description = 'Identificador do recurso') => ({
  name,
  in: 'path',
  required: true,
  description,
  schema: { type: 'integer', example: 1 },
});

const jsonBody = (schemaRef, required = true) => ({
  required,
  content: { 'application/json': { schema: { $ref: `#/components/schemas/${schemaRef}` } } },
});

const ok = (description, dataSchema) => ({
  description,
  content: {
    'application/json': {
      schema: dataSchema
        ? {
          type: 'object',
          properties: { success: { type: 'boolean', example: true }, data: dataSchema },
        }
        : { $ref: '#/components/schemas/MessageResponse' },
    },
  },
});

const ref = (name) => ({ $ref: `#/components/schemas/${name}` });
const arrayOf = (name) => ({ type: 'array', items: ref(name) });
const errorResponse = (description) => ({
  description,
  content: { 'application/json': { schema: ref('ErrorResponse') } },
});

const responses = {
  400: errorResponse('Dados inválidos'),
  401: errorResponse('Token ausente, expirado ou inválido'),
  403: errorResponse('Sem permissão para acessar o recurso'),
  404: errorResponse('Recurso não encontrado'),
  409: errorResponse('Conflito (registro já existe)'),
};

const swaggerSpec = {
  openapi: '3.0.3',
  info: {
    title: 'ZELOOS - API da Pulseira Localizadora',
    version: '1.0.0',
    description: 'API REST do sistema de pulseira localizadora infantil. '
      + 'Para acessar as rotas protegidas, faça login em **POST /api/auth/login**, copie o `token` '
      + 'e clique em **Authorize** informando apenas o valor do token.',
  },
  servers: [{ url: `http://localhost:${PORT}`, description: 'Servidor local' }],
  tags: [
    { name: 'Health', description: 'Status da API' },
    { name: 'Auth', description: 'Cadastro, login e perfil do responsável' },
    { name: 'Crianças', description: 'Perfis das crianças e seus responsáveis' },
    { name: 'Pulseiras', description: 'Dispositivos e localização' },
    { name: 'Locais seguros', description: 'Áreas seguras (cercas virtuais)' },
    { name: 'Alertas', description: 'Alertas de entrada/saída de locais seguros' },
    { name: 'Configurações', description: 'Preferências de alertas por criança' },
  ],
  components: {
    securitySchemes: {
      bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
    },
    schemas: {
      ErrorResponse: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          message: { type: 'string', example: 'Dados inválidos.' },
          errors: {
            type: 'array',
            items: {
              type: 'object',
              properties: { field: { type: 'string' }, message: { type: 'string' } },
            },
          },
        },
      },
      MessageResponse: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: true },
          message: { type: 'string', example: 'Operação realizada com sucesso.' },
        },
      },
      Usuario: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          nome: { type: 'string', example: 'Responsável Demo' },
          email: { type: 'string', format: 'email', example: 'responsavel@demo.com' },
          telefone: { type: 'string', nullable: true, example: '(11) 98765-4321' },
          ativo: { type: 'boolean', example: true },
        },
      },
      RegisterRequest: {
        type: 'object',
        required: ['nome', 'email', 'senha'],
        properties: {
          nome: { type: 'string', minLength: 2, example: 'Responsável Demo' },
          email: { type: 'string', format: 'email', example: 'responsavel@demo.com' },
          senha: { type: 'string', minLength: 6, example: '123456' },
          telefone: { type: 'string', nullable: true, example: '(11) 98765-4321' },
        },
      },
      LoginRequest: {
        type: 'object',
        required: ['email', 'senha'],
        properties: {
          email: { type: 'string', format: 'email', example: 'responsavel@demo.com' },
          senha: { type: 'string', example: '123456' },
        },
      },
      UpdateProfileRequest: {
        type: 'object',
        required: ['nome'],
        properties: {
          nome: { type: 'string', minLength: 2, example: 'Novo Nome' },
          telefone: { type: 'string', nullable: true, example: '(11) 98765-4321' },
        },
      },
      AuthResponse: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: true },
          token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' },
          user: ref('Usuario'),
        },
      },
      Crianca: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          nome: { type: 'string', example: 'Ana' },
          data_nascimento: { type: 'string', format: 'date', nullable: true, example: '2018-05-10' },
          foto_url: { type: 'string', nullable: true, example: null },
        },
      },
      CriancaInput: {
        type: 'object',
        required: ['nome'],
        properties: {
          nome: { type: 'string', example: 'Ana' },
          data_nascimento: { type: 'string', format: 'date', nullable: true, example: '2018-05-10' },
          foto_url: { type: 'string', nullable: true, example: null },
        },
      },
      Responsavel: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          usuario_id: { type: 'integer', example: 2 },
          nome: { type: 'string', example: 'Maria' },
          email: { type: 'string', example: 'maria@demo.com' },
          permissao: { type: 'string', example: 'admin' },
        },
      },
      ResponsavelInput: {
        type: 'object',
        required: ['usuario_id'],
        properties: {
          usuario_id: { type: 'integer', example: 2 },
          tipo_relacao: { type: 'string', example: 'responsavel' },
          permissao: { type: 'string', example: 'admin' },
        },
      },
      Pulseira: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          crianca_id: { type: 'integer', example: 1 },
          identificador: { type: 'string', example: 'BRACELET-001' },
          nome_dispositivo: { type: 'string', nullable: true, example: 'Pulseira da Ana' },
          modelo: { type: 'string', nullable: true, example: 'ZL-01' },
          status: { type: 'string', example: 'ativa' },
          status_conexao: { type: 'string', example: 'conectada' },
          bateria_percentual: { type: 'integer', nullable: true, example: 82 },
          ultima_comunicacao_em: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      PulseiraInput: {
        type: 'object',
        required: ['crianca_id', 'identificador'],
        properties: {
          crianca_id: { type: 'integer', example: 1 },
          identificador: { type: 'string', example: 'BRACELET-001' },
          nome_dispositivo: { type: 'string', example: 'Pulseira da Ana' },
          modelo: { type: 'string', example: 'ZL-01' },
        },
      },
      PulseiraUpdate: {
        type: 'object',
        description: 'Somente estes campos podem ser alterados; qualquer outro retorna 400.',
        properties: {
          crianca_id: { type: 'integer', example: 1 },
          identificador: { type: 'string', example: 'BRACELET-001' },
          nome_dispositivo: { type: 'string', example: 'Pulseira da Ana' },
          modelo: { type: 'string', example: 'ZL-01' },
          status: { type: 'string', example: 'ativa' },
        },
      },
      Localizacao: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 10 },
          pulseira_id: { type: 'integer', example: 1 },
          latitude: { type: 'number', example: -23.55052 },
          longitude: { type: 'number', example: -46.63331 },
          precisao_metros: { type: 'number', nullable: true, example: 5 },
          bateria_percentual: { type: 'integer', nullable: true, example: 82 },
          origem: { type: 'string', example: 'dispositivo' },
          registrada_em: { type: 'string', format: 'date-time' },
        },
      },
      LocalizacaoInput: {
        type: 'object',
        required: ['identificador', 'latitude', 'longitude'],
        properties: {
          identificador: { type: 'string', example: 'BRACELET-001' },
          latitude: { type: 'number', minimum: -90, maximum: 90, example: -23.55052 },
          longitude: { type: 'number', minimum: -180, maximum: 180, example: -46.63331 },
          precisao_metros: { type: 'number', example: 5 },
          bateria_percentual: { type: 'integer', example: 82 },
          origem: { type: 'string', example: 'dispositivo', description: 'Use "simulado" para dados de demonstração' },
        },
      },
      LocalSeguro: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          crianca_id: { type: 'integer', example: 1 },
          nome: { type: 'string', example: 'Escola' },
          latitude: { type: 'number', example: -23.55052 },
          longitude: { type: 'number', example: -46.63331 },
          raio_metros: { type: 'number', example: 150 },
        },
      },
      LocalSeguroInput: {
        type: 'object',
        required: ['nome', 'latitude', 'longitude', 'raio_metros'],
        properties: {
          nome: { type: 'string', example: 'Escola' },
          latitude: { type: 'number', example: -23.55052 },
          longitude: { type: 'number', example: -46.63331 },
          raio_metros: { type: 'number', example: 150 },
        },
      },
      Alerta: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          crianca_id: { type: 'integer', example: 1 },
          pulseira_id: { type: 'integer', nullable: true, example: 1 },
          local_seguro_id: { type: 'integer', nullable: true, example: 1 },
          tipo: { type: 'string', enum: ['entrada_local', 'saida_local'], example: 'saida_local' },
          titulo: { type: 'string', example: 'Saída de local seguro' },
          mensagem: { type: 'string', example: 'A criança saiu de Escola.' },
          status: { type: 'string', example: 'novo' },
          ocorrido_em: { type: 'string', format: 'date-time' },
        },
      },
      ConfiguracaoAlerta: {
        type: 'object',
        properties: {
          alerta_saida_local: { type: 'boolean', example: true },
          alerta_entrada_local: { type: 'boolean', example: true },
          alerta_desconexao: { type: 'boolean', example: true },
          alerta_bateria_baixa: { type: 'boolean', example: true },
          limite_bateria_percentual: { type: 'integer', example: 20 },
        },
      },
    },
  },
  security: [{ bearerAuth: [] }],
  paths: {
    '/api/health': {
      get: {
        tags: ['Health'],
        summary: 'Verifica se a API e o banco de dados estão disponíveis',
        security: [],
        responses: {
          200: { description: 'API e banco operacionais' },
          503: { description: 'Banco de dados indisponível' },
        },
      },
    },
    '/api/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Cadastra um novo responsável',
        security: [],
        requestBody: jsonBody('RegisterRequest'),
        responses: {
          201: { description: 'Usuário criado', content: { 'application/json': { schema: ref('AuthResponse') } } },
          400: responses[400],
          409: responses[409],
        },
      },
    },
    '/api/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Autentica o responsável e retorna o token JWT',
        security: [],
        requestBody: jsonBody('LoginRequest'),
        responses: {
          200: { description: 'Login realizado', content: { 'application/json': { schema: ref('AuthResponse') } } },
          400: responses[400],
          401: errorResponse('Credenciais inválidas'),
        },
      },
    },
    '/api/auth/me': {
      get: {
        tags: ['Auth'],
        summary: 'Retorna os dados do usuário logado',
        responses: {
          200: { description: 'Usuário logado', content: { 'application/json': { schema: { type: 'object', properties: { success: { type: 'boolean' }, user: ref('Usuario') } } } } },
          401: responses[401],
          404: responses[404],
        },
      },
      put: {
        tags: ['Auth'],
        summary: 'Atualiza nome e telefone do usuário logado',
        requestBody: jsonBody('UpdateProfileRequest'),
        responses: {
          200: { description: 'Perfil atualizado', content: { 'application/json': { schema: { type: 'object', properties: { success: { type: 'boolean' }, user: ref('Usuario') } } } } },
          400: responses[400],
          401: responses[401],
          404: responses[404],
        },
      },
    },
    '/api/criancas': {
      get: {
        tags: ['Crianças'],
        summary: 'Lista as crianças vinculadas ao usuário',
        responses: { 200: ok('Lista de crianças', arrayOf('Crianca')), 401: responses[401] },
      },
      post: {
        tags: ['Crianças'],
        summary: 'Cadastra uma criança e vincula ao usuário logado',
        requestBody: jsonBody('CriancaInput'),
        responses: { 201: ok('Criança criada', ref('Crianca')), 401: responses[401] },
      },
    },
    '/api/criancas/{id}': {
      parameters: [idParam('id', 'ID da criança')],
      get: {
        tags: ['Crianças'],
        summary: 'Obtém uma criança com seus responsáveis',
        responses: {
          200: ok('Criança encontrada', {
            allOf: [ref('Crianca'), { type: 'object', properties: { responsaveis: arrayOf('Responsavel') } }],
          }),
          401: responses[401],
          404: responses[404],
        },
      },
      put: {
        tags: ['Crianças'],
        summary: 'Atualiza os dados de uma criança',
        requestBody: jsonBody('CriancaInput'),
        responses: { 200: ok('Criança atualizada', ref('Crianca')), 401: responses[401], 404: responses[404] },
      },
      delete: {
        tags: ['Crianças'],
        summary: 'Remove uma criança',
        responses: { 200: ok('Criança removida'), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/criancas/{id}/responsaveis': {
      parameters: [idParam('id', 'ID da criança')],
      get: {
        tags: ['Crianças'],
        summary: 'Lista os responsáveis da criança',
        responses: { 200: ok('Lista de responsáveis', arrayOf('Responsavel')), 401: responses[401] },
      },
      post: {
        tags: ['Crianças'],
        summary: 'Vincula um responsável à criança',
        requestBody: jsonBody('ResponsavelInput'),
        responses: { 201: ok('Responsável vinculado', { type: 'object' }), 401: responses[401] },
      },
    },
    '/api/criancas/{id}/responsaveis/{usuarioId}': {
      parameters: [idParam('id', 'ID da criança'), idParam('usuarioId', 'ID do usuário responsável')],
      delete: {
        tags: ['Crianças'],
        summary: 'Remove o vínculo de um responsável',
        responses: { 200: ok('Vínculo removido'), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/criancas/{id}/locais-seguros': {
      parameters: [idParam('id', 'ID da criança')],
      get: {
        tags: ['Locais seguros'],
        summary: 'Lista os locais seguros da criança',
        responses: { 200: ok('Lista de locais seguros', arrayOf('LocalSeguro')), 401: responses[401] },
      },
      post: {
        tags: ['Locais seguros'],
        summary: 'Cadastra um local seguro para a criança',
        requestBody: jsonBody('LocalSeguroInput'),
        responses: { 201: ok('Local seguro criado', ref('LocalSeguro')), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/locais-seguros/{id}': {
      parameters: [idParam('id', 'ID do local seguro')],
      put: {
        tags: ['Locais seguros'],
        summary: 'Atualiza um local seguro',
        requestBody: jsonBody('LocalSeguroInput'),
        responses: { 200: ok('Local seguro atualizado', ref('LocalSeguro')), 401: responses[401], 404: responses[404] },
      },
      delete: {
        tags: ['Locais seguros'],
        summary: 'Remove um local seguro',
        responses: { 200: ok('Local seguro removido'), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/pulseiras': {
      get: {
        tags: ['Pulseiras'],
        summary: 'Lista as pulseiras das crianças do usuário',
        responses: { 200: ok('Lista de pulseiras', arrayOf('Pulseira')), 401: responses[401] },
      },
      post: {
        tags: ['Pulseiras'],
        summary: 'Cadastra uma pulseira para uma criança do usuário',
        requestBody: jsonBody('PulseiraInput'),
        responses: {
          201: ok('Pulseira criada', ref('Pulseira')),
          401: responses[401],
          403: responses[403],
          404: responses[404],
        },
      },
    },
    '/api/pulseiras/receber-localizacao': {
      post: {
        tags: ['Pulseiras'],
        summary: 'Recebe uma localização enviada pelo dispositivo',
        description: 'Endpoint público usado pela pulseira. Gera alertas de entrada/saída de locais seguros.',
        security: [],
        requestBody: jsonBody('LocalizacaoInput'),
        responses: {
          201: ok('Localização registrada', {
            type: 'object',
            properties: {
              localizacao: ref('Localizacao'),
              pulseira: ref('Pulseira'),
              entrouEmLocal: { allOf: [ref('LocalSeguro')], nullable: true },
              saiuDeLocal: { allOf: [ref('LocalSeguro')], nullable: true },
            },
          }),
          400: errorResponse('Coordenadas fora do limite válido'),
          404: responses[404],
        },
      },
    },
    '/api/pulseiras/{id}': {
      parameters: [idParam('id', 'ID da pulseira')],
      get: {
        tags: ['Pulseiras'],
        summary: 'Obtém uma pulseira do usuário',
        responses: { 200: ok('Pulseira encontrada', ref('Pulseira')), 401: responses[401], 404: responses[404] },
      },
      put: {
        tags: ['Pulseiras'],
        summary: 'Atualiza os dados editáveis da pulseira',
        requestBody: jsonBody('PulseiraUpdate'),
        responses: {
          200: ok('Pulseira atualizada', ref('Pulseira')),
          400: responses[400],
          401: responses[401],
          403: responses[403],
          404: responses[404],
        },
      },
      delete: {
        tags: ['Pulseiras'],
        summary: 'Desativa uma pulseira',
        responses: { 200: ok('Pulseira removida'), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/pulseiras/{id}/localizacao-atual': {
      parameters: [idParam('id', 'ID da pulseira')],
      get: {
        tags: ['Pulseiras'],
        summary: 'Última localização e local seguro em que a criança está',
        responses: {
          200: ok('Localização atual', {
            type: 'object',
            properties: {
              pulseira: ref('Pulseira'),
              localizacao: { allOf: [ref('Localizacao')], nullable: true },
              dentro: { allOf: [ref('LocalSeguro')], nullable: true },
              locaisSeguros: arrayOf('LocalSeguro'),
            },
          }),
          401: responses[401],
          404: responses[404],
        },
      },
    },
    '/api/pulseiras/{id}/historico': {
      parameters: [
        idParam('id', 'ID da pulseira'),
        { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
        { name: 'offset', in: 'query', schema: { type: 'integer', default: 0 } },
      ],
      get: {
        tags: ['Pulseiras'],
        summary: 'Histórico paginado de localizações',
        responses: {
          200: {
            description: 'Histórico de localizações',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean' },
                    data: arrayOf('Localizacao'),
                    pagination: { type: 'object', properties: { limit: { type: 'integer' }, offset: { type: 'integer' } } },
                  },
                },
              },
            },
          },
          401: responses[401],
          404: responses[404],
        },
      },
    },
    '/api/alertas': {
      get: {
        tags: ['Alertas'],
        summary: 'Lista os alertas das crianças do usuário',
        responses: { 200: ok('Lista de alertas', arrayOf('Alerta')), 401: responses[401] },
      },
    },
    '/api/alertas/{id}': {
      parameters: [idParam('id', 'ID do alerta')],
      get: {
        tags: ['Alertas'],
        summary: 'Obtém um alerta',
        responses: { 200: ok('Alerta encontrado', ref('Alerta')), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/alertas/{id}/visualizar': {
      parameters: [idParam('id', 'ID do alerta')],
      patch: {
        tags: ['Alertas'],
        summary: 'Marca o alerta como visualizado',
        responses: { 200: ok('Alerta visualizado'), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/alertas/{id}/resolver': {
      parameters: [idParam('id', 'ID do alerta')],
      patch: {
        tags: ['Alertas'],
        summary: 'Marca o alerta como resolvido',
        responses: { 200: ok('Alerta resolvido'), 401: responses[401], 404: responses[404] },
      },
    },
    '/api/configuracoes/{criancaId}': {
      parameters: [idParam('criancaId', 'ID da criança')],
      get: {
        tags: ['Configurações'],
        summary: 'Obtém a configuração de alertas da criança para o usuário',
        responses: { 200: ok('Configuração (ou null)', { allOf: [ref('ConfiguracaoAlerta')], nullable: true }), 401: responses[401] },
      },
      put: {
        tags: ['Configurações'],
        summary: 'Cria ou atualiza a configuração de alertas',
        requestBody: jsonBody('ConfiguracaoAlerta'),
        responses: { 200: ok('Configuração salva', ref('ConfiguracaoAlerta')), 401: responses[401] },
      },
    },
  },
};

module.exports = swaggerSpec;
