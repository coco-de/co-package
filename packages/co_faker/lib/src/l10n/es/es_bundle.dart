import '../co_l10n_bundle.dart';

/// Spanish (Spain) domain text: the Spanish counterpart of every English key,
/// with the same number of texts in the same order, so that one seed picks the
/// same record in English, Korean, and Spanish. See [CoL10nBundle].
///
/// The conventions of the language are in `docs/languages/es.md`, and the ones
/// that a template has to keep are these:
///
/// - it is the Spanish of Spain (`es_ES`): Peninsular words and spellings
///   (`móvil`, `ordenador`, `zumo`, `aparcamiento`), not the American ones;
/// - the register is `usted`: a notice or an instruction says `Por favor,` and
///   the imperative of `usted` (`devuelva`, `consulte`), and a first-person line
///   of a customer says `me gustaría` or `¿podría…?`, with the opening `¿` and
///   `¡` of Spanish;
/// - a fictional name ends with `(ficticio)` and a sample label with
///   `(ejemplo)`, and nothing else marks a text as fictional; the marker is the
///   same masculine word after every name, whatever the gender of the noun
///   before it, because it reads as the tag `(nombre ficticio)` and not as an
///   adjective that agrees;
/// - a time is written with 24 hours and a colon (`18:00`), a range of hours
///   as `de 18:00 a 20:00`, a unit follows its number after a no-break space
///   (`U+00A0`: `2 ml`), the percent sign too (`10 %`, as the RAE
///   writes it), and a number of four digits takes no separator (`1000`);
/// - a template that a value fills never puts `el`, `la`, `del`, or `al` right
///   before the value, because the article and its contraction depend on the
///   gender of the value; a level follows `nivel` (masculine), a count follows
///   its label, and a person is named after `de` or a label, which take no
///   article before a given name.
const CoL10nBundle esBundle = CoL10nBundle(
  language: 'es',
  texts: <String, List<String>>{
    // common
    // The first letter of a given name, as English masks it.
    'common.maskedName': ['{initial}***'],
    'common.taxonomyChild': ['{root} · subtema {n}'],

    // fx
    'fx.currencyName.USD': ['Dólar estadounidense'],
    'fx.currencyName.JPY': ['Yen japonés'],
    'fx.currencyName.EUR': ['Euro'],
    'fx.currencyName.CNY': ['Yuan chino'],
    'fx.currencyName.THB': ['Baht tailandés'],
    'fx.currencyName.VND': ['Dong vietnamita'],
    'fx.currencyName.PHP': ['Peso filipino'],
    'fx.currencyName.NPR': ['Rupia nepalí'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      'Casa de cambio demo, aeropuerto T1',
      'Casa de cambio demo, Luzaral',
      'Casa de cambio demo, aeropuerto T2',
      'Casa de cambio demo, Riberazul',
      'Casa de cambio demo, Jaramar',
    ],
    'fx.couponName': [
      'Descuento del 80 % en el diferencial del USD (ejemplo)',
      'Descuento del 70 % en el diferencial del JPY (ejemplo)',
      'Descuento en el primer cambio de divisa (ejemplo)',
    ],
    'fx.tierName': ['Bronce', 'Plata', 'Oro'],

    // remit
    'remit.countryName.VN': ['Vietnam'],
    'remit.countryName.PH': ['Filipinas'],
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.US': ['Estados Unidos'],
    'remit.countryName.CN': ['China'],
    'remit.bankName': ['Banco colaborador Lumarante (ficticio)'],
    'remit.flagRule': [
      'Transferencia de importe elevado (regla de demostración)',
      'Comprobación de documentación adicional (regla de demostración)',
      'Comprobación de solicitudes repetidas (regla de demostración)',
    ],

    // vet
    'vet.petName': ['Cebada', 'Mariposa', 'Flan', 'Garbanzo', 'Nube'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['Bichón maltés', 'Caniche', 'Perro mestizo'],
    'vet.breed.cat': ['Gato doméstico de pelo corto', 'Gato mestizo'],
    'vet.breed.small_mammal': ['Conejo', 'Hámster'],
    'vet.breed.bird': ['Periquito'],
    'vet.breed.reptile': ['Tortuga terrestre'],
    'vet.coatColor': ['Blanco', 'Marrón', 'Negro', 'Tricolor', 'Gris'],
    'vet.vaccineName': [
      'Vacuna polivalente (ejemplo)',
      'Vacunación antirrábica (ejemplo)',
      'Vacuna polivalente felina (ejemplo)',
    ],
    'vet.preventiveProduct': [
      'Ejemplo de preventivo contra la filariosis (ficticio)',
      'Ejemplo de preventivo contra parásitos externos (ficticio)',
    ],
    'vet.vetDiagnosis': [
      'Observación de la piel (ejemplo)',
      'Observación digestiva (ejemplo)',
      'Observación rutinaria de salud (ejemplo)',
    ],
    'vet.vetDrug': [
      'Ejemplo de producto para la piel (ficticio)',
      'Ejemplo de producto digestivo (ficticio)',
      'Ejemplo de producto para los ojos (ficticio)',
    ],
    'vet.clinicRoom': [
      'Consulta veterinaria 1',
      'Consulta veterinaria 2',
      'Sala de vacunación',
    ],

    // grocery
    'grocery.originRegion': [
      'Zona de cultivo Luzaral (ficticio)',
      'Zona de cultivo Riberazul (ficticio)',
      'Zona de cultivo Campoalba (ficticio)',
    ],
    'grocery.harvestNote': [
      'Las fechas de cosecha y de envasado son ilustrativas.',
      'El texto sobre la frescura describe un producto ficticio.',
    ],
    'grocery.deliveryZone': [
      'Luzaral, zona A (demo)',
      'Riberazul, zona B (demo)',
      'Campoalba, zona C (demo)',
    ],
    'grocery.slotLabel': [
      'Madrugada, de 06:00 a 07:00',
      'Tarde, de 18:00 a 20:00',
    ],
    'grocery.substitutionNote': [
      'Ejemplo de sustitución por un artículo de peso similar.',
      'Ejemplo de reembolso sin sustitución.',
    ],
    'grocery.doorNote': [
      'Por favor, llame al portero automático del portal.',
      'Entrega en mano, sin dejar el pedido en la puerta.',
    ],
    'grocery.categoryName': [
      'Fruta',
      'Verduras',
      'Platos preparados',
      'Cereales',
      'Carne',
      'Pescado y marisco',
      'Lácteos',
    ],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': [
      'Fresas',
      'Espinacas',
      'Empanadillas caseras',
      'Arroz integral',
      'Solomillo de pollo',
      'Caballa congelada',
      'Leche',
    ],
    'catalog.groceryUnit': [
      '500 g',
      '200 g',
      '1 kg',
      '2 kg',
      '500 g',
      '600 g',
      '1 l',
    ],
    'catalog.groceryKindName': ['Huevos', 'Ternera Hanwoo para sopa', 'Rúcula'],
    // `10 uds.`: the abbreviation reads for any count.
    'catalog.groceryPackLabel': ['{n} uds.'],
    'catalog.commerceName': [
      'Auriculares inalámbricos',
      'Caja de almacenaje plegable',
      'Juego de toallas de algodón',
      'Taza de cerámica',
      'Aperitivo de cereales',
    ],
    'catalog.commerceUnit': ['1 par', '1 caja', '3 piezas', '1 pieza', '200 g'],

    // booking
    'booking.cancelReason': [
      'Cambio de planes (ejemplo)',
      'Se ha elegido otra hora (ejemplo)',
      'Motivo personal (ejemplo)',
    ],

    // dental
    'dental.dentalProcedure': [
      'Limpieza dental',
      'Ejemplo de endodoncia',
      'Ejemplo de obturación con resina',
      'Ejemplo de planificación de corona',
    ],
    'dental.dentalMaterial': [
      'Resina compuesta (ejemplo)',
      'Circonio (ejemplo)',
      'Cerámica (ejemplo)',
    ],
    'dental.chairName': [
      'Sillón dental 1',
      'Sillón dental 2',
      'Sillón dental 3',
    ],
    'dental.hygieneNote': [
      'Ejemplo de registro de la explicación sobre el cepillado.',
      'Ejemplo de registro de la observación de la higiene bucal.',
    ],

    // homecare
    'homecare.careGrade': [
      'Grado de cuidados 1',
      'Grado de cuidados 2',
      'Grado de cuidados 3',
      'Grado de cuidados 4',
      'Grado de cuidados 5',
      'Grado de apoyo cognitivo',
    ],
    'homecare.careTaskLabel': [
      'Ayuda con las comidas',
      'Comprobación del registro de medicación',
      'Ayuda con la higiene',
      'Ayuda con la movilidad',
      'Ayuda para ir al baño',
      'Conversación y compañía',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      'Casa de fideos del callejón (ficticio)',
      'Tienda de conveniencia de la estación (ficticio)',
      'Albergue del viajero (ficticio)',
    ],
    'travel_wallet.cityName': ['Osaka', 'Tokio', 'Bangkok', 'Hanói'],
    'travel_wallet.cardAlias': [
      'Tarjeta para excursiones (ficticio)',
      'Tarjeta de presupuesto del viaje (ficticio)',
    ],
    'travel_wallet.tripName': [
      'Cuatro días en Osaka',
      'Fin de semana en Bangkok',
      'Ruta a pie por Hanói',
    ],

    // b2b_trade
    'b2b_trade.buyerCompany': [
      'Cafetería Brisa Mansa (ficticio)',
      'Panadería Harina Fina (ficticio)',
      'Tienda de alimentación Arroyo Claro (ficticio)',
    ],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      'Vasos de papel de 360 ml, 1000 unidades',
      'Patatas congeladas, 10 kg',
      'Bolsas de papel, 100 unidades',
      'Toallitas higiénicas sin perfume, 20 unidades',
    ],
    'b2b_trade.quoteTitle': [
      'Presupuesto mensual de embalaje (ficticio)',
      'Presupuesto semanal de alimentos (ficticio)',
      'Presupuesto de artículos de higiene (ficticio)',
    ],
    'b2b_trade.holdReason': [
      'Comprobación del crédito disponible (ejemplo)',
      'Comprobación de la fecha de entrega (ejemplo)',
      'Comprobación de la especificación del artículo (ejemplo)',
    ],

    // group_deal
    'group_deal.dealTitle': [
      'Compra conjunta de cítricos de invierno',
      'Compra conjunta de auriculares inalámbricos',
      'Compra conjunta de toallas de algodón',
    ],
    'group_deal.optionLabel': [
      'Talla estándar',
      'Envoltorio para regalo',
      'Color estándar',
    ],
    'group_deal.rewardLabel': [
      'Sello de participación',
      'Puntos de recompensa ilustrativos',
      'Ventaja en el envío',
    ],
    'group_deal.benefitTitle': [
      'Ejemplo de cupón de envío gratuito',
      'Ejemplo de cupón para la próxima compra conjunta',
    ],
    'group_deal.settleNote': [
      'Ejemplo de total de las participaciones completadas.',
      'Ejemplo de total sin las participaciones canceladas.',
    ],

    // fitness
    // A class name from the category label and the level label of the same
    // record: the level follows `nivel`, which is masculine, so that the label
    // needs no agreement with the category (`Silla, nivel intermedio`).
    'fitness.className': ['{category}, nivel {level}'],
    'fitness.classCategoryLabel': ['Suelo', 'Reformer', 'Silla', 'Yoga'],
    'fitness.classLevelLabel': ['principiante', 'intermedio', 'avanzado'],
    'fitness.equipment': ['Esterilla', 'Reformer', 'Silla', 'Bloque de yoga'],
    'fitness.studioRoom': [
      'Sala de pilates suelo',
      'Sala de reformer',
      'Sala de silla',
      'Sala de yoga',
    ],
    'fitness.instructorSpecialty': [
      'Instrucción de pilates suelo',
      'Instrucción de reformer',
      'Instrucción de yoga',
    ],
    'fitness.instructorCareer': [
      '5 años impartiendo clases de pilates suelo',
      '3 años en el reformer',
      '8 años de yoga en grupo',
      '2 años de entrenamiento en grupos reducidos',
      '6 años de sesiones de rehabilitación',
    ],
    'fitness.passName': [
      'Bono de 10 clases de pilates suelo (ejemplo)',
      'Bono de 20 clases de reformer (ejemplo)',
      'Cuota mensual (ejemplo)',
    ],
    'fitness.cancelReason': ['Cambio de planes', 'Cambio de hora de la clase'],
    'fitness.noShowNote': [
      'Ejemplo de registro sin confirmación de asistencia.',
      'Ejemplo de ausencia anotada tras el inicio de la clase.',
    ],

    // space_rental
    'space_rental.spaceName': [
      'Sala de fiestas Las Cuatro (ficticio)',
      'Sala de estudio Luzaral (ficticio)',
      'Local de ensayo Riberazul (ficticio)',
    ],
    'space_rental.districtName': [
      'Ciudad ficticia, barrio de Luzaral',
      'Ciudad ficticia, barrio de Riberazul',
      'Ciudad ficticia, barrio de Jaramar',
    ],
    'space_rental.amenity': ['Wifi', 'Pizarra blanca', 'Dispensador de agua'],
    'space_rental.equipmentOption': [
      'Proyector (ejemplo)',
      'Equipo de sonido (ejemplo)',
      'Una plaza de aparcamiento (ejemplo)',
    ],
    'space_rental.houseRule': [
      'Por favor, devuelva el equipo después de usarlo.',
      'Por favor, respete el horario reservado.',
    ],
    'space_rental.bookingPurpose': [
      'Grupo de estudio',
      'Reunión de amigos',
      'Ensayo de grupo musical',
    ],
    'space_rental.guestMessage': [
      '¿Podría explicarme cómo se usa el equipo?',
      '¿Podría enviarme las instrucciones de acceso?',
    ],
    'space_rental.hostReply': [
      'Por favor, consulte la guía del equipo en la página de la reserva.',
      'Las instrucciones de acceso aparecen en los detalles de la reserva.',
    ],

    // dining
    'dining.restaurantName': [
      'Casa de fideos de perilla (ficticio)',
      'Pastas del Callejón (ficticio)',
      'Salón de té Luzaral (ficticio)',
    ],
    'dining.menuName': [
      'Fideos de perilla',
      'Pasta con tomate',
      'Bol de arroz con verduras',
      'Té caliente',
    ],
    // A table is `Mesa para 1`, `Mesa para 4`: no plural to agree.
    'dining.partyLabel': ['Mesa para {n}'],
    'dining.noShowNote': [
      'Ejemplo de registro de la cola sin confirmación de llegada.',
      'Ejemplo de ausencia tras la hora avisada.',
    ],
    'dining.loyaltyBenefit': [
      'Bebida en la quinta visita (ejemplo)',
      'Cupón de postre para clientes habituales (ejemplo)',
    ],
    'dining.districtName': [
      'Ciudad ficticia, barrio de Luzaral',
      'Ciudad ficticia, barrio de Riberazul',
    ],

    // daycare
    'daycare.childName': ['Lucía', 'Hugo', 'Martina', 'Leo', 'Vega'],
    'daycare.className': ['Clase Sol', 'Clase Luna', 'Clase Estrella'],
    'daycare.ageLabel': ['1 año', '2 años', '3 años', '4 años', '5 años'],
    // {name1} is the first given name drawn: only `de` stands before it, which
    // takes no article before a given name.
    'daycare.guardianLabel': ['Tutor/a de {name1}'],
    // The name is drawn without a sex, so the title is the short `profe` that
    // Spanish schools use for both.
    'daycare.teacherName': ['Profe {name1}'],
    'daycare.toiletNote': [
      'Una ida al baño registrada (ejemplo)',
      'Dos idas al baño registradas (ejemplo)',
      'Ningún registro (ejemplo)',
    ],
    'daycare.mealMenu': [
      'Arroz integral con guiso de verduras',
      'Sopa de tofu con arroz',
      'Arroz salteado con verduras',
    ],
    'daycare.snackMenu': ['Pera en gajos', 'Boniato al vapor', 'Yogur natural'],
    'daycare.allergenLabel': [
      'Leche',
      'Huevo',
      'Soja',
      'Trigo',
      'Ninguno anotado (ejemplo)',
    ],
    'daycare.activityTitle': [
      'Juegos en la nieve en invierno',
      'Construimos casitas de papel',
      'Juego con bloques de colores',
    ],
    'daycare.albumCaption': [
      'Ilustración ficticia de amigos construyendo con bloques',
      'Ilustración ficticia de juegos de invierno',
    ],
    'daycare.drugLabel': [
      'Jarabe para la fiebre (ficticio)',
      'Jarabe para la tos (ficticio)',
      'Crema hidratante de uso tópico (ficticio)',
    ],
    'daycare.medicationStorage': [
      'Temperatura ambiente',
      'Conservar en la nevera',
      'Proteger de la luz solar',
    ],
    'daycare.symptom': [
      'Mocos',
      'Tos leve',
      'Febrícula',
      'Erupción cutánea',
      'Malestar de estómago',
    ],
    'daycare.dosageLabel': [
      'Ejemplo indicado por la familia: 2 ml',
      'Ejemplo indicado por la familia: 3 ml',
      'Ejemplo indicado por la familia: una pequeña cantidad',
    ],
    'daycare.noticeTitle': [
      'Aviso sobre los juegos de invierno (ejemplo)',
      'Aviso de cambio de menú (ejemplo)',
      'Aviso de revisión de seguridad (ejemplo)',
    ],

    // exam_prep
    'exam_prep.subjectName': [
      'Bases de datos',
      'Bases de datos',
      'Redes',
      'Redes',
      'Redes',
      'Fundamentos de programación',
      'Fundamentos de programación',
      'Seguridad de la información',
      'Seguridad de la información',
    ],
    'exam_prep.unitName': [
      'Modelado de datos',
      'Fundamentos de SQL',
      'Capa de transporte',
      'Enrutamiento',
      'Capa de aplicación',
      'Variables',
      'Estructuras de datos',
      'Fundamentos de criptografía',
      'Control de acceso',
    ],
    'exam_prep.questionStem': [
      '¿Qué clave distingue las filas de una tabla?',
      '¿Qué cláusula SQL selecciona filas según una condición?',
      '¿Qué protocolo de transporte se encarga del orden y de la retransmisión?',
      '¿Qué dispositivo elige la siguiente ruta de un paquete?',
      '¿Qué protocolo expresa las peticiones y respuestas web?',
      '¿Qué guarda un valor bajo un nombre en un programa?',
      '¿Qué estructura saca primero el último valor introducido?',
      '¿Qué calcula un resumen de longitud fija a partir de una entrada?',
      '¿Qué principio concede solo los permisos necesarios para una tarea?',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      'Clave primaria',
      'WHERE',
      'TCP',
      'Enrutador',
      'HTTP',
      'Variable',
      'Pila',
      'Función hash',
      'Mínimo privilegio',
    ],
    'exam_prep.wrongChoice1': [
      'Fuente',
      'Fuente',
      'JPEG',
      'Altavoz',
      'PNG',
      'Borde',
      'Cola FIFO',
      'Selección de fuente',
      'Acceso público',
    ],
    'exam_prep.wrongChoice2': [
      'Color de fondo',
      'Margen',
      'CSS',
      'Teclado',
      'MP3',
      'Margen de página',
      'Imagen',
      'Zoom de pantalla',
      'Contraseña compartida',
    ],
    'exam_prep.wrongChoice3': [
      'Ancho de pantalla',
      'Icono',
      'SVG',
      'Monitor',
      'TTF',
      'Imagen de fondo',
      'Archivo de audio',
      'Relleno de fondo',
      'Comprobaciones omitidas',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    // A term that opens a definition is written in the case of the list
    // (`Clave primaria: ...`), because a test of the package compares the
    // explanation and the choice with the same case.
    'exam_prep.explanation': [
      'Clave primaria: identifica cada fila de una tabla.',
      'La cláusula WHERE expresa una condición para seleccionar filas.',
      'El protocolo TCP se encarga del orden y de la retransmisión de un flujo de bytes.',
      'Enrutador: elige la siguiente ruta a partir de la dirección de destino.',
      'El protocolo HTTP expresa las peticiones y respuestas web.',
      'Variable: permite que un programa se refiera a un valor por su nombre.',
      'Pila: saca primero el último valor introducido.',
      'Función hash: calcula un resumen de longitud fija a partir de una entrada.',
      'Mínimo privilegio: concede solo los permisos necesarios para una tarea.',
    ],
    'exam_prep.examPaperTitle': [
      'Examen de práctica 1 (ficticio)',
      'Examen de práctica 2 (ficticio)',
      'Prueba de repaso de la unidad (ficticio)',
    ],
    'exam_prep.studyTaskTitle': [
      'Resolver diez preguntas sobre la capa de transporte',
      'Repasar los errores de control de acceso',
      'Revisar los fundamentos de SQL',
    ],
    'exam_prep.taxonomyName': [
      'Bases de datos',
      'Redes',
      'Fundamentos de programación',
      'Seguridad de la información',
    ],

    // hrd
    'hrd.departmentName': [
      'Ventas',
      'Producción',
      'Investigación',
      'Soporte',
      'Administración',
      'Logística',
    ],
    'hrd.jobTitle': ['Técnico/a', 'Responsable', 'Jefe/a de equipo'],
    'hrd.courseTitle': [
      'Tratamiento de datos personales 2026 (ficticio)',
      'Trabajar en equipo con seguridad (ficticio)',
      'Organización de los registros de trabajo (ficticio)',
    ],
    'hrd.courseKind': ['Obligatorio', 'Profesional', 'Liderazgo'],
    'hrd.lessonTitle': [
      'Entender los principios básicos',
      'Revisar ejemplos de trabajo',
      'Comprobar los registros',
    ],
    'hrd.chapterTitle': ['Introducción', 'Repaso de ejemplos', 'Resumen'],
    'hrd.nudgeTitle': [
      'Recordatorio del plazo de la formación (ejemplo)',
      'Recordatorio de lección pendiente (ejemplo)',
    ],
    'hrd.exemptionReason': [
      'Justificante de formación externa completada (ejemplo)',
      'Comprobación del periodo de permiso (ejemplo)',
      'Comprobación de formación alternativa (ejemplo)',
    ],
    'hrd.classroomPlace': [
      'Aula Luzaral (ficticio)',
      'Sala de seminarios Riberazul (ficticio)',
    ],

    // neighborhood
    'neighborhood.neighborhoodName': [
      'Barrio de Luzaral (ficticio)',
      'Barrio del Ginkgo (ficticio)',
      'Barrio de Jaramar (ficticio)',
    ],
    'neighborhood.districtName': [
      'Ciudad ficticia, barrio de Riberazul',
      'Ciudad ficticia, barrio de Solarroyo',
    ],
    'neighborhood.nickname': [
      'GarbanzoLuzaral (ficticio)',
      'EstrellaJaramar (ficticio)',
      'NubeDelCallejón (ficticio)',
    ],
    'neighborhood.postTitle': [
      'Guante azul encontrado en el parque infantil (ejemplo)',
      'Descubrimos un paseo por el barrio (ejemplo)',
      'Regalo una maceta pequeña (ejemplo)',
    ],
    'neighborhood.postBody': [
      'Noticia ficticia del barrio. Los detalles están en esta publicación.',
      'Publicación de ejemplo para los vecinos; no incluye ningún teléfono ni dirección real.',
    ],
    'neighborhood.commentBody': [
      'Gracias por compartir la novedad.',
      'Lo compruebo y respondo en la publicación.',
      'Puedo mirarlo por la tarde.',
    ],
    'neighborhood.placeName': [
      'Panadería Luzaral (ficticio)',
      'Cenador del parque Riberazul (ficticio)',
      'Pequeña biblioteca Jaramar (ficticio)',
    ],
    'neighborhood.openHours': [
      'De 08:00 a 21:00',
      'De 09:00 a 18:00',
      'De 10:00 a 20:00',
    ],
    'neighborhood.bannedWord': [
      'publicidad-ejemplo',
      'insulto-ejemplo',
      'palabra-bloqueada-ejemplo',
    ],
    'neighborhood.keyword': [
      'guante',
      'paseo',
      'compartir',
      'noticias del barrio',
    ],

    // meetup
    'meetup.clubName': [
      'Carrera matinal Luzaral (ficticio)',
      'Club de lectura Riberazul (ficticio)',
      'Juegos de mesa Jaramar (ficticio)',
    ],
    'meetup.interestTag': [
      'Correr',
      'Lectura',
      'Juegos de mesa',
      'Fotografía',
      'Cocina',
      'Senderismo',
    ],
    'meetup.availableDays': [
      'Tardes entre semana',
      'Fines de semana',
      'Martes y jueves',
      'Sábados por la mañana',
      'Cualquier día',
    ],
    'meetup.clubIntro': [
      'Grupo ficticio que da la bienvenida a los vecinos que vienen por primera vez.',
      'Grupo de ejemplo para compartir pequeñas actividades.',
    ],
    'meetup.gatheringTitle': [
      'Quedada de la tercera semana de enero (ficticio)',
      'Charla de libros del fin de semana (ficticio)',
      'Paseo de invierno en grupo (ficticio)',
    ],
    'meetup.venueName': [
      'Entrada de la senda Riberazul (ficticio)',
      'Sala de reuniones Luzaral (ficticio)',
      'Cenador de Jaramar (ficticio)',
    ],
    'meetup.nickname': [
      'GarbanzoDelAlba (ficticio)',
      'NubeDeLibros (ficticio)',
      'EstrellitaPequeña (ficticio)',
    ],
    'meetup.duesItem': [
      'Cuota de la quedada (ejemplo)',
      'Bebidas a escote (ejemplo)',
      'Alquiler de material a escote (ejemplo)',
    ],
    'meetup.joinAnswer': [
      'Me gustaría participar en las actividades a partir de este mes.',
      'Puedo participar las mañanas de fin de semana.',
    ],
    'meetup.ruleText': [
      'Por favor, respete el tiempo de los demás.',
      'Por favor, hable dentro del grupo sin publicar datos de contacto.',
      'Por favor, avise al grupo si cancela.',
    ],
    'meetup.cadenceLabel': [
      'Todos los sábados a las 07:00',
      'Domingos alternos a las 10:00',
      'Primer sábado de cada mes a las 14:00',
    ],

    // fandom
    // The two approved fictional creators of the fandom pack: Spanish writes
    // two names of its own, never the Korean ones.
    'fandom.creatorName': ['Jardín de Arena Lenta', 'Veta de Cielo'],
    'fandom.fanNickname': ['Estrellita', 'Brote', 'Judía Lunar', 'Gota de Luz'],
    'fandom.benefitTitle': [
      'Ejemplo de imagen exclusiva para miembros',
      'Inscripción simulada a un evento',
      'Avance anticipado de un clip ficticio',
    ],
    'fandom.postCaption': [
      'Ilustración ficticia de un estudio en invierno',
      'Ejemplo de publicación sobre el horario de ensayo',
    ],
    'fandom.clipTitle': [
      'Ensayo de treinta segundos (ficticio)',
      'Saludo desde el estudio (ficticio)',
      'Nota sonora de invierno (ficticio)',
    ],
    'fandom.letterBody': [
      'Me ha gustado la publicación de ejemplo de hoy y espero la próxima novedad.',
      'La ilustración del estudio en invierno me ha parecido muy cálida. Os mando ánimo.',
    ],
    'fandom.eventTitle': [
      'Encuentro de fans de invierno (ficticio)',
      'Evento de historias del estudio (ficticio)',
    ],
    'fandom.agendaTitle': [
      'Programa del pequeño teatro de invierno (ficticio)',
      'Conversación ficticia en directo',
      'Calendario de nuevas publicaciones',
    ],
    'fandom.venueLabel': [
      'Pequeño teatro de invierno (ficticio)',
      'Estudio Luzaral (ficticio)',
      'Espacio en línea de ejemplo',
    ],

    // content
    'content.seriesTitle': [
      'La isla postal del faro de papel (ficticio)',
      'El pequeño mapa del estanque de nubes (ficticio)',
      'El jardín del reloj lento (ficticio)',
    ],
    'content.penName': [
      'Judía de Palabras (ficticio)',
      'Estrella de Papel (ficticio)',
      'Pluma de Nube (ficticio)',
    ],
    'content.synopsisLine': [
      'Unos personajes ficticios ordenan cartas en una pequeña isla.',
      'Una historia ficticia sobre dibujar un estanque que no aparece en el mapa.',
    ],
    'content.genreName': [
      'Fantasía',
      'Vida cotidiana',
      'Aventura',
      'Historias de ciencia',
      'Ensayo',
    ],
    'content.seriesSection': [
      'Semanales',
      'Novedades',
      'Finalizadas',
      'Diarias',
      'Series cortas',
    ],
    'content.episodeTitle': [
      'El primer barquito de papel (ficticio)',
      'Un puntito en el estanque (ficticio)',
      'Una tarde sin reloj (ficticio)',
    ],
    'content.cutAltText': [
      'Ilustración de un personaje ficticio que dobla un barquito de papel',
      'Ilustración de dos personajes ficticios junto a un estanque',
    ],
    'content.commentLine': [
      'La escena del barquito de papel se me ha quedado grabada.',
      'Me gustaría leer el siguiente episodio de ejemplo.',
    ],
    'content.chapterParagraph': [
      'En el buzón de la isla había una hoja en blanco. Una niña la dobló hasta darle la forma de un barquito como el estanque. Este párrafo es un ejemplo de demostración original y ficticio.',
      'Junto al reloj lento había una maceta pequeña. En lugar de ponerle nombre a la planta, dos amigos dibujaron las nubes que habían visto. Este es un párrafo de ejemplo original y ficticio.',
    ],
    'content.publisherName': [
      'Editorial Faro de Papel (ficticio)',
      'Editorial Estanque de Nubes (ficticio)',
    ],
    'content.audioTitle': [
      'Una tarde doblando barquitos de papel (ficticio)',
      'Notas sonoras de un pequeño estanque (ficticio)',
    ],
    'content.newsletterName': [
      'Notas semanales del Faro de Papel (ficticio)',
      'Cartitas del Estanque de Nubes (ficticio)',
    ],
    'content.articleHeadline': [
      'Ordenar las notas del día a día en pequeños grupos (ficticio)',
      'Apuntar los colores de un paseo de invierno (ficticio)',
    ],
    'content.topicName': [
      'Notas del día a día',
      'Paseos de invierno',
      'Pequeña ciencia',
      'Hábitos de lectura',
    ],
    'content.genreTaxonomy': [
      'Fantasía',
      'Vida cotidiana',
      'Aventura',
      'Historias de ciencia',
      'Ensayo',
    ],
    'content.audioTaxonomy': ['Audiolibro', 'Pódcast'],
    'content.topicTaxonomy': [
      'Notas del día a día',
      'Paseos de invierno',
      'Pequeña ciencia',
      'Hábitos de lectura',
      'Observaciones de la vida',
    ],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      'Por favor, revisen el estado de la invitación al equipo',
      'Consulta sobre las líneas de una factura de ejemplo',
      'Error de ejemplo al exportar a CSV',
      'Consulta sobre el estado de la integración',
      'Consulta sobre un botón de una pantalla de ejemplo',
      'Consulta sobre dónde encontrar ayuda',
    ],
    'helpdesk.ticketDescription': [
      'La cuenta de soporte ficticia muestra una invitación pendiente.',
      'Me gustaría revisar las líneas y el periodo de la factura ficticia.',
      'Aparece un estado de error al exportar los datos de ejemplo a CSV.',
      'Me gustaría revisar el texto de la página de estado de la integración ficticia.',
      'La pantalla de ejemplo no cambia después de pulsar un botón.',
      '¿Dónde encuentro la página de ayuda del soporte ficticio?',
    ],
    'helpdesk.macroName': [
      'Ejemplo de acuse de recibo',
      'Comprobación de información adicional',
      'Aviso del estado de la gestión',
    ],
    'helpdesk.helpArticleTitle': [
      'Guía de invitaciones de ejemplo',
      'Cómo leer una factura ficticia',
      'Exportar datos de ejemplo a CSV',
    ],
    'helpdesk.csatComment': [
      'He revisado la explicación.',
      'Las instrucciones de ejemplo eran fáciles de seguir.',
      'Tengo más detalles que comprobar.',
    ],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      'Compruebe el estado de la invitación en los ajustes de la cuenta. Este borrador simulado de IA necesita la revisión de un agente.',
      'Anote juntos el método de inicio de sesión y el error de ejemplo. Este borrador simulado de IA no hace ningún cambio en la cuenta.',
      'Compruebe el periodo y las líneas de la factura de ejemplo. Este borrador simulado de IA describe precios ficticios.',
      'Anote el número de la factura de ejemplo en la nota de soporte. Este borrador simulado de IA no es un aviso de pago real.',
      'Compruebe el intervalo de fechas y el formato elegidos para la exportación. Este borrador simulado de IA anota un error de ejemplo sin datos personales.',
      'Compruebe los nombres de las columnas y el estado del archivo en el CSV de ejemplo. Este borrador simulado de IA requiere la revisión de un agente.',
      'Anote el estado de integración de ejemplo y la hora de la comprobación. Este borrador simulado de IA no hace llamadas externas.',
      'Anote la pantalla y los pasos para reproducir el problema. Este borrador simulado de IA no promete ningún resultado.',
    ],
    'helpdesk.topicName': ['Cuenta', 'Facturación', 'Datos', 'Integración'],

    // campaign
    'campaign.brandName': [
      'Panadería Luz de Primavera (ficticio)',
      'Librería Claro de Luna (ficticio)',
      'Cafetería Jardín Verde (ficticio)',
    ],
    'campaign.campaignTitle': [
      'Oferta de invierno de ejemplo',
      'Novedades de ejemplo para la primera visita',
      'Novedades de ejemplo del fin de semana',
    ],
    'campaign.offerCopy': [
      '(Publicidad) Cupón de ejemplo para un menú de invierno ficticio. Para darse de baja, consulte los ajustes de la demo.',
      '(Publicidad) Oferta de ejemplo para un producto ficticio. La baja está en los ajustes de la demo.',
    ],
    'campaign.couponTitle': [
      'Cupón de ejemplo del 20 % de invierno',
      'Cupón de ejemplo del 10 % en la primera visita',
    ],
    'campaign.segmentName': [
      'Compradores de ejemplo de los últimos 30 días',
      'Grupo de ejemplo que acepta recibir ofertas',
      'Grupo de ejemplo de las novedades del fin de semana',
    ],
    'campaign.failReason': [
      'Falta el número del destinatario (ejemplo)',
      'Sin consentimiento para marketing (ejemplo)',
      'Sin consentimiento para envíos nocturnos (ejemplo)',
    ],

    // workplace
    'workplace.department': [
      'Equipo de frontend',
      'Equipo de backend',
      'Equipo de diseño',
      'Atención al cliente',
      'Recursos humanos',
    ],
    'workplace.approverRole': [
      'Jefe/a de equipo',
      'Dirección de departamento',
      'Responsable de RR. HH.',
      'Revisión financiera',
      'Dirección general',
    ],
    'workplace.closeSection': [
      'Nóminas',
      'Gastos',
      'Asistencia',
      'Beneficios sociales',
      'Periodificaciones',
    ],
    'workplace.position': ['Técnico/a', 'Responsable', 'Jefe/a de equipo'],
    'workplace.workPlace': [
      'Oficina Luzaral (ficticio)',
      'Centro de trabajo Riberazul (ficticio)',
      'Teletrabajo',
    ],
    'workplace.shiftName': [
      'Turno de día',
      'Turno de mañana',
      'Guardia de fin de semana',
    ],
    'workplace.approvalComment': [
      'He revisado el registro de ejemplo adjunto.',
      'El motivo de ejemplo necesita más aclaraciones.',
    ],
    'workplace.projectName': [
      'Renovación del portal de clientes (ficticio)',
      'Limpieza de la wiki interna (ficticio)',
      'Mejora de accesibilidad de ejemplo',
    ],
    'workplace.workItemTitle': [
      'Mejorar el texto del error de inicio de sesión',
      'Revisar la ordenación de la tabla de ejemplo',
      'Ordenar la presentación del estado de las notificaciones',
    ],
    'workplace.labelName': [
      'Textos',
      'Accesibilidad',
      'Backlog',
      'Pendiente de revisar',
    ],
    'workplace.milestoneTitle': [
      'Hito de la primera revisión',
      'Pantalla de ejemplo terminada',
      'Comprobación de regresiones',
    ],
    'workplace.sprintName': ['Sprint {n}'],
    'workplace.commentBody': [
      'Dejo mis comentarios tras revisar la pantalla de ejemplo.',
      'Por favor, revise el texto antes de la siguiente tarea.',
    ],
    'workplace.merchantName': [
      'Restaurante Flor Silvestre (ficticio)',
      'Bar de tapas del Callejón (ficticio)',
      'Papelería Luzaral (ficticio)',
    ],
    'workplace.accountName': [
      'Comidas (ejemplo)',
      'Transporte (ejemplo)',
      'Reuniones (ejemplo)',
      'Material (ejemplo)',
      'Viajes (ejemplo)',
      'Otros (ejemplo)',
    ],
    'workplace.rejectReasonText': [
      'Falta el recibo de ejemplo',
      'Hay que revisar la clasificación del concepto',
      'Hay que revisar el límite de la política de ejemplo',
    ],

    // brokerage
    'brokerage.projectTitle': [
      'Creación de un portal de clientes de ejemplo',
      'Renovación ficticia de una pantalla de servicio',
      'Creación de una pantalla de reservas de ejemplo',
    ],
    'brokerage.serviceCategory': [
      'Interfaz web',
      'Interfaz de aplicación',
      'Diseño de espacios de trabajo',
      'Servicios a domicilio',
    ],
    'brokerage.providerName': [
      'Estudio Desván del Código (ficticio)',
      'Taller de interfaces Luzaral (ficticio)',
      'Taller del hogar Riberazul (ficticio)',
    ],
    'brokerage.providerHeadline': [
      'Colaborador ficticio que muestra pantallas de ejemplo y registros de trabajo',
      'Perfil de ejemplo para revisar el alcance de un proyecto ficticio',
    ],
    'brokerage.skillTag': [
      'Dart',
      'Planificación de interfaces',
      'Organización de datos',
      'Redacción de textos',
    ],
    'brokerage.proposalMessage': [
      'He preparado el alcance y los puntos de control del calendario para el ejemplo.',
      'Propongo puntos de control para las fases del proyecto ficticio.',
    ],
    'brokerage.portfolioTitle': [
      'Ejemplo ficticio de portal de clientes',
      'Registro de ejemplo de una pantalla de reservas',
      'Mejora ficticia de una tabla de trabajo',
    ],
    'brokerage.milestoneLabel': [
      'Revisión del alcance',
      'Revisión del borrador de pantallas',
      'Revisión de una función de ejemplo',
      'Registro de la entrega',
    ],
    'brokerage.homeServiceName': [
      'Limpieza del aire acondicionado (ejemplo)',
      'Mudanza pequeña (ejemplo)',
      'Revisión de un grifo (ejemplo)',
      'Clase de instrumento para principiantes (ejemplo)',
    ],
    'brokerage.requestAnswer': [
      'Me gustaría confirmar el alcance antes de la visita.',
      'El horario de ejemplo es una mañana de fin de semana.',
    ],
    'brokerage.regionDong': [
      'Ciudad ficticia, barrio de Luzaral',
      'Ciudad ficticia, barrio de Riberazul',
      'Ciudad ficticia, barrio de Jaramar',
    ],
    'brokerage.reviewText': [
      'He revisado el registro de trabajo de ejemplo y las instrucciones.',
      'Las instrucciones del horario de ejemplo eran fáciles de seguir.',
    ],
    'brokerage.creditLabel': [
      'Crédito por envío de presupuesto (ejemplo)',
      'Crédito de reembolso por presupuesto no visto (ejemplo)',
      'Crédito de recarga (ejemplo)',
    ],
    'brokerage.advisorTitle': [
      'Especialista fiscal ficticio',
      'Especialista jurídico ficticio',
      'Especialista laboral ficticio',
    ],
    'brokerage.consultTopic': [
      'Explicación de terminología de ejemplo',
      'Lista de comprobación previa a la consulta de ejemplo',
      'Explicación de una lista de documentos de ejemplo',
    ],
    'brokerage.qnaQuestion': [
      '¿Qué significa este término del sistema? (pregunta ficticia)',
      '¿Qué campos aparecen en un registro de consulta? (pregunta ficticia)',
    ],
    // Every text starts with the general-information prefix of the language
    // (`test/language_safety/es.dart`) and promises no result.
    'brokerage.qnaAnswerGeneric': [
      'Información general: ejemplo. Un resumen del sistema puede enumerar términos, ámbito y documentos. No contiene ningún juicio sobre un caso particular.',
      'Información general: ejemplo. Un registro de consulta separa las preguntas de los materiales de referencia. No se indica ningún resultado concreto ni ninguna línea de actuación.',
    ],
    'brokerage.consultNoteGeneric': [
      'Información general: nota de ejemplo. Se presentó el tema de la pregunta y los términos del sistema. La lista de documentos consta de elementos explicativos ficticios.',
      'Información general: nota de ejemplo. Se revisó el formato del registro de consulta. No hay ninguna conclusión ni orientación sobre un caso particular.',
    ],
    'brokerage.officeName': [
      'Oficina de atención Luzaral (ficticio)',
      'Oficina de registros Riberazul (ficticio)',
    ],
    'brokerage.serviceTypeName': [
      'Limpieza',
      'Mudanzas',
      'Reparaciones',
      'Clases',
    ],

    // logistics
    'logistics.zoneName': [
      'Zona 1 Solarroyo (ficticio)',
      'Zona 2 Solarroyo (ficticio)',
      'Zona Riberazul (ficticio)',
    ],
    'logistics.hubName': [
      'Centro de distribución Luzaral (ficticio)',
      'Centro de distribución Riberazul (ficticio)',
    ],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // The shape is the Spanish plate (four digits, a space, three letters),
    // with `●●` hiding its last two letters.
    'logistics.vehiclePlate': ['{n}{m} B●●'],
    'logistics.deliveryNote': [
      'No dejar en la puerta; entregar en mano.',
      'Por favor, llame al portero automático del portal.',
      'Por favor, consulte en conserjería.',
    ],
    'logistics.exceptionDetail': [
      'Nadie abrió la puerta; se dejó un aviso.',
      'El código del portal no funcionó.',
      'La caja llegó abollada; se tomaron fotos.',
      'El destinatario pidió la entrega para mañana.',
      'La dirección no indica piso ni puerta.',
    ],
    'logistics.entranceHint': [
      'Portal n.º ••••; llamar a conserjería',
      'Usar el portero automático; no se muestra ningún código',
    ],
    'logistics.scanEvent': [
      'Llegada al centro de distribución',
      'Carga para transporte troncal',
      'En reparto',
      'Entregado',
      'Entrega no realizada',
    ],
    'logistics.carrierLabel': [
      'Transportista de ejemplo A (ficticio)',
      'Transportista de ejemplo B (ficticio)',
      'Transportista de mercancías de ejemplo C (ficticio)',
    ],
    'logistics.freightType': [
      'Embalaje',
      'Suministros alimentarios',
      'Materiales de construcción',
      'Componentes electrónicos',
      'Artículos para el hogar',
    ],
    'logistics.routeSummary': [
      'Zona ficticia Luzaral → zona Riberazul',
      'Zona ficticia Jaramar → zona Solarroyo',
    ],
    'logistics.fareItem': [
      'Tarifa base (ejemplo)',
      'Suplemento por plataforma elevadora (ejemplo)',
      'Manipulación manual (ejemplo)',
      'Tiempo de espera (ejemplo)',
    ],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': [
      'Caja de cartón pequeña',
      'Cinta de embalar de 48 mm',
      'Toallas de algodón, 3 unidades',
      'Arroz integral, 2 kg',
    ],
    'logistics.ownerLabel': [
      'Cargador A (ficticio)',
      'Cargador B (ficticio)',
      'Cargador C (ficticio)',
    ],

    // hospitality
    'hospitality.propertyName': [
      'Refugio Pinar Alto (ficticio)',
      'Hotel de descanso Riberazul (ficticio)',
      'Pequeño hostal Jaramar (ficticio)',
    ],
    'hospitality.siteName': [
      'Parcela Brisa del Pinar A (ficticio)',
      'Parcela Aroma del Pinar B (ficticio)',
      'Parcela Piña del Pinar C (ficticio)',
    ],
    'hospitality.amenity': [
      'Zona de barbacoa privada',
      'Duchas compartidas',
      'Wifi',
    ],
    'hospitality.stayOption': [
      'Kit de barbacoa (ejemplo)',
      'Haz de leña (ejemplo)',
      'Entrada anticipada (ejemplo)',
    ],
    'hospitality.seasonName': [
      'Temporada media',
      'Temporada alta de festivos (ejemplo)',
      'Temporada de ofertas entre semana (ejemplo)',
    ],
    'hospitality.ratePlan': [
      'Tarifa estándar de ejemplo',
      'Tarifa de ejemplo con desayuno',
      'Tarifa de ejemplo entre semana',
    ],
    'hospitality.houseRule': [
      'Por favor, guarde silencio en las zonas comunes por la noche.',
      'Por favor, revise la lista de salida de ejemplo.',
    ],
    'hospitality.bbqRule': [
      'La barbacoa está disponible de 17:00 a 21:00.',
      'Por favor, reserve la barbacoa en recepción al llegar.',
      'Se facilitan carbón y parrilla en cada parcela.',
      'Por favor, apague el fuego por completo antes de marcharse.',
      'No se permite hacer barbacoa en la terraza de las habitaciones.',
    ],
    'hospitality.wifiHint': [
      'El nombre de la red y la contraseña están en la tarjeta junto a la puerta.',
      'Por favor, pida en recepción la contraseña de la red de huéspedes.',
      'La red de huéspedes llega a las habitaciones y al salón.',
      'Si la señal se corta después de las 22:00, vuelva a conectarse.',
      'La contraseña cambia cada lunes.',
    ],
    'hospitality.reviewSnippet': [
      'Las instrucciones de ejemplo de la habitación se leían con facilidad.',
      'Las instrucciones del alojamiento ficticio están bien organizadas.',
    ],
    'hospitality.hkCheckItem': [
      'Cambiar la ropa de cama',
      'Limpiar el baño',
      'Revisar los artículos de acogida',
      'Revisar el minibar',
    ],
    'hospitality.maintenanceIssue': [
      'Revisión de una fuga en el baño (ejemplo)',
      'Solicitud de revisión de la iluminación (ejemplo)',
      'Revisión del panel de la calefacción (ejemplo)',
      'Revisión de un mueble dañado (ejemplo)',
    ],
    'hospitality.lostItemName': [
      'Paraguas azul',
      'Bufanda gris',
      'Un libro',
      'Botella de agua',
    ],
    'hospitality.specialRequest': [
      'Planta alta, habitación de no fumadores (ejemplo)',
      'Solicitud de almohada adicional (ejemplo)',
      'Solicitud de habitación tranquila (ejemplo)',
    ],
    'hospitality.menuItem': [
      'Menú con sopa de algas',
      'Pasta con verduras',
      'Yogur con fruta',
      'Té caliente',
    ],
    'hospitality.menuOption': [
      'Menos arroz',
      'Arroz normal',
      'Guarnición adicional (ejemplo)',
      'Sin hielo',
    ],
    'hospitality.amenityName': [
      'Toalla',
      'Agua',
      'Cepillo de dientes',
      'Almohada',
    ],
    'hospitality.localSpot': [
      'Casa de sopas matinal (ficticio)',
      'Cafetería del Callejón (ficticio)',
      'Senda Luzaral (ficticio)',
    ],
    'hospitality.conciergeReply': [
      'Las instrucciones del alojamiento ficticio aparecen en los detalles de la estancia.',
      'Hemos anotado la solicitud en el registro de ejemplo.',
      'Los lugares cercanos son todos lugares de demostración ficticios.',
    ],
    'hospitality.folioItem': [
      'Alojamiento (ejemplo)',
      'Servicio de habitaciones (ejemplo)',
      'Opción adicional (ejemplo)',
    ],
  },
  // The texts of Spanish that read like the English ones on purpose: the names
  // of a currency, countries, and cities that are spelled alike, acronyms and
  // file formats, loanwords that Spanish teams and studios keep in English
  // (`Backlog`, `Sprint`, `Reformer`), and words that both languages spell
  // alike (`Tricolor`, `Monitor`, `Variable`, `Yoga`). The language coverage
  // gate reads this list.
  allowSameAsEnglish: <String, List<String>>{
    'fx.currencyName.EUR': ['Euro'],
    // The names of the countries are spelled the same.
    'remit.countryName.VN': ['Vietnam'],
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.CN': ['China'],
    'vet.coatColor': ['Tricolor'],
    // Names of cities that Spanish spells as English does.
    'travel_wallet.cityName': ['Osaka', 'Bangkok'],
    // The name of a Pilates apparatus and of a discipline.
    'fitness.classCategoryLabel': ['Reformer', 'Yoga'],
    'fitness.equipment': ['Reformer'],
    // Acronyms and file formats of the exam questions, and the words
    // `variable` and `monitor`, which are the same in both languages.
    'exam_prep.unitName': ['Variables'],
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'HTTP', 'Variable'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF', 'Monitor'],
    // The name of a programming language.
    'brokerage.skillTag': ['Dart'],
    // Agile vocabulary that Spanish teams keep in English.
    'workplace.labelName': ['Backlog'],
    'workplace.sprintName': ['Sprint {n}'],
    // The clinic data: the units of a strength, which follow a no-break space.
    'clinic.drugForms.unit': ['*'],
  },
);
