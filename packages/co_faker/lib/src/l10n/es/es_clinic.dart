import '../../clinic_data.dart';
import '../../clinic_ops.dart';
import '../../clinic_texts.dart';
import '../../currency_format.dart';
import '../../korean_values.dart';

/// Spanish (Spain, `es`) clinic data for `faker.clinic`.
///
/// A general dermatology and aesthetic clinic in euros that follows
/// `CoFakerClinicData.english`: every list has the length of the English one,
/// in the same order, so that one seed picks the same record in both
/// languages. `es`, `es_ES`, and `CoFaker.forLanguage('es')` read it.
///
/// What makes the data Spanish and not a translation only:
///
/// - the amounts are euros written `1.234,56 €`: a dot between thousands, a
///   comma before the cents, and a no-break space before the symbol. The
///   price bands and the price scale are in euros, as in the French data;
/// - a clinic name is the kind of place first and the name after it
///   (`Clínica de Pediatría Los Arces`), and a date is `miércoles 25/11`;
/// - the patient is addressed with `usted`, and a text that a value fills
///   never puts `de` or `a` before it, because the gender of the value decides
///   the contraction (`del`, `al`): the value comes after a colon, in
///   parentheses, or after `para` or `con`;
/// - the insurance is the public health system or a private patient, and no
///   institution of Spain is named;
/// - no value of the Korean data appears (`CoKoreanValues.none`): the ID is
///   masked in the shape of a DNI (`***4567**`), the phones and addresses are
///   those of Spain, and a closure notice gives a reason.
const CoFakerClinicData esClinic = CoFakerClinicData(
  specialties: <CoSpecialtySpec>[
    (name: 'Dermatología', clinicSuffix: 'Clínica Dermatológica'),
    (name: 'Cirugía Plástica', clinicSuffix: 'Clínica de Cirugía Plástica'),
    (
      name: 'Medicina Familiar y Comunitaria',
      clinicSuffix: 'Consulta de Medicina General',
    ),
    (name: 'Medicina Interna', clinicSuffix: 'Consulta de Medicina Interna'),
    (name: 'Pediatría', clinicSuffix: 'Clínica de Pediatría'),
  ],
  // They follow the kind of place: `Clínica de Pediatría Los Arces`, or
  // `Clínica Dermatológica de Demostración`.
  clinicNamePrefixes: <String>[
    'Vistaclara',
    'El Claro',
    'Los Arces',
    'La Ribera',
    'Los Abetos',
    'Modelo',
    'de Demostración',
    'Puerta Norte',
  ],
  // A role is a generic title, written in the masculine as a form does.
  staffRoles: <String, String>{
    'director': 'Director médico',
    'doctor': 'Médico',
    'counselor': 'Asesor de pacientes',
    'coordinator': 'Coordinador asistencial',
    'nurse': 'Enfermero',
    'nurseAide': 'Técnico en cuidados de enfermería',
    'skincare': 'Esteticista',
    'desk': 'Recepción',
  },
  visitPurposes: <CoVisitPurposeSpec>[
    (
      name: 'Consulta',
      details: <String>['Primera consulta', 'Consulta de revisión'],
    ),
    (
      name: 'Procedimiento',
      details: <String>['Inyectables', 'Láser', 'Lifting'],
    ),
    (
      name: 'Tratamiento',
      details: <String>['Acné', 'Afección cutánea', 'Verrugas'],
    ),
    (
      name: 'Cuidado',
      details: <String>['Tratamiento facial', 'Tratamiento calmante'],
    ),
  ],
  // Prices are euros, the bands of the French data.
  procedures: <CoProcedureSpec>[
    (
      code: 'CONS01',
      category: 'Consulta/Honorarios',
      name: 'Primera consulta',
      unit: 'consulta',
      minPrice: 70,
      maxPrice: 180,
      taxable: false,
    ),
    (
      code: 'BTX-F',
      category: 'Toxina botulínica/Arrugas',
      name: 'Toxina botulínica en la frente',
      unit: 'zona',
      minPrice: 140,
      maxPrice: 400,
      taxable: true,
    ),
    (
      code: 'FIL-L',
      category: 'Relleno/Zona',
      name: 'Relleno de labios con ácido hialurónico, 1\u00A0ml',
      unit: 'ml',
      minPrice: 450,
      maxPrice: 800,
      taxable: true,
    ),
    (
      code: 'LT-01',
      category: 'Láser/Unificación del tono',
      name: 'Láser de picosegundos para unificar el tono',
      unit: 'sesión',
      minPrice: 180,
      maxPrice: 450,
      taxable: true,
    ),
    (
      code: 'HIFU-300',
      category: 'Lifting/Ultrasonidos',
      name: 'Lifting con ultrasonidos focalizados, 300 líneas',
      unit: 'sesión',
      minPrice: 800,
      maxPrice: 2700,
      taxable: true,
    ),
    (
      code: 'ACN-01',
      category: 'Acné/Tratamiento',
      name: 'Extracción de comedones',
      unit: 'sesión',
      minPrice: 50,
      maxPrice: 130,
      taxable: false,
    ),
    (
      code: 'CARE-01',
      category: 'Cuidado/Calmante',
      name: 'Tratamiento facial calmante con LED',
      unit: 'sesión',
      minPrice: 50,
      maxPrice: 120,
      taxable: true,
    ),
    (
      code: 'DOC-01',
      category: 'Documentos médicos',
      name: 'Certificado médico',
      unit: 'ejemplar',
      minPrice: 10,
      maxPrice: 30,
      taxable: false,
    ),
  ],
  // The codes and the English names are the ones of the English data; the
  // Spanish names are those of the Spanish version of ICD-10 (CIE-10).
  diagnoses: <CoDiagnosisSpec>[
    (code: 'L70.0', name: 'Acné vulgar', nameEn: 'Acne vulgaris'),
    (code: 'L81.1', name: 'Cloasma', nameEn: 'Chloasma'),
    (code: 'B07', name: 'Verrugas víricas', nameEn: 'Viral warts'),
    (
      code: 'L20.9',
      name: 'Dermatitis atópica, no especificada',
      nameEn: 'Atopic dermatitis, unspecified',
    ),
    (
      code: 'L30.9',
      name: 'Dermatitis, no especificada',
      nameEn: 'Dermatitis, unspecified',
    ),
    (
      code: 'L71.9',
      name: 'Rosácea, no especificada',
      nameEn: 'Rosacea, unspecified',
    ),
  ],
  // Invented names that no marketed product has, as in the English data.
  drugStems: <String>[
    'Velquira',
    'Tormaxen',
    'Brisolan',
    'Quelvatin',
    'Ondrafex',
    'Sarmivel',
    'Celtrobin',
    'Pravunel',
  ],
  // A drug reads `Velquira comprimido 10 mg`: the form has its leading space
  // and the unit a no-break one.
  drugForms: <({String form, String unit, List<int> strengths})>[
    (form: ' comprimido', unit: '\u00A0mg', strengths: <int>[5, 10, 20, 50]),
    (form: ' cápsula', unit: '\u00A0mg', strengths: <int>[25, 50, 100]),
    (form: ' pomada', unit: '\u00A0g', strengths: <int>[15, 30]),
    (form: ' crema', unit: '\u00A0g', strengths: <int>[15, 30]),
  ],
  drugUsages: <String>[
    'Una vez al día, al acostarse',
    'Dos veces al día, después de las comidas',
    'Aplicar una capa fina dos veces al día',
    'Aplicar una vez al día después de la limpieza',
  ],
  complaints: <String>[
    'Refiere manchas más oscuras en ambas mejillas',
    'Acné recurrente a lo largo de la mandíbula',
    'Le preocupan las arrugas de la frente',
    'Desea mejorar la flacidez de la piel',
    'Enrojecimiento persistente tras un procedimiento',
  ],
  findings: <String>[
    'Máculas parduzcas mal delimitadas en ambas regiones malares',
    'Múltiples pápulas inflamatorias en el mentón',
    'Arrugas dinámicas de la frente, grado 2',
    'Flacidez moderada del tercio inferior facial',
    'Eritema leve, sin edema',
  ],
  plans: <String>[
    'Sesión de láser cada dos semanas',
    'Extracción y tratamiento tópico',
    'Revisión dos semanas después de la infiltración',
    'Consejos de fotoprotección, revisión en cuatro semanas',
    'Observación; volver si empeora',
  ],
  memos: <String>[
    'Se indica no maquillarse durante 24\u00A0horas.',
    'Anestésico tópico aplicado 30\u00A0minutos antes del procedimiento.',
    'Fotos previas realizadas.',
    'Se explica el bono; el paciente lo decidirá más adelante.',
    'Próxima cita programada dentro de dos semanas.',
  ],
  questions: <CoQuestionSpec>[
    (
      question: '¿Tiene alguna alergia a medicamentos?',
      options: <String>['Ninguna', 'Lidocaína', 'Penicilina', 'No lo sé'],
    ),
    (
      question: '¿Toma algún medicamento?',
      options: <String>[
        'Ninguno',
        'Anticoagulantes',
        'Tratamiento para el acné',
        'Otro',
      ],
    ),
    (
      question: '¿Está embarazada o en periodo de lactancia?',
      options: <String>['No', 'Embarazada', 'Lactancia', 'No procede'],
    ),
    (
      question: '¿Qué le gustaría mejorar en primer lugar?',
      options: <String>['Manchas', 'Acné', 'Arrugas', 'Firmeza'],
    ),
  ],
  // Card networks, with the debit card that Spanish terminals still list in
  // place of the fourth.
  cardIssuers: <String>['Visa', 'Mastercard', 'Amex', 'Maestro'],
  // A status is written in the masculine, as the word `estado` it qualifies
  // is, because the same label serves an appointment and a visit.
  labels: <String, String>{
    'nhis': 'Sistema público de salud',
    'medicalAid1': 'Asistencia sanitaria pública (tipo 1)',
    'medicalAid2': 'Asistencia sanitaria pública (tipo 2)',
    'uninsured': 'Paciente privado',
    'reception': 'Admisión',
    'waiting': 'En espera',
    'consultation': 'Consulta',
    'counseling': 'Asesoramiento',
    'procedure': 'Procedimiento',
    'care': 'Cuidado',
    'payment': 'Pago',
    'done': 'Finalizado',
    'requested': 'Solicitado',
    'reserved': 'Reservado',
    'confirmed': 'Confirmado',
    'checkedIn': 'Presente',
    'completed': 'Realizado',
    'cancelled': 'Cancelado',
    'noShow': 'No presentado',
    'rejected': 'Rechazado',
    'card': 'Tarjeta',
    'cash': 'Efectivo',
    'transfer': 'Transferencia bancaria',
    'prepaid': 'Saldo prepago',
    'package': 'Bono',
    'female': 'Mujer',
    'male': 'Hombre',
  },
  // A package has 3, 5, or 10 sessions, so the word is always plural.
  packageNameFormat: '{name} · {sessions} sesiones',
  texts: CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'Consentimiento informado para el procedimiento',
        clauses: <String>[
          'Se me han explicado la finalidad, el método y el efecto esperado del procedimiento.',
          'Entiendo que pueden aparecer enrojecimiento, hinchazón o hematomas.',
          'Entiendo que los resultados varían y no están garantizados.',
          'He informado de mis medicamentos, mis alergias y un posible embarazo.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'Consentimiento para el tratamiento de datos personales',
        clauses: <String>[
          'Datos recogidos: nombre, fecha de nacimiento, datos de contacto e historia clínica.',
          'Finalidades: asistencia, recordatorios de citas y facturación.',
          'Puedo negarme, pero entonces la cita en línea puede no estar disponible.',
        ],
      ),
      (
        kind: 'photo',
        title: 'Consentimiento para la toma de fotografías',
        clauses: <String>[
          'Se toman fotos de antes y después para seguir la evolución.',
          'Las fotos se usan solo para el tratamiento y nunca se publican.',
        ],
      ),
    ],
    consentDisclaimer:
        'Texto de ejemplo solo para demostraciones. Sin revisión jurídica; '
        'no lo utilice como formulario de consentimiento real.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'El médico lo explicó todo con mucho detalle.',
        'Poca espera y un equipo muy amable.',
        'El tono de mi piel mejoró después de tres sesiones.',
      ],
      'neutral': <String>[
        'Buenos resultados, pero algo caro.',
        'El aparcamiento era poco práctico.',
      ],
      'negative': <String>[
        'Esperé más de 40 minutos después de la hora de mi cita.',
        'La factura final no coincidía con el presupuesto.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'láser de picosegundos',
        concern: 'Las manchas oscuras de mis mejillas van a más.',
        recommend:
            'Para la pigmentación, le recomiendo el láser de picosegundos.',
        pain: 'Pica un poco; la mayoría de las personas no necesita anestesia.',
        interval: 'Unas diez sesiones, cada dos semanas.',
        downtime:
            'Algo de enrojecimiento durante unas horas; puede lavarse la cara el mismo día.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'lifting con ultrasonidos focalizados',
        concern: 'Noto la línea de la mandíbula descolgada.',
        recommend:
            'El lifting con ultrasonidos focalizados reafirma las capas profundas.',
        pain:
            'Puede doler cerca del hueso, por eso aplicamos una crema anestésica.',
        interval: 'Una vez cada seis a doce meses.',
        downtime: 'Puede volver al trabajo enseguida.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'Buenos días, ¿en qué podemos ayudarle hoy?',
      questions: <String, String>{
        'pain': '¿Duele?',
        'interval': '¿Cada cuánto tengo que hacerlo?',
        'downtime': '¿Puedo ir a trabajar justo después?',
        'price': '¿Cuánto cuesta?',
      },
      priceAnswer:
          'Son {price} por sesión, o {packagePrice} con un bono de '
          '{sessions} sesiones.',
      bookYes: 'Perfecto, me gustaría pedir cita para esta semana.',
      bookYesReply:
          'Con mucho gusto. Le reservo la cita y le envío por SMS las '
          'indicaciones posteriores.',
      bookNo: 'Lo pensaré y ya les diré algo.',
      bookNoReply: 'Por supuesto, puede contactarnos cuando quiera.',
      summary:
          'Recomendación: {procedure}, {price} por sesión, {packagePrice} '
          'por {sessions} sesiones. {outcome}',
      booked: 'Cita reservada.',
      pending: 'Decisión pendiente; volver a contactar más adelante.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Cobertura verificada', ok: true),
        (code: 'LOST', message: 'Cobertura finalizada', ok: false),
        (code: 'NOT_FOUND', message: 'Ningún asegurado coincide', ok: false),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'No se detectan interacciones', ok: true),
        (
          code: 'WARN_COMBINATION',
          message: 'Alerta de interacción farmacológica',
          ok: false,
        ),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'Solicitud recibida', ok: true),
        (
          code: 'ADJUSTED',
          message: 'Solicitud ajustada tras la revisión',
          ok: false,
        ),
        (
          code: 'RETURNED',
          message: 'Solicitud devuelta: faltan campos',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'Receta electrónica enviada', ok: true),
        (code: 'FAILED', message: 'La farmacia no la ha recibido', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Identidad verificada', ok: true),
        (code: 'EXPIRED', message: 'Código QR caducado', ok: false),
      ],
    },
    // Invented names of insurers.
    insurers: <String>[
      'Mutua Brisanorte',
      'Vida Altavista',
      'Seguros Cimalínea',
      'Salud Arroyoclaro',
    ],
    // `{mention}` and `{patient}` stand at the start of a sentence, after
    // `para` or `con`, or alone: no template needs `del` or `al` before a
    // name.
    teamNotes: <String>[
      '{mention}, por favor, baje un nivel la potencia del láser para {patient}.',
      'Relevo: {patient} ya tiene aplicada la crema anestésica. '
          '{mention}, puede continuar cuando quiera.',
      '{mention}, queda una sola sesión del bono para {patient}.',
      'Se necesita la firma de un tutor legal para {patient}. {mention}, '
          'por favor, compruébelo.',
    ],
    deviceNameFormat: '{kind} n.º\u00A0{number}',
    staffMentionFormat: '@{name} ({role})',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'Titular',
      'spouse': 'Cónyuge',
      'parent': 'Padre o madre',
      'child': 'Hijo o hija',
      'sibling': 'Hermano o hermana',
      'grandparent': 'Abuelo o abuela',
      'grandchild': 'Nieto o nieta',
      'legalGuardian': 'Tutor legal',
      'other': 'Otro',
      'picoLaser': 'Láser de picosegundos',
      'hifu': 'HIFU',
      'rf': 'RF',
      'ipl': 'IPL',
      'ledTherapy': 'Fototerapia LED',
      'skinAnalyzer': 'Analizador de piel',
      'photoCamera': 'Cámara clínica',
      'labelPrinter': 'Impresora de etiquetas',
      'cardTerminal': 'Datáfono',
      'signaturePad': 'Tableta de firma',
      'kiosk': 'Quiosco de autoservicio',
      'bridgePc': 'PC de enlace',
      'positive': 'Positivo',
      'neutral': 'Neutro',
      'negative': 'Negativo',
      'counselor': 'Asesor',
      'patientSpeaker': 'Paciente',
      'life': 'Vida',
      'nonLife': 'No vida',
    },
  ),
  ops: CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: 'Lifting', color: '#6366F1'),
      (code: 'referral', label: 'Recomendación', color: '#10B981'),
      (code: 'caution', label: 'Precaución', color: '#EF4444'),
      (code: 'package', label: 'Con bono', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'Cita en línea', color: '#03C75A'),
      (code: 'referral', label: 'Recomendación', color: '#10B981'),
      (
        code: 'instagramAd',
        label: 'Anuncio en redes sociales',
        color: '#E1306C',
      ),
      (code: 'search', label: 'Búsqueda en internet', color: '#7C3AED'),
      (code: 'walkIn', label: 'Sin cita previa', color: '#64748B'),
    ],
    specialNotes: <String>[
      'Alergia a la lidocaína',
      'Tendencia a queloides: reducir la potencia del láser',
      'Toma anticoagulantes: comprobar antes de los procedimientos',
      'Alergia a la penicilina',
    ],
    rooms: <CoRoomSpec>[
      (
        name: 'Sala de asesoramiento 1',
        kind: 'counseling',
        staffRole: 'counselor',
      ),
      (name: 'Consulta 1', kind: 'consultation', staffRole: 'director'),
      (name: 'Consulta 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'Sala de procedimientos 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'Cabina de estética 1', kind: 'care', staffRole: 'skincare'),
      (name: 'Caja', kind: 'payment', staffRole: 'coordinator'),
      (name: 'Admisión en tableta', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      'Se precisa el plazo de conservación de los datos.',
      'Se añade la red de receta electrónica entre los destinatarios.',
      'Se indica la conservación durante 90 días de las grabaciones del asesoramiento con IA.',
    ],
    consentDispatch: <String, String>{
      'sent': 'Solicitud de firma enviada.',
      'opened': 'El paciente ha abierto la solicitud.',
      'signed': 'Firmado electrónicamente.',
      'expired': 'La solicitud ha caducado (24\u00A0horas).',
      'failed': 'No se pudo enviar la solicitud; compruebe el número.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>[
        'Descuento paciente habitual 10\u00A0%',
        'Descuento familiar del personal 20\u00A0%',
      ],
      'coupon': <String>[
        'Cupón primera visita 20\u00A0%',
        'Cupón de cumpleaños',
      ],
      'point': <String>['Puntos canjeados'],
      'rounding': <String>['Redondeo'],
    },
    pointReasons: <String, String>{
      'earn': 'Acumulado el 3\u00A0% del pago',
      'use': 'Canjeados en el pago',
      'bonus': 'Bonificación por una reseña',
      'expire': 'Caducados',
      'refund': 'Anulados tras un reembolso',
      'adjust': 'Ajuste manual',
    },
    paymentMessages: <String, String>{
      'approved': 'Tarjeta aceptada.',
      'cashReceipt': 'Recibo de pago en efectivo emitido.',
      'partialCancel': 'Anulación parcial realizada.',
      'prepaidUsed': 'Cargado al saldo prepago.',
      'declined': 'Tarjeta rechazada: {reason}',
    },
    tasks: <String>[
      'Revisar las existencias de puntas de láser',
      'Pedir material',
      'Cierre de caja diario',
      'Anotar la temperatura del frigorífico',
    ],
    taskMemos: <String>[
      'Terminar antes de las 15:00.',
      'Pedir de inmediato si quedan menos de 5.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'Registrar llegada',
      'reservation': 'Buscar mi cita',
      'payment': 'Pagar',
      'document': 'Mis documentos',
    },
    evidence: <CoEvidenceSpec>[
      (
        kind: 'chartHistory',
        rule: 'Mismo procedimiento en los últimos 3 meses',
      ),
      (
        kind: 'priceRule',
        rule:
            'Proponer primero los bonos ya contratados antes que las '
            'sesiones sueltas',
      ),
      (
        kind: 'contraindication',
        rule: 'Excluir la crema anestésica en caso de alergia a la lidocaína',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING':
          'Sin consentimiento para la grabación; el asesoramiento con IA no puede empezar.',
      'STT_FAILED': 'Ha fallado el reconocimiento de voz. Revise el micrófono.',
      'TOO_SHORT': 'La grabación es demasiado corta para resumirla.',
      'MODEL_TIMEOUT':
          'El resumen se está retrasando. Vuelva a intentarlo en un momento.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message:
            'Un diagnóstico estético no permite facturar una consulta cubierta por el seguro.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: 'Consulta de revisión facturada dos veces el mismo día.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'Sin consentimiento para publicidad nocturna',
      'MARKETING_NO_CONSENT': 'Sin consentimiento de marketing',
      'OPTED_OUT': 'Baja voluntaria',
      'INVALID_NUMBER': 'Número no válido',
    },
    // It ends the name of a compound package: `… + crema reparadora de
    // regalo`.
    packageBonus: 'crema reparadora de regalo',
    staffNotices: <String, List<({String title, String body})>>{
      'training': <({String title, String body})>[
        (
          title: 'Formación sobre el nuevo equipo láser',
          body:
              'La formación sobre el nuevo láser será el próximo miércoles a las 18:00 en la sala de procedimientos 1.',
        ),
      ],
      'policy': <({String title, String body})>[
        (
          title: 'Control de accesos a los números de identificación',
          body:
              'Los números de identificación completos solo pueden mostrarse con un motivo; los accesos se revisan cada mes.',
        ),
      ],
      'schedule': <({String title, String body})>[
        (
          title: 'Calendario de festivos',
          body:
              'La víspera del festivo se cierra a las 17:00. Consulte el calendario compartido.',
        ),
      ],
    },
    vitalsNotes: <String, String>{
      'normal':
          'Constantes estables (TA {sys}/{dia}\u00A0mmHg, FC {pulse}, SpO2 {spo2}\u00A0%, T.ª {temp}\u00A0°C).',
      'highBp':
          'TA {sys}/{dia}\u00A0mmHg elevada; volver a medir tras 10\u00A0minutos de reposo.',
      'fever':
          'Febrícula de {temp}\u00A0°C; el médico decidirá si hay que aplazar.',
      'lowSpo2':
          'SpO2 {spo2}\u00A0% baja; medida de nuevo, sin dificultad respiratoria.',
      'highGlucose':
          'Glucemia de {glucose}\u00A0mg/dL elevada; medición posprandial confirmada.',
    },
    // A date reads `miércoles 25/11` and a range `del miércoles 25/11 al
    // jueves 26/11`, after a colon, so that a notice needs no article or
    // preposition before it. The reason follows `Motivo`, and the name of a
    // holiday stands in parentheses, so that neither needs `de` or `del`.
    closure: <String, String>{
      'title': 'Aviso de cierre: {dates}',
      'holiday':
          '{clinic}. Cierre: {dates} ({name}). Reanudación de la actividad '
          'habitual: {reopen}.',
      'other':
          '{clinic}. Cierre: {dates}. Motivo: {reason}. Reanudación de la '
          'actividad habitual: {reopen}.',
    },
    closureReasons: <String>[
      'congreso médico',
      'obras de reforma',
      'mantenimiento de equipos',
    ],
    dateFormat: '{weekday} {day}/{month}',
    weekdayNames: <String>[
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ],
    dateRangeFormat: 'del {from} al {to}',
    compoundItemFormat: '{name} ({sessions} sesiones)',
    labels: <String, String>{
      'requested': 'Solicitado',
      'waiting': 'En espera',
      'priority': 'Prioritario',
      'inProgress': 'En curso',
      'done': 'Finalizado',
      'tablet': 'Tableta',
      'online': 'En línea',
      'app': 'Aplicación',
      'kiosk': 'Quiosco',
      'desk': 'Mostrador',
      'paper': 'Papel',
      'privacyRequired': 'Datos personales (obligatorio)',
      'marketingOptional': 'Marketing (opcional)',
      'sensitiveInfo': 'Datos sensibles',
      'photoUse': 'Uso de fotografías',
      'thirdParty': 'Cesión a terceros',
      'aiRecording': 'Grabación con IA',
      'nightAdvertising': 'Publicidad nocturna',
      'agreed': 'Aceptado',
      'withdrawn': 'Revocado',
      'chartHistory': 'Historial clínico',
      'procedureHistory': 'Historial de procedimientos',
      'priceRule': 'Regla de precios',
      'contraindication': 'Contraindicación',
      'guideline': 'Guía clínica',
      'preference': 'Preferencia',
      'error': 'Error',
      'warning': 'Advertencia',
      'discount': 'Descuento',
      'coupon': 'Cupón',
      'point': 'Puntos',
      'rounding': 'Redondeo',
    },
  ),
  // The euro: `1.234,56 €`, with a dot between thousands, a comma before the
  // cents, and a no-break space before the symbol.
  currency: CoCurrencyFormat(
    code: 'EUR',
    symbol: '€',
    pattern: '{amount}\u00A0{symbol}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // The units of the French data, which is in euros too: five euros for a
  // price, ten for a package, a point for a euro.
  priceScale: CoClinicPriceScale(
    priceRounding: 5,
    packageRounding: 10,
    prepaidStep: 10,
    installmentMinimum: 400,
    splitMinimum: 50,
    splitRounding: 1,
    adjustmentUnit: 1,
    pointUnit: 1,
    quoteMin: 50,
    quoteMax: 300,
  ),
  clinicNameFormat: '{suffix} {prefix}',
  koreanValues: CoKoreanValues.none,
  // The shape of a DNI, eight digits and a letter, masked but for the middle.
  maskedIdFormat: '***####**',
  // The street line and the city, as the national locale writes an address:
  // `Calle Mayor, 12, Madrid`.
  addressLineFormat: '{line1}, {city}',
);
