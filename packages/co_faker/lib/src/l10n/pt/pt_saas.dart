import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// Brazilian Portuguese (`pt`) SaaS data for `faker.saas`.
///
/// The back office of a clinic software vendor in reais that follows
/// `CoFakerSaasData.english`: every list has the length of the English one, in
/// the same order, and a map has its keys. `pt`, `pt_BR`, and
/// `CoFaker.forLanguage('pt')` read it.
///
/// What makes the data Brazilian and not a translation only:
///
/// - the amounts are reais written `R$ 1.234,56`, the plans cost reais, and
///   the tax of an invoice is the 5% that is the highest rate of the ISS, the
///   municipal tax on services (the municipalities charge from 2% to 5%);
/// - a notification template writes its variables in Portuguese
///   (`#{nome}`, `#{clinica}`), and no variable follows `de`, `do`, `da`,
///   `em`, `no`, or `na`, because the value decides the contraction with the
///   article: the clinic and the date stand after a colon or `para`, which
///   never change;
/// - a title that a name or a service fills (`{target}`, `{service}`) puts the
///   name first and a colon after it, so that it needs no preposition;
/// - a count is written after its label (`Agendamentos realizados: {n}`), which
///   needs no plural to agree;
/// - no Korean-only value appears (`CoKoreanValues.none`): the business number
///   of a tenant has the shape of a CNPJ (`12.345.678/0001-90`), in random
///   digits.
const CoFakerSaasData ptSaas = CoFakerSaasData(
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'Inicial',
      monthlyPrice: 299,
      seats: 3,
      messageCredits: 500,
    ),
    (
      code: 'standard',
      name: 'Padrão',
      monthlyPrice: 599,
      seats: 10,
      messageCredits: 2000,
    ),
    (
      code: 'pro',
      name: 'Profissional',
      monthlyPrice: 1099,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'Empresarial',
      monthlyPrice: 2199,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  // The variables are Portuguese and stand after a colon, a comma, a
  // parenthesis, or `para`, because the template is not filled by the
  // generator: the application that sends it fills them.
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'Agendamento confirmado',
      body:
          'Olá, #{nome}! Seu agendamento está confirmado: #{clinica}, '
          '#{data_hora}.',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'Agendamento cancelado',
      body:
          'Olá, #{nome}! O seu agendamento marcado para #{data_hora} foi '
          'cancelado.',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'Lembrete',
      body: 'Olá, #{nome}! Até amanhã, às #{hora}: #{clinica}.',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: 'Questionário pré-consulta',
      body:
          'Olá, #{nome}! Por favor, preencha o questionário antes da sua '
          'consulta: #{link}',
    ),
    (
      code: 'SURVEY',
      name: 'Pesquisa de satisfação',
      body: 'Olá, #{nome}! Como foi o seu atendimento (#{clinica})? #{link}',
    ),
    (
      code: 'AD_EVENT',
      name: 'Promoção (publicidade)',
      body:
          '[Publicidade] #{clinica}: oferta do mês, 10 sessões de laser em '
          'promoção. Para não receber mais mensagens: #{link}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: 'Manutenção programada',
      body: 'O serviço ficará indisponível das 2h às 4h para manutenção.',
    ),
    (
      category: 'release',
      title: 'Novos recursos lançados',
      body:
          'Agora você pode ver a senha de espera diretamente na tela de '
          'agendamento.',
    ),
    (
      category: 'notice',
      title: 'Atualização de preços',
      body: 'Os novos planos valem a partir da sua próxima data de cobrança.',
    ),
    (
      category: 'notice',
      title: 'Notificações atrasadas',
      body: 'Algumas notificações estão atrasadas e serão enviadas por SMS.',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': 'Número do destinatário inválido',
    'NOT_FRIEND': 'O destinatário não usa o aplicativo de mensagens',
    'TEMPLATE_MISMATCH': 'Modelo incompatível',
    'NO_CREDIT': 'Créditos insuficientes',
    'CARRIER_TIMEOUT': 'Tempo esgotado na operadora',
    'OPTED_OUT': 'O destinatário optou por não receber',
  },
  // A status is written in the masculine, as the word `status` it qualifies
  // is, because the same label serves a subscription and an invoice.
  labels: <String, String>{
    'trialing': 'Em teste',
    'active': 'Ativo',
    'pastDue': 'Pagamento em atraso',
    'paused': 'Pausado',
    'cancelled': 'Cancelado',
    'draft': 'Rascunho',
    'open': 'Em aberto',
    'paid': 'Pago',
    'overdue': 'Vencido',
    'void': 'Anulado',
    'refunded': 'Reembolsado',
    'alimtalk': 'Notificação no aplicativo de mensagens',
    'sms': 'SMS',
    'lms': 'LMS',
    'queued': 'Na fila',
    'sent': 'Enviado',
    'failed': 'Falhou',
    'fallbackSent': 'Enviado por canal alternativo',
    'approved': 'Aprovado',
    'reviewing': 'Em análise',
    'rejected': 'Rejeitado',
    'pending': 'Pendente',
    'eligibility': 'Verificação de elegibilidade',
    'dur': 'Revisão do uso de medicamentos',
    'ePrescription': 'Receita eletrônica',
    'insuranceClaim': 'Guia de cobrança',
    'identityQr': 'QR code de identidade',
    'alimtalkGateway': 'Gateway de mensagens',
    'payment': 'Gateway de pagamento',
    'up': 'Operacional',
    'degraded': 'Degradado',
    'down': 'Interrupção',
    'login': 'Login',
    'loginFailed': 'Falha de login',
    'view': 'Visualização',
    'revealRrn': 'Exibição do número de identificação',
    'create': 'Criação',
    'update': 'Atualização',
    'delete': 'Exclusão',
    'print': 'Impressão',
    'exportData': 'Exportação',
    'send': 'Envio',
    'roleChange': 'Alteração de perfil',
    'notice': 'Aviso',
    'maintenance': 'Manutenção',
    'release': 'Versão',
    'fee': 'Tabela de honorários',
    'drug': 'Preços de medicamentos',
    'material': 'Materiais',
    'diagnosis': 'Diagnósticos',
    'current': 'Vigente',
    'scheduled': 'Programado',
    'archived': 'Arquivado',
    'purchase': 'Compra',
    'usage': 'Uso',
    'refund': 'Reembolso',
    'grant': 'Concessão',
  },
  ops: CoFakerSaasOps(
    // A summary starts with the name it is about, then a colon: no `de` or
    // `do` stands before `{target}`.
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'Aprovar clínica',
        summary: '{target}: cadastro aprovado.',
      ),
      'tenant.suspend': (
        label: 'Suspender clínica',
        summary: '{target}: suspensão por inadimplência.',
      ),
      'tenant.resume': (
        label: 'Reativar clínica',
        summary: '{target}: suspensão removida.',
      ),
      'plan.change': (
        label: 'Alterar plano',
        summary: '{target}: mudança do plano Padrão para o plano Profissional.',
      ),
      'invoice.issue': (
        label: 'Emitir fatura',
        summary: '{target}: fatura mensal emitida.',
      ),
      'invoice.refund': (
        label: 'Reembolsar fatura',
        summary: '{target}: reembolso parcial de uma fatura.',
      ),
      'credit.grant': (
        label: 'Conceder créditos',
        summary: '{target}: 1.000 créditos de mensagens concedidos.',
      ),
      'template.approve': (
        label: 'Aprovar modelo',
        summary: '{target}: modelo aprovado.',
      ),
      'template.reject': (
        label: 'Rejeitar modelo',
        summary: '{target}: modelo publicitário rejeitado.',
      ),
      'senderNumber.approve': (
        label: 'Aprovar número de remetente',
        summary: '{target}: número de remetente aprovado.',
      ),
      'master.publish': (
        label: 'Publicar tabelas de referência de cobrança',
        summary:
            'Novas tabelas de referência de cobrança publicadas ({target}).',
      ),
      'notice.publish': (
        label: 'Publicar aviso',
        summary: 'Aviso “{target}” publicado.',
      ),
      'operator.invite': (
        label: 'Convidar operador',
        summary: '{target}: convite enviado para atuar como operador.',
      ),
      'operator.roleChange': (
        label: 'Alterar perfil do operador',
        summary: '{target}: perfil alterado para administrador.',
      ),
      'impersonate.start': (
        label: 'Acessar como clínica',
        summary:
            '{target}: acesso em nome da clínica para investigar um problema.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'Proprietário',
      'admin': 'Administrador',
      'billing': 'Financeiro',
      'support': 'Suporte',
      'viewer': 'Visualizador',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'Limite do cartão excedido',
      'CARD_EXPIRED': 'Cartão vencido',
      'INSUFFICIENT_FUNDS': 'Saldo insuficiente',
      'CARD_LOST': 'Cartão informado como perdido ou roubado',
      'CARD_SUSPENDED': 'Cartão bloqueado',
      'ISSUER_TIMEOUT': 'Tempo esgotado no banco emissor',
    },
    // Unit prices in reais. A drug row names the drug of the clinic data at the
    // same position of the stems.
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'Primeira consulta', price: 280),
        (name: 'Consulta de retorno', price: 190),
        (name: 'Crioterapia (uma região)', price: 140),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'Quenadil comprimido 10 mg', price: 12),
        (name: 'Tarmovin pomada 15 g', price: 38),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'Gaze estéril (10)', price: 8),
        (name: 'Seringa de 1 ml', price: 2),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'Acne vulgar', price: null),
        (name: 'Verrugas virais', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'Nenhum código duplicado',
      'NEGATIVE_PRICE': 'Nenhum preço zerado ou negativo',
      'EFFECTIVE_DATE': 'Datas de vigência em ordem',
      'REQUIRED_COLUMNS': 'Nenhuma coluna obrigatória ausente',
      'ROW_DELTA': 'Número de linhas dentro de 5% da versão anterior',
      'REMOVED_IN_USE':
          'Os códigos removidos não são usados por guias de cobrança em aberto',
    },
    // The service comes first, then a colon, so that no preposition stands
    // before it.
    incidentTitles: <String, String>{
      'outage': '{service}: interrupção',
      'degraded': '{service}: respostas lentas',
      'maintenance': '{service}: manutenção programada',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message:
            '3 clínicas estão com a sincronização off-line atrasada em mais de 15 minutos.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: '7 faturas falharam na cobrança automática neste mês.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: '5 clínicas têm menos de 100 créditos de mensagens.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'O backup noturno foi concluído.',
      ),
    ],
    releaseItems: <String>[
      'Veja a senha de espera direto na tela de agendamento.',
      'Pagamento dividido e saldo pré-pago em uma única tela.',
      'Notificações com falha são reenviadas por SMS automaticamente.',
      'Mencione colegas com @ nas anotações do prontuário.',
    ],
    regulationItems: <String>[
      'Tabela de honorários revisada aplicada.',
      'Lista de preços de medicamentos atualizada aplicada.',
      'Mapeamento dos códigos de diagnóstico atualizado.',
    ],
    releaseTitle: 'Notas da versão {version} do PEP',
    regulationTitle: 'Atualizações regulatórias de {month}',
    // The count follows its label, so that one or many needs no agreement.
    tenantActivities: <String>[
      'Novos pacientes cadastrados: {n}',
      'Guias de cobrança enviadas: {n}',
      'Notificações enviadas: {n}',
      'Agendamentos realizados: {n}',
      'Contas de funcionários adicionadas: {n}',
    ],
    templateRejectReason:
        'Contém publicidade; envie como mensagem de marketing.',
    labels: <String, String>{
      'active': 'Ativo',
      'invited': 'Convidado',
      'suspended': 'Suspenso',
      'allTenants': 'Todas as clínicas',
      'proAndAbove': 'Planos Profissional e superiores',
      'dermatology': 'Clínicas de dermatologia',
      'inApp': 'No aplicativo',
      'email': 'E-mail',
      'alimtalk': 'Notificação no aplicativo de mensagens',
      'outage': 'Interrupção',
      'degraded': 'Degradado',
      'maintenance': 'Manutenção',
      'info': 'Informação',
      'warning': 'Aviso',
      'critical': 'Crítico',
      'topUp': 'Recarga',
      'usage': 'Uso',
      'refund': 'Reembolso',
      'card': 'Cartão',
      'transfer': 'Transferência bancária',
      'virtualAccount': 'Conta virtual',
      'release': 'Versão',
      'regulation': 'Atualização regulatória',
      'failed': 'Falha no pagamento',
      'added': 'Adicionado',
      'updated': 'Atualizado',
      'removed': 'Removido',
    },
    senderLabels: <String>['Linha principal', 'Agendamentos', 'Recepção'],
    healthMessages: <String, String>{
      'degraded': 'Respostas lentas',
      'down': 'Tempo de conexão esgotado',
    },
    auditTargets: <String, String>{
      'login': 'conta',
      'loginFailed': 'conta',
      'roleChange': 'perfil de funcionário',
      'send': 'notificação',
    },
    auditRecords: <String>['paciente', 'prontuário', 'fatura', 'agendamento'],
    // `{n}` rows may be one, so the noun carries its plural in parentheses.
    masterCheckDetail: '{n} linha(s)',
  ),
  // The real: `R$ 1.234,56`, with a no-break space after the symbol.
  currency: CoCurrencyFormat(
    code: 'BRL',
    symbol: r'R$',
    pattern: '{symbol} {amount}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // The tax of an invoice is the ISS, 5% at most. The prepaid wallet of message
  // credits is topped up in reais, from a hundred to five thousand, and a
  // top-up from R$ 250 earns a bonus of five to fifteen percent.
  priceScale: CoSaasPriceScale(
    vatRate: 0.05,
    prepaidTopUps: <int>[100, 250, 500, 1000, 2500, 5000],
    prepaidBonusTiers: <(int, int)>[(250, 5), (500, 8), (1000, 10), (2500, 15)],
    prepaidLowBalance: 250,
    prepaidUsageMin: 10,
    prepaidUsageRounding: 5,
    prepaidRefundMin: 10,
    prepaidRefundRounding: 5,
  ),
  koreanValues: CoKoreanValues.none,
  // The shape of a CNPJ: eight digits, the branch, and two check digits.
  businessNumberFormat: '##.###.###/####-##',
);
