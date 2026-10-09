import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// Spanish (Spain, `es`) SaaS data for `faker.saas`.
///
/// The back office of a clinic software vendor in euros that follows
/// `CoFakerSaasData.english`: every list has the length of the English one, in
/// the same order, and a map has its keys. `es`, `es_ES`, and
/// `CoFaker.forLanguage('es')` read it.
///
/// What makes the data Spanish and not a translation only:
///
/// - the amounts are euros written `1.234,56 €`, the plans cost euros, and the
///   VAT of an invoice is the 21% that Spain applies to a software service;
/// - a notification template writes its variables in Spanish
///   (`#{nombre}`, `#{clinica}`), and no variable follows `de` or `a`,
///   because the gender of the value decides the contraction (`del`, `al`):
///   the clinic and the date stand after a colon, `para`, or `el` before a
///   date (`el #{fecha_hora}`), which never changes;
/// - a title that a name or a service fills (`{target}`, `{service}`) puts the
///   name first and a colon after it, so that it needs no preposition;
/// - a count is written after its label (`Citas reservadas: {n}`), which
///   needs no plural to agree;
/// - no Korean-only value appears (`CoKoreanValues.none`): the business number
///   of a tenant has the shape of a Spanish tax ID of a limited company (`B`
///   and eight digits), in random digits.
const CoFakerSaasData esSaas = CoFakerSaasData(
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'Básico',
      monthlyPrice: 69,
      seats: 3,
      messageCredits: 500,
    ),
    (
      code: 'standard',
      name: 'Estándar',
      monthlyPrice: 149,
      seats: 10,
      messageCredits: 2000,
    ),
    (
      code: 'pro',
      name: 'Profesional',
      monthlyPrice: 259,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'Empresa',
      monthlyPrice: 499,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  // The variables are Spanish and stand after a colon, a comma, a
  // parenthesis, `a las`, or the `el` of a date, because the template is not
  // filled by the generator: the application that sends it fills them.
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'Cita reservada',
      body:
          'Hola, #{nombre}. Su cita está reservada: #{clinica}, el '
          '#{fecha_hora}.',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'Cita cancelada',
      body:
          'Hola, #{nombre}. Su cita prevista para el #{fecha_hora} se ha '
          'cancelado.',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'Recordatorio',
      body: 'Hola, #{nombre}. Le esperamos mañana a las #{hora}: #{clinica}.',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: 'Cuestionario previo a la visita',
      body:
          'Hola, #{nombre}. Por favor, rellene el cuestionario antes de su '
          'visita: #{enlace}',
    ),
    (
      code: 'SURVEY',
      name: 'Encuesta de satisfacción',
      body:
          'Hola, #{nombre}. ¿Qué tal fue su visita (#{clinica})? '
          '#{enlace}',
    ),
    (
      code: 'AD_EVENT',
      name: 'Promoción (publicidad)',
      body:
          '[Publi] Oferta del mes, #{clinica}: 10 sesiones de láser en '
          'promoción. Darse de baja: #{enlace}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: 'Mantenimiento programado',
      body:
          'El servicio no estará disponible de 2:00 a 4:00 por '
          'mantenimiento.',
    ),
    (
      category: 'release',
      title: 'Nuevas funciones disponibles',
      body:
          'Ahora puede ver el número de espera directamente en la pantalla '
          'de reservas.',
    ),
    (
      category: 'notice',
      title: 'Actualización de precios',
      body:
          'Los nuevos planes se aplican a partir de su próxima fecha de '
          'facturación.',
    ),
    (
      category: 'notice',
      title: 'Notificaciones con retraso',
      body:
          'Algunas notificaciones llegan con retraso y se enviarán por SMS '
          'en su lugar.',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': 'Número del destinatario no válido',
    'NOT_FRIEND': 'El destinatario no usa la aplicación de mensajería',
    'TEMPLATE_MISMATCH': 'La plantilla no coincide',
    'NO_CREDIT': 'Créditos insuficientes',
    'CARRIER_TIMEOUT': 'Tiempo de espera agotado en el operador',
    'OPTED_OUT': 'El destinatario se ha dado de baja',
  },
  // A status is written in the masculine, as the word `estado` it qualifies
  // is, because the same label serves a subscription and an invoice.
  labels: <String, String>{
    'trialing': 'En prueba',
    'active': 'Activo',
    'pastDue': 'Pago vencido',
    'paused': 'En pausa',
    'cancelled': 'Cancelado',
    'draft': 'Borrador',
    'open': 'Pendiente de pago',
    'paid': 'Pagado',
    'overdue': 'Vencido',
    'void': 'Anulado',
    'refunded': 'Reembolsado',
    'alimtalk': 'Notificación por mensajería',
    'sms': 'SMS',
    'lms': 'LMS',
    'queued': 'En cola',
    'sent': 'Enviado',
    'failed': 'Fallido',
    'fallbackSent': 'Enviado por canal alternativo',
    'approved': 'Aprobado',
    'reviewing': 'En revisión',
    'rejected': 'Rechazado',
    'pending': 'Pendiente',
    'eligibility': 'Verificación de cobertura',
    'dur': 'Revisión del uso de medicamentos',
    'ePrescription': 'Receta electrónica',
    'insuranceClaim': 'Solicitud de reembolso',
    'identityQr': 'Código QR de identidad',
    'alimtalkGateway': 'Pasarela de mensajería',
    'payment': 'Pasarela de pago',
    'up': 'Operativo',
    'degraded': 'Degradado',
    'down': 'Caído',
    'login': 'Inicio de sesión',
    'loginFailed': 'Inicio de sesión fallido',
    'view': 'Consulta',
    'revealRrn': 'Visualización del número de identificación',
    'create': 'Creación',
    'update': 'Modificación',
    'delete': 'Eliminación',
    'print': 'Impresión',
    'exportData': 'Exportación',
    'send': 'Envío',
    'roleChange': 'Cambio de rol',
    'notice': 'Aviso',
    'maintenance': 'Mantenimiento',
    'release': 'Versión',
    'fee': 'Tarifas',
    'drug': 'Precios de medicamentos',
    'material': 'Material fungible',
    'diagnosis': 'Diagnósticos',
    'current': 'Vigente',
    'scheduled': 'Programado',
    'archived': 'Archivado',
    'purchase': 'Compra',
    'usage': 'Uso',
    'refund': 'Reembolso',
    'grant': 'Asignación',
  },
  ops: CoFakerSaasOps(
    // A summary starts with the name it is about, then a colon: no `de` or
    // `del` stands before `{target}`.
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'Aprobar centro',
        summary: '{target}: alta aprobada.',
      ),
      'tenant.suspend': (
        label: 'Suspender centro',
        summary: '{target}: suspendido por impago.',
      ),
      'tenant.resume': (
        label: 'Reactivar centro',
        summary: '{target}: suspensión levantada.',
      ),
      'plan.change': (
        label: 'Cambiar de plan',
        summary: '{target}: cambio del plan Estándar al plan Profesional.',
      ),
      'invoice.issue': (
        label: 'Emitir factura',
        summary: '{target}: factura mensual emitida.',
      ),
      'invoice.refund': (
        label: 'Reembolsar factura',
        summary: '{target}: reembolso parcial de una factura.',
      ),
      'credit.grant': (
        label: 'Asignar créditos',
        summary: '{target}: 1000 créditos de mensajes asignados.',
      ),
      'template.approve': (
        label: 'Aprobar plantilla',
        summary: '{target}: plantilla aprobada.',
      ),
      'template.reject': (
        label: 'Rechazar plantilla',
        summary: '{target}: plantilla publicitaria rechazada.',
      ),
      'senderNumber.approve': (
        label: 'Aprobar número de remitente',
        summary: '{target}: número de remitente aprobado.',
      ),
      'master.publish': (
        label: 'Publicar el maestro de facturación',
        summary: 'Nuevo maestro de facturación publicado ({target}).',
      ),
      'notice.publish': (
        label: 'Publicar aviso',
        summary: 'Aviso «{target}» publicado.',
      ),
      'operator.invite': (
        label: 'Invitar a un operador',
        summary: 'Invitación de operador enviada: {target}.',
      ),
      'operator.roleChange': (
        label: 'Cambiar el rol de un operador',
        summary: '{target}: rol cambiado a administrador.',
      ),
      'impersonate.start': (
        label: 'Acceder como el centro',
        summary: '{target}: acceso en su nombre para analizar una incidencia.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'Propietario',
      'admin': 'Administrador',
      'billing': 'Facturación',
      'support': 'Atención al cliente',
      'viewer': 'Lector',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'Límite de la tarjeta superado',
      'CARD_EXPIRED': 'Tarjeta caducada',
      'INSUFFICIENT_FUNDS': 'Saldo insuficiente',
      'CARD_LOST': 'Tarjeta denunciada por pérdida o robo',
      'CARD_SUSPENDED': 'Tarjeta bloqueada',
      'ISSUER_TIMEOUT': 'Tiempo de espera agotado en el emisor',
    },
    // Unit prices in euros.
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'Primera consulta', price: 60),
        (name: 'Consulta de revisión', price: 45),
        (name: 'Crioterapia (una zona)', price: 35),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'Tormaxen comprimido 10\u00A0mg', price: 4),
        (name: 'Quelvatin pomada 15\u00A0g', price: 9),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'Gasas estériles (10)', price: 5),
        (name: 'Jeringa de 1\u00A0ml', price: 1),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'Acné vulgar', price: null),
        (name: 'Verrugas víricas', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'Sin códigos duplicados',
      'NEGATIVE_PRICE': 'Sin precios nulos ni negativos',
      'EFFECTIVE_DATE': 'Fechas de vigencia en orden',
      'REQUIRED_COLUMNS': 'Sin columnas obligatorias vacías',
      'ROW_DELTA':
          'Número de filas dentro del 5\u00A0% respecto a la versión anterior',
      'REMOVED_IN_USE':
          'Los códigos eliminados no se usan en solicitudes en curso',
    },
    // The service comes first, then a colon, so that no `de` stands before it.
    incidentTitles: <String, String>{
      'outage': '{service}: caída del servicio',
      'degraded': '{service}: respuestas lentas',
      'maintenance': '{service}: mantenimiento programado',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message:
            '3 centros tienen la sincronización sin conexión retrasada más de 15\u00A0minutos.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: 'Este mes han fallado 7 facturas en el cobro automático.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: '5 centros tienen menos de 100 créditos de mensajes.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'La copia de seguridad nocturna ha finalizado.',
      ),
    ],
    releaseItems: <String>[
      'Vea el número de espera directamente en la pantalla de reservas.',
      'Pagos fraccionados y saldo prepago en una sola pantalla.',
      'Las notificaciones fallidas pasan automáticamente a SMS.',
      'Mencione a sus compañeros con @ en las notas de la historia clínica.',
    ],
    regulationItems: <String>[
      'Aplicación de las tarifas revisadas.',
      'Aplicación de la lista actualizada de precios de medicamentos.',
      'Actualización de la correspondencia de códigos de diagnóstico.',
    ],
    releaseTitle: 'Notas de versión de la HCE {version}',
    regulationTitle: 'Actualizaciones normativas {month}',
    // The count follows its label, so that one or many needs no agreement.
    tenantActivities: <String>[
      'Pacientes nuevos registrados: {n}',
      'Solicitudes de reembolso enviadas: {n}',
      'Notificaciones enviadas: {n}',
      'Citas reservadas: {n}',
      'Cuentas de personal añadidas: {n}',
    ],
    templateRejectReason:
        'Contiene publicidad; envíelo como mensaje de marketing.',
    labels: <String, String>{
      'active': 'Activo',
      'invited': 'Invitado',
      'suspended': 'Suspendido',
      'allTenants': 'Todos los centros',
      'proAndAbove': 'Plan Profesional y superiores',
      'dermatology': 'Clínicas dermatológicas',
      'inApp': 'En la aplicación',
      'email': 'Correo electrónico',
      'alimtalk': 'Notificación por mensajería',
      'outage': 'Caída',
      'degraded': 'Degradado',
      'maintenance': 'Mantenimiento',
      'info': 'Información',
      'warning': 'Advertencia',
      'critical': 'Crítico',
      'topUp': 'Recarga',
      'usage': 'Uso',
      'refund': 'Reembolso',
      'card': 'Tarjeta',
      'transfer': 'Transferencia bancaria',
      'virtualAccount': 'Cuenta virtual',
      'release': 'Versión',
      'regulation': 'Actualización normativa',
      'failed': 'Pago fallido',
      'added': 'Añadido',
      'updated': 'Actualizado',
      'removed': 'Eliminado',
    },
    senderLabels: <String>['Línea principal', 'Citas', 'Recepción'],
    healthMessages: <String, String>{
      'degraded': 'Respuestas lentas',
      'down': 'Tiempo de conexión agotado',
    },
    auditTargets: <String, String>{
      'login': 'cuenta',
      'loginFailed': 'cuenta',
      'roleChange': 'rol del personal',
      'send': 'mensaje',
    },
    auditRecords: <String>['paciente', 'historia clínica', 'factura', 'cita'],
    masterCheckDetail: '{n} fila(s)',
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
  // Spain applies a 21% VAT (IVA) to a software service. The prepaid wallet of
  // message credits is topped up in euros, from fifty to two thousand, and a
  // top-up from a hundred euros earns a bonus of five to fifteen percent.
  priceScale: CoSaasPriceScale(
    vatRate: 0.21,
    prepaidTopUps: <int>[50, 100, 250, 500, 1000, 2000],
    prepaidBonusTiers: <(int, int)>[(100, 5), (250, 8), (500, 10), (1000, 15)],
    prepaidLowBalance: 100,
    prepaidUsageMin: 5,
    prepaidUsageRounding: 5,
    prepaidRefundMin: 5,
    prepaidRefundRounding: 5,
  ),
  koreanValues: CoKoreanValues.none,
  // A Spanish tax ID of a limited company (`B` and eight digits).
  businessNumberFormat: 'B########',
);
