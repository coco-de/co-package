import '../../clinic_data.dart';
import '../../clinic_ops.dart';
import '../../clinic_texts.dart';
import '../../currency_format.dart';
import '../../korean_values.dart';

/// Brazilian Portuguese (`pt`) clinic data for `faker.clinic`.
///
/// A general dermatology and aesthetic clinic in reais that follows
/// `CoFakerClinicData.english`: every list has the length of the English one,
/// in the same order, so that one seed picks the same record in both
/// languages. `pt`, `pt_BR`, and `CoFaker.forLanguage('pt')` read it.
///
/// What makes the data Brazilian and not a translation only:
///
/// - the amounts are reais written `R$ 1.234,56`: a no-break space after the
///   symbol, a dot between thousands, and a comma before the centavos. The
///   price bands and the price scale are in reais, at three to five times the
///   dollar prices of the English data, and the units are those of a Brazilian
///   price tag (R$ 10 for a price, R$ 50 for a package);
/// - a clinic name is the kind of place first and the name after it
///   (`Clínica de Pediatria Ipê`), and a date is `quinta-feira (8/10)`;
/// - the patient is addressed with `você`, and a text that a value fills never
///   puts a preposition that contracts with the article (`de` + `a` = `da`,
///   `em` + `o` = `no`) before the value, because the gender of the value
///   decides it: the value comes after a colon, in parentheses, or after `por`
///   or `para`;
/// - the insurance is a health plan (`Plano de saúde`) or a private patient
///   (`Particular`), and no institution of Brazil is named;
/// - no value of the Korean data appears (`CoKoreanValues.none`): the ID is
///   masked in the shape of a CPF (`***.123.456-**`), the phones and addresses
///   are those of Brazil, and a closure notice gives a reason.
const CoFakerClinicData ptClinic = CoFakerClinicData(
  specialties: <CoSpecialtySpec>[
    (name: 'Dermatologia', clinicSuffix: 'Clínica de Dermatologia'),
    (name: 'Cirurgia Plástica', clinicSuffix: 'Clínica de Cirurgia Plástica'),
    (
      name: 'Medicina de Família e Comunidade',
      clinicSuffix: 'Clínica de Medicina de Família',
    ),
    // Brazil calls internal medicine `Clínica Médica`.
    (name: 'Clínica Médica', clinicSuffix: 'Clínica Médica'),
    (name: 'Pediatria', clinicSuffix: 'Clínica de Pediatria'),
  ],
  // They follow the kind of place: `Clínica de Pediatria Ipê`, or
  // `Clínica Médica de Demonstração`.
  clinicNamePrefixes: <String>[
    'Vista Clara',
    'Boa Luz',
    'Ipê',
    'Margem Serena',
    'Sempre Verde',
    'Modelo',
    'de Demonstração',
    'Portal do Norte',
  ],
  // A title that has both genders is written with `(a)`, as a form does.
  staffRoles: <String, String>{
    'director': 'Diretor(a) clínico(a)',
    'doctor': 'Médico(a)',
    'counselor': 'Orientador(a) de pacientes',
    'coordinator': 'Coordenador(a) de cuidados',
    'nurse': 'Enfermeiro(a)',
    'nurseAide': 'Auxiliar de enfermagem',
    'skincare': 'Esteticista',
    'desk': 'Recepção',
  },
  visitPurposes: <CoVisitPurposeSpec>[
    (
      name: 'Consulta',
      details: <String>['Primeira consulta', 'Consulta de retorno'],
    ),
    (name: 'Procedimento', details: <String>['Injetáveis', 'Laser', 'Lifting']),
    (
      name: 'Tratamento',
      details: <String>['Acne', 'Doença de pele', 'Verrugas'],
    ),
    (name: 'Cuidado', details: <String>['Cuidado facial', 'Cuidado calmante']),
  ],
  // Prices are reais, the English bands at three to five times and rounded to
  // a price a clinic would put on a tag.
  procedures: <CoProcedureSpec>[
    (
      code: 'CONS01',
      category: 'Consulta/Honorários',
      name: 'Primeira consulta',
      unit: 'consulta',
      minPrice: 400,
      maxPrice: 900,
      taxable: false,
    ),
    (
      code: 'BTX-F',
      category: 'Toxina botulínica/Rugas',
      name: 'Toxina botulínica na testa',
      unit: 'região',
      minPrice: 700,
      maxPrice: 2000,
      taxable: true,
    ),
    (
      code: 'FIL-L',
      category: 'Preenchimento/Região',
      name: 'Preenchimento labial com ácido hialurônico, 1\u00A0ml',
      unit: 'ml',
      minPrice: 1800,
      maxPrice: 3500,
      taxable: true,
    ),
    (
      code: 'LT-01',
      category: 'Laser/Uniformização do tom',
      name: 'Laser de picossegundos para uniformização do tom',
      unit: 'sessão',
      minPrice: 900,
      maxPrice: 2200,
      taxable: true,
    ),
    (
      code: 'HIFU-300',
      category: 'Lifting/Ultrassom',
      name: 'Lifting por ultrassom focado, 300 linhas',
      unit: 'sessão',
      minPrice: 4000,
      maxPrice: 12000,
      taxable: true,
    ),
    (
      code: 'ACN-01',
      category: 'Acne/Tratamento',
      name: 'Extração de comedões',
      unit: 'sessão',
      minPrice: 250,
      maxPrice: 650,
      taxable: false,
    ),
    (
      code: 'CARE-01',
      category: 'Cuidado/Calmante',
      name: 'Cuidado facial calmante com LED',
      unit: 'sessão',
      minPrice: 250,
      maxPrice: 600,
      taxable: true,
    ),
    (
      code: 'DOC-01',
      category: 'Documentos',
      name: 'Atestado médico',
      unit: 'via',
      minPrice: 50,
      maxPrice: 150,
      taxable: false,
    ),
  ],
  // The codes and the English names are the ones of the English data; the
  // Portuguese names are those of the Brazilian version of ICD-10.
  diagnoses: <CoDiagnosisSpec>[
    (code: 'L70.0', name: 'Acne vulgar', nameEn: 'Acne vulgaris'),
    (code: 'L81.1', name: 'Cloasma', nameEn: 'Chloasma'),
    (code: 'B07', name: 'Verrugas virais', nameEn: 'Viral warts'),
    (
      code: 'L20.9',
      name: 'Dermatite atópica, não especificada',
      nameEn: 'Atopic dermatitis, unspecified',
    ),
    (
      code: 'L30.9',
      name: 'Dermatite, não especificada',
      nameEn: 'Dermatitis, unspecified',
    ),
    (
      code: 'L71.9',
      name: 'Rosácea, não especificada',
      nameEn: 'Rosacea, unspecified',
    ),
  ],
  // Invented names that no marketed product has: none of them was found as a
  // medicine, a brand, or a company when it was searched for.
  drugStems: <String>[
    'Brolivex',
    'Quenadil',
    'Tarmovin',
    'Selquira',
    'Pimorel',
    'Corvelin',
    'Olvetrix',
    'Avelmora',
  ],
  // A drug reads `Brolivex comprimido 10 mg`: the form has its leading space
  // and the unit a no-break one.
  drugForms: <({String form, String unit, List<int> strengths})>[
    (form: ' comprimido', unit: '\u00A0mg', strengths: <int>[5, 10, 20, 50]),
    (form: ' cápsula', unit: '\u00A0mg', strengths: <int>[25, 50, 100]),
    (form: ' pomada', unit: '\u00A0g', strengths: <int>[15, 30]),
    (form: ' creme', unit: '\u00A0g', strengths: <int>[15, 30]),
  ],
  drugUsages: <String>[
    'Uma vez ao dia, ao deitar',
    'Duas vezes ao dia, após as refeições',
    'Aplicar uma camada fina duas vezes ao dia',
    'Aplicar uma vez ao dia após a limpeza',
  ],
  complaints: <String>[
    'Relata manchas mais escuras nas duas bochechas',
    'Acne recorrente ao longo da linha da mandíbula',
    'Preocupação com as linhas de expressão da testa',
    'Deseja melhorar a flacidez da pele',
    'Vermelhidão que persiste após um procedimento',
  ],
  findings: <String>[
    'Máculas acastanhadas mal delimitadas nas duas regiões malares',
    'Múltiplas pápulas inflamatórias no queixo',
    'Rugas dinâmicas da testa, grau 2',
    'Flacidez moderada no terço inferior da face',
    'Eritema leve, sem edema',
  ],
  plans: <String>[
    'Sessão de laser a cada duas semanas',
    'Extração e terapia tópica',
    'Reavaliação duas semanas após a aplicação',
    'Orientação sobre proteção solar, retorno em quatro semanas',
    'Observar; retornar em caso de piora',
  ],
  memos: <String>[
    'Orientação: não usar maquiagem por 24 horas.',
    'Anestésico tópico aplicado 30 minutos antes do procedimento.',
    'Fotos de antes realizadas.',
    'Valores do pacote explicados; a decisão ficará para depois.',
    'Retorno agendado para daqui a duas semanas.',
  ],
  questions: <CoQuestionSpec>[
    (
      question: 'Você tem alguma alergia a medicamentos?',
      options: <String>['Nenhuma', 'Lidocaína', 'Penicilina', 'Não sei'],
    ),
    (
      question: 'Você está tomando algum medicamento?',
      options: <String>[
        'Nenhum',
        'Anticoagulantes',
        'Medicamento para acne',
        'Outro',
      ],
    ),
    (
      question: 'Você está grávida ou amamentando?',
      options: <String>['Não', 'Grávida', 'Amamentando', 'Não se aplica'],
    ),
    (
      question: 'O que você mais gostaria de melhorar?',
      options: <String>['Pigmentação', 'Acne', 'Rugas', 'Firmeza'],
    ),
  ],
  // Card networks, with the Brazilian domestic one in place of the fourth.
  cardIssuers: <String>['Visa', 'Mastercard', 'Amex', 'Elo'],
  // A status is written in the masculine, as the words `agendamento` and
  // `atendimento` it qualifies are, or as a verb (`Chegou`, `Faltou`).
  labels: <String, String>{
    'nhis': 'Plano de saúde',
    'medicalAid1': 'Assistência pública (tipo 1)',
    'medicalAid2': 'Assistência pública (tipo 2)',
    'uninsured': 'Particular',
    'reception': 'Recepção',
    'waiting': 'Em espera',
    'consultation': 'Consulta',
    'counseling': 'Orientação',
    'procedure': 'Procedimento',
    'care': 'Cuidado',
    'payment': 'Pagamento',
    'done': 'Finalizado',
    'requested': 'Solicitado',
    'reserved': 'Agendado',
    'confirmed': 'Confirmado',
    'checkedIn': 'Chegou',
    'completed': 'Concluído',
    'cancelled': 'Cancelado',
    'noShow': 'Faltou',
    'rejected': 'Recusado',
    'card': 'Cartão',
    'cash': 'Dinheiro',
    'transfer': 'Transferência bancária',
    'prepaid': 'Saldo pré-pago',
    'package': 'Pacote',
    'female': 'Feminino',
    'male': 'Masculino',
  },
  // A package has 3, 5, or 10 sessions, so the word is always plural.
  packageNameFormat: '{name} · {sessions} sessões',
  texts: CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'Termo de consentimento para procedimento',
        clauses: <String>[
          'Fui informado(a) sobre a finalidade, o método e o efeito esperado do procedimento.',
          'Entendo que podem ocorrer vermelhidão, inchaço ou hematomas.',
          'Entendo que os resultados variam e não são garantidos.',
          'Informei meus medicamentos, minhas alergias e a possibilidade de gravidez.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'Consentimento para tratamento de dados pessoais',
        clauses: <String>[
          'Dados coletados: nome, data de nascimento, dados de contato e prontuário.',
          'Finalidade: atendimento, lembretes de agendamento e cobrança.',
          'Posso recusar, mas o agendamento on-line pode ficar indisponível.',
        ],
      ),
      (
        kind: 'photo',
        title: 'Consentimento para fotografias',
        clauses: <String>[
          'Fotos de antes e depois são feitas para acompanhar a evolução.',
          'As fotos são usadas apenas no tratamento e nunca são divulgadas.',
        ],
      ),
    ],
    consentDisclaimer:
        'Texto de exemplo apenas para demonstrações. Sem revisão jurídica; '
        'não use como termo de consentimento real.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'Explicaram tudo com muito cuidado.',
        'Pouca espera e uma equipe simpática.',
        'O tom da minha pele melhorou depois de três sessões.',
      ],
      'neutral': <String>[
        'Bons resultados, mas um pouco caro.',
        'O estacionamento era pouco prático.',
      ],
      'negative': <String>[
        'Esperei mais de 40 minutos além do horário agendado.',
        'O valor final foi diferente do orçamento.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'laser de picossegundos',
        concern: 'As manchas escuras nas minhas bochechas estão piorando.',
        recommend: 'Para a pigmentação, recomendo o laser de picossegundos.',
        pain:
            'Dá uma leve ardência; a maioria das pessoas não precisa de anestesia.',
        interval: 'Cerca de dez sessões, com intervalo de duas semanas.',
        downtime:
            'Um pouco de vermelhidão por algumas horas; você pode lavar o rosto no mesmo dia.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'lifting por ultrassom focado',
        concern: 'Sinto a linha da mandíbula flácida.',
        recommend:
            'O lifting por ultrassom focado firma as camadas mais profundas.',
        pain:
            'Pode doer perto do osso, por isso aplicamos um creme anestésico.',
        interval: 'Uma vez a cada seis a doze meses.',
        downtime: 'Você pode voltar ao trabalho logo em seguida.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'Olá, em que posso ajudar hoje?',
      questions: <String, String>{
        'pain': 'Dói?',
        'interval': 'Com que frequência preciso fazer?',
        'downtime': 'Posso ir trabalhar logo depois?',
        'price': 'Quanto custa?',
      },
      priceAnswer:
          'Custa {price} por sessão, ou {packagePrice} no pacote de '
          '{sessions} sessões.',
      bookYes: 'Ótimo, gostaria de agendar para esta semana.',
      bookYesReply:
          'Claro, vou agendar e enviar por mensagem as orientações '
          'pós-procedimento.',
      bookNo: 'Vou pensar e depois entro em contato.',
      bookNoReply: 'Claro, fique à vontade para falar conosco quando quiser.',
      summary:
          'Recomendação: {procedure}, {price} por sessão, {packagePrice} por '
          '{sessions} sessões. {outcome}',
      booked: 'Agendado.',
      pending: 'Sem decisão; retomar o contato depois.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Cobertura verificada', ok: true),
        (code: 'LOST', message: 'Cobertura encerrada', ok: false),
        (
          code: 'NOT_FOUND',
          message: 'Nenhum beneficiário correspondente',
          ok: false,
        ),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Nenhuma interação encontrada', ok: true),
        (
          code: 'WARN_COMBINATION',
          message: 'Alerta de interação medicamentosa',
          ok: false,
        ),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'Guia de cobrança recebida', ok: true),
        (
          code: 'ADJUSTED',
          message: 'Guia de cobrança ajustada após análise',
          ok: false,
        ),
        (
          code: 'RETURNED',
          message: 'Guia de cobrança devolvida: campos ausentes',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'Receita eletrônica enviada', ok: true),
        (code: 'FAILED', message: 'A farmácia não a recebeu', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Identidade verificada', ok: true),
        (code: 'EXPIRED', message: 'QR code expirado', ok: false),
      ],
    },
    // Invented names of insurers.
    insurers: <String>[
      'Seguros Ventonorte',
      'Vida Marvista',
      'Seguradora Linha do Cume',
      'Saúde Pinhalto',
    ],
    // `{mention}` and `{patient}` stand at the start of a sentence, after
    // `para`, `em`, or `de` before a name (which takes no article), or alone:
    // no template needs `do` or `da` before a name.
    teamNotes: <String>[
      '{mention}, por favor, reduza a potência do laser em um nível para {patient}.',
      'Passagem de caso: o creme anestésico já foi aplicado em {patient}. '
          '{mention}, pode prosseguir quando quiser.',
      '{mention}, resta apenas uma sessão no pacote de {patient}.',
      '{patient} precisa da assinatura de um responsável. {mention}, por '
          'favor, confira.',
    ],
    deviceNameFormat: '{kind} nº\u00A0{number}',
    staffMentionFormat: '@{name} · {role}',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'Titular',
      'spouse': 'Cônjuge',
      'parent': 'Pai ou mãe',
      'child': 'Filho(a)',
      'sibling': 'Irmão(ã)',
      'grandparent': 'Avô ou avó',
      'grandchild': 'Neto(a)',
      'legalGuardian': 'Responsável legal',
      'other': 'Outro',
      'picoLaser': 'Laser de picossegundos',
      'hifu': 'HIFU',
      'rf': 'RF',
      'ipl': 'IPL',
      'ledTherapy': 'Fototerapia LED',
      'skinAnalyzer': 'Analisador de pele',
      'photoCamera': 'Câmera clínica',
      'labelPrinter': 'Impressora de etiquetas',
      'cardTerminal': 'Terminal de pagamento',
      'signaturePad': 'Tablet de assinatura',
      'kiosk': 'Totem de autoatendimento',
      'bridgePc': 'PC de integração',
      'positive': 'Positivo',
      'neutral': 'Neutro',
      'negative': 'Negativo',
      'counselor': 'Orientador(a)',
      'patientSpeaker': 'Paciente',
      'life': 'Seguro de vida',
      'nonLife': 'Seguro geral',
    },
  ),
  ops: CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: 'Lifting', color: '#6366F1'),
      (code: 'referral', label: 'Indicação', color: '#10B981'),
      (code: 'caution', label: 'Atenção', color: '#EF4444'),
      (code: 'package', label: 'Paciente com pacote', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'Agendamento on-line', color: '#03C75A'),
      (code: 'referral', label: 'Indicação', color: '#10B981'),
      (code: 'instagramAd', label: 'Anúncio em rede social', color: '#E1306C'),
      (code: 'search', label: 'Busca on-line', color: '#7C3AED'),
      (code: 'walkIn', label: 'Sem hora marcada', color: '#64748B'),
    ],
    specialNotes: <String>[
      'Alergia à lidocaína',
      'Propensão a queloides: reduzir a potência do laser',
      'Usa anticoagulantes: conferir antes dos procedimentos',
      'Alergia à penicilina',
    ],
    rooms: <CoRoomSpec>[
      (
        name: 'Sala de orientação 1',
        kind: 'counseling',
        staffRole: 'counselor',
      ),
      (name: 'Consultório 1', kind: 'consultation', staffRole: 'director'),
      (name: 'Consultório 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'Sala de procedimentos 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'Cabine de estética 1', kind: 'care', staffRole: 'skincare'),
      (name: 'Caixa', kind: 'payment', staffRole: 'coordinator'),
      (name: 'Recepção por tablet', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      'Esclarecido o prazo de retenção dos dados.',
      'Inclusão da rede de receita eletrônica entre os destinatários.',
      'Indicação da retenção de 90 dias das gravações de orientação por IA.',
    ],
    consentDispatch: <String, String>{
      'sent': 'Solicitação de assinatura enviada.',
      'opened': 'O paciente abriu a solicitação.',
      'signed': 'Assinado eletronicamente.',
      'expired': 'A solicitação expirou (24 horas).',
      'failed': 'Não foi possível enviar a solicitação; confira o número.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>[
        'Paciente frequente 10%',
        'Familiar de funcionário 20%',
      ],
      'coupon': <String>[
        'Cupom de 20% na primeira visita',
        'Cupom de aniversário',
      ],
      'point': <String>['Pontos utilizados'],
      'rounding': <String>['Arredondamento'],
    },
    pointReasons: <String, String>{
      'earn': 'Acúmulo de 3% do pagamento',
      'use': 'Uso no pagamento',
      'bonus': 'Bônus por avaliação',
      'expire': 'Expiração',
      'refund': 'Estorno após reembolso',
      'adjust': 'Ajuste manual',
    },
    paymentMessages: <String, String>{
      'approved': 'Cartão aprovado.',
      'cashReceipt': 'Recibo de pagamento em dinheiro emitido.',
      'partialCancel': 'Cancelamento parcial realizado.',
      'prepaidUsed': 'Cobrado do saldo pré-pago.',
      'declined': 'Cartão recusado: {reason}',
    },
    tasks: <String>[
      'Conferir o estoque de ponteiras do laser',
      'Pedir suprimentos',
      'Fechamento diário',
      'Registrar a temperatura da geladeira',
    ],
    taskMemos: <String>[
      'Por favor, conclua antes das 15h.',
      'Peça imediatamente se restarem menos de 5.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'Registrar chegada',
      'reservation': 'Encontrar meu agendamento',
      'payment': 'Pagar',
      'document': 'Documentos',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: 'Mesmo procedimento nos últimos 3 meses'),
      (
        kind: 'priceRule',
        rule: 'Sugerir pacotes já adquiridos antes de sessões avulsas',
      ),
      (
        kind: 'contraindication',
        rule: 'Não usar creme anestésico em caso de alergia à lidocaína',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING':
          'Sem consentimento para gravação; a orientação por IA não pode começar.',
      'STT_FAILED': 'Falha no reconhecimento de voz. Verifique o microfone.',
      'TOO_SHORT': 'A gravação é curta demais para ser resumida.',
      'MODEL_TIMEOUT': 'O resumo está atrasado. Tente novamente em instantes.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message:
            'Diagnósticos estéticos não podem ser cobrados como consulta coberta pelo plano de saúde.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: 'Consulta de retorno cobrada duas vezes no mesmo dia.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'Sem consentimento para publicidade noturna',
      'MARKETING_NO_CONSENT': 'Sem consentimento para marketing',
      'OPTED_OUT': 'Descadastrado',
      'INVALID_NUMBER': 'Número inválido',
    },
    // It ends the name of a compound package: `… + creme reparador de brinde`.
    packageBonus: 'creme reparador de brinde',
    staffNotices: <String, List<({String title, String body})>>{
      'training': <({String title, String body})>[
        (
          title: 'Treinamento do novo aparelho de laser',
          body:
              'O treinamento do novo laser será na próxima quarta-feira, às 18h, na Sala de procedimentos 1.',
        ),
      ],
      'policy': <({String title, String body})>[
        (
          title: 'Revisão de acessos ao número de identificação',
          body:
              'Os números de identificação completos só podem ser exibidos com um motivo; os acessos são revisados todo mês.',
        ),
      ],
      'schedule': <({String title, String body})>[
        (
          title: 'Escala de feriados',
          body:
              'Na véspera do feriado, o expediente termina às 17h. Confira a escala compartilhada.',
        ),
      ],
    },
    vitalsNotes: <String, String>{
      'normal':
          'Sinais vitais estáveis (PA {sys}/{dia}\u00A0mmHg, FC {pulse}, SpO2 {spo2}%, T {temp}\u00A0°C).',
      'highBp':
          'PA {sys}/{dia}\u00A0mmHg elevada; medir novamente após 10 minutos de repouso.',
      'fever':
          'Febrícula de {temp}\u00A0°C; a equipe médica decidirá se é necessário adiar.',
      'lowSpo2': 'SpO2 {spo2}% baixa; nova medição feita, sem falta de ar.',
      'highGlucose':
          'Glicemia de {glucose}\u00A0mg/dL elevada; leitura pós-prandial confirmada.',
    },
    // A date reads `quinta-feira (8/10)` and a range `de quarta-feira (25/11)
    // a quinta-feira (26/11)`, so that a notice needs no article or
    // contraction before it: the dates come after a colon. The reason follows
    // `Motivo`, and the name of a holiday stands in parentheses, so that
    // neither needs `de` or `do`.
    closure: <String, String>{
      'title': 'Aviso de fechamento: {dates}',
      'holiday':
          '{clinic}. Fechamento: {dates} ({name}). Retorno ao atendimento '
          'normal: {reopen}.',
      'other':
          '{clinic}. Fechamento: {dates}. Motivo: {reason}. Retorno ao '
          'atendimento normal: {reopen}.',
    },
    closureReasons: <String>[
      'congresso médico',
      'reforma',
      'manutenção de equipamentos',
    ],
    dateFormat: '{weekday} ({day}/{month})',
    weekdayNames: <String>[
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ],
    dateRangeFormat: 'de {from} a {to}',
    compoundItemFormat: '{name} ({sessions} sessões)',
    labels: <String, String>{
      'requested': 'Solicitado',
      'waiting': 'Em espera',
      'priority': 'Prioritário',
      'inProgress': 'Em andamento',
      'done': 'Finalizado',
      'tablet': 'Tablet',
      'online': 'On-line',
      'app': 'Aplicativo',
      'kiosk': 'Totem',
      'desk': 'Balcão',
      'paper': 'Papel',
      'privacyRequired': 'Dados pessoais (obrigatório)',
      'marketingOptional': 'Marketing (opcional)',
      'sensitiveInfo': 'Dados sensíveis',
      'photoUse': 'Uso de fotos',
      'thirdParty': 'Compartilhamento com terceiros',
      'aiRecording': 'Gravação por IA',
      'nightAdvertising': 'Publicidade noturna',
      'agreed': 'De acordo',
      'withdrawn': 'Revogado',
      'chartHistory': 'Histórico do prontuário',
      'procedureHistory': 'Histórico de procedimentos',
      'priceRule': 'Regra de preço',
      'contraindication': 'Contraindicação',
      'guideline': 'Diretriz',
      'preference': 'Preferência',
      'error': 'Erro',
      'warning': 'Aviso',
      'discount': 'Desconto',
      'coupon': 'Cupom',
      'point': 'Pontos',
      'rounding': 'Arredondamento',
    },
  ),
  // The real: `R$ 1.234,56`, with a no-break space after the symbol, a dot
  // between thousands, and a comma before the centavos.
  currency: CoCurrencyFormat(
    code: 'BRL',
    symbol: r'R$',
    pattern: '{symbol}\u00A0{amount}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // The English units, at about five times: R$ 10 for a price, R$ 50 for a
  // package or a prepaid step, R$ 5 for a discount or a point. A payment in
  // installments starts at R$ 600, because Brazilian clinics sell in
  // `parcelas` from a low amount, and a split payment from R$ 250.
  priceScale: CoClinicPriceScale(
    priceRounding: 10,
    packageRounding: 50,
    prepaidStep: 50,
    installmentMinimum: 600,
    splitMinimum: 250,
    splitRounding: 5,
    adjustmentUnit: 5,
    pointUnit: 5,
    quoteMin: 250,
    quoteMax: 1500,
  ),
  clinicNameFormat: '{suffix} {prefix}',
  koreanValues: CoKoreanValues.none,
  // The shape of a CPF as a screen shows it, masked but for the middle: the
  // first three digits and the check digits are hidden.
  maskedIdFormat: '***.###.###-**',
  // The street line and the city and state, as the national locale writes an
  // address: `Rua das Flores, 123 - São Paulo - SP`.
  addressLineFormat: '{line1} - {city} - {regionCode}',
);
