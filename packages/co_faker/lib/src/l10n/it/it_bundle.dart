import '../co_l10n_bundle.dart';

/// Italian domain text: the Italian counterpart of every English key, with the
/// same number of texts in the same order, so that one seed picks the same
/// record in English, Korean, and Italian. See [CoL10nBundle].
///
/// The conventions of the language are in `docs/languages/it.md`, and the ones
/// that a template has to keep are these:
///
/// - the register is `Lei`; a notice or an instruction that says nobody in
///   particular uses `si prega di` and the infinitive;
/// - a fictional name ends with `(di fantasia)` and a sample label with
///   `(esempio)`, and nothing else marks a text as fictional;
/// - the apostrophe is `’`, a quotation is `«…»`, a unit follows its number
///   after a space (`500 g`), and `%` follows its number (`20%`);
/// - a template that a value fills never puts an article, or a preposition
///   that contracts with it (`del`, `al`, `nel`, `dell’`), right before the
///   value, because the gender, the number, and the first letter of the value
///   decide them.
const CoL10nBundle itBundle = CoL10nBundle(
  language: 'it',
  texts: <String, List<String>>{
    // common
    // The first letter of a given name, as English masks it.
    'common.maskedName': ['{initial}***'],
    'common.taxonomyChild': ['{root} · sottotema {n}'],

    // fx
    'fx.currencyName.USD': ['Dollaro statunitense'],
    'fx.currencyName.JPY': ['Yen giapponese'],
    'fx.currencyName.EUR': ['Euro'],
    'fx.currencyName.CNY': ['Yuan cinese'],
    'fx.currencyName.THB': ['Baht thailandese'],
    'fx.currencyName.VND': ['Dong vietnamita'],
    'fx.currencyName.PHP': ['Peso filippino'],
    'fx.currencyName.NPR': ['Rupia nepalese'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      'Ufficio cambio demo, aeroporto T1',
      'Ufficio cambio demo, Aurelvia',
      'Ufficio cambio demo, aeroporto T2',
      'Ufficio cambio demo, Rivosereno',
      'Ufficio cambio demo, Fraxinia',
    ],
    'fx.couponName': [
      'Sconto dell’80% sul margine USD (esempio)',
      'Sconto del 70% sul margine JPY (esempio)',
      'Sconto sul primo cambio (esempio)',
    ],
    'fx.tierName': ['Bronzo', 'Argento', 'Oro'],

    // remit
    'remit.countryName.VN': ['Vietnam'],
    'remit.countryName.PH': ['Filippine'],
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.US': ['Stati Uniti'],
    'remit.countryName.CN': ['Cina'],
    'remit.bankName': ['Banca partner Lumivale (di fantasia)'],
    'remit.flagRule': [
      'Bonifico di importo elevato (regola demo)',
      'Verifica di documenti aggiuntivi (regola demo)',
      'Verifica di richieste ripetute (regola demo)',
    ],

    // vet
    'vet.petName': ['Orzo', 'Farfalla', 'Tofu', 'Fagiolo', 'Nuvola'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['Bichon maltese', 'Barboncino', 'Cane meticcio'],
    'vet.breed.cat': ['Europeo a pelo corto', 'Gatto meticcio'],
    'vet.breed.small_mammal': ['Coniglio', 'Criceto'],
    'vet.breed.bird': ['Piccolo pappagallo'],
    'vet.breed.reptile': ['Tartaruga di terra'],
    'vet.coatColor': ['Bianco', 'Marrone', 'Nero', 'Tricolore', 'Grigio'],
    'vet.vaccineName': [
      'Vaccino combinato (esempio)',
      'Vaccinazione antirabbica (esempio)',
      'Vaccino combinato felino (esempio)',
    ],
    'vet.preventiveProduct': [
      'Esempio di prodotto contro la filariosi cardiopolmonare (di fantasia)',
      'Esempio di prodotto contro i parassiti esterni (di fantasia)',
    ],
    'vet.vetDiagnosis': [
      'Osservazione cutanea (esempio)',
      'Osservazione digestiva (esempio)',
      'Osservazione dello stato di salute di routine (esempio)',
    ],
    'vet.vetDrug': [
      'Esempio di prodotto per la cura della pelle (di fantasia)',
      'Esempio di prodotto per la cura dell’apparato digerente (di fantasia)',
      'Esempio di prodotto per la cura degli occhi (di fantasia)',
    ],
    'vet.clinicRoom': [
      'Ambulatorio veterinario 1',
      'Ambulatorio veterinario 2',
      'Sala vaccinazioni',
    ],

    // grocery
    'grocery.originRegion': [
      'Zona di coltivazione Aurelvia (di fantasia)',
      'Zona di coltivazione Rivosereno (di fantasia)',
      'Zona di coltivazione Pianalba (di fantasia)',
    ],
    'grocery.harvestNote': [
      'Le date di raccolta e di confezionamento sono solo a titolo di esempio.',
      'Il testo sulla freschezza descrive un prodotto di fantasia.',
    ],
    'grocery.deliveryZone': [
      'Aurelvia, zona A (demo)',
      'Rivosereno, zona B (demo)',
      'Pianalba, zona C (demo)',
    ],
    'grocery.slotLabel': ['Alba 06:00–07:00', 'Sera 18:00–20:00'],
    'grocery.substitutionNote': [
      'Esempio di sostituzione con un prodotto di peso simile.',
      'Esempio di rimborso senza sostituzione.',
    ],
    'grocery.doorNote': [
      'Si prega di suonare al citofono dell’ingresso comune.',
      'Consegna a mano, senza lasciare il pacco davanti alla porta.',
    ],
    'grocery.categoryName': [
      'Frutta',
      'Verdura',
      'Piatti pronti',
      'Cereali',
      'Carne',
      'Pesce e frutti di mare',
      'Latticini',
    ],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': [
      'Fragole',
      'Spinaci',
      'Ravioli fatti a mano',
      'Riso integrale',
      'Filetto di pollo',
      'Sgombro surgelato',
      'Latte',
    ],
    'catalog.groceryUnit': [
      '500 g',
      '200 g',
      '1 kg',
      '2 kg',
      '500 g',
      '600 g',
      '1 L',
    ],
    'catalog.commerceName': [
      'Auricolari senza fili',
      'Scatola portaoggetti pieghevole',
      'Set di asciugamani in cotone',
      'Tazza in ceramica',
      'Snack ai cereali',
    ],
    'catalog.commerceUnit': [
      '1 paio',
      '1 scatola',
      '3 pezzi',
      '1 pezzo',
      '200 g',
    ],

    // booking
    'booking.cancelReason': [
      'Cambio di programma (esempio)',
      'Scelto un altro orario (esempio)',
      'Motivo personale (esempio)',
    ],

    // dental
    'dental.dentalProcedure': [
      'Detartrasi',
      'Esempio di terapia canalare',
      'Esempio di otturazione in resina',
      'Esempio di pianificazione della corona',
    ],
    'dental.dentalMaterial': [
      'Resina composita (esempio)',
      'Zirconia (esempio)',
      'Ceramica (esempio)',
    ],
    'dental.chairName': [
      'Poltrona odontoiatrica 1',
      'Poltrona odontoiatrica 2',
      'Poltrona odontoiatrica 3',
    ],
    'dental.hygieneNote': [
      'Esempio di annotazione sulla spiegazione del corretto spazzolamento.',
      'Esempio di annotazione sull’osservazione dell’igiene orale.',
    ],

    // homecare
    'homecare.careGrade': [
      'Livello di assistenza 1',
      'Livello di assistenza 2',
      'Livello di assistenza 3',
      'Livello di assistenza 4',
      'Livello di assistenza 5',
      'Livello di supporto cognitivo',
    ],
    'homecare.careTaskLabel': [
      'Aiuto al pasto',
      'Controllo dell’assunzione dei farmaci',
      'Aiuto per l’igiene personale',
      'Aiuto negli spostamenti',
      'Aiuto ai servizi igienici',
      'Compagnia e conversazione',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      'Locale di noodles nel vicolo (di fantasia)',
      'Minimarket della stazione (di fantasia)',
      'Locanda del viaggiatore (di fantasia)',
    ],
    'travel_wallet.cityName': ['Osaka', 'Tokyo', 'Bangkok', 'Hanoi'],
    'travel_wallet.cardAlias': [
      'Carta viaggio per le gite (di fantasia)',
      'Carta del budget di viaggio (di fantasia)',
    ],
    'travel_wallet.tripName': [
      'Quattro giorni a Osaka',
      'Fine settimana a Bangkok',
      'Passeggiata per Hanoi',
    ],

    // b2b_trade
    'b2b_trade.buyerCompany': [
      'Caffè Terzovento (di fantasia)',
      'Forno Lunagrano (di fantasia)',
      'Alimentari Pinelume (di fantasia)',
    ],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      'Bicchieri di carta da 350 ml, 1.000 pezzi',
      'Patate surgelate, 10 kg',
      'Sacchetti di carta, 100 pezzi',
      'Salviette igieniche non profumate, 20 pezzi',
    ],
    'b2b_trade.quoteTitle': [
      'Preventivo mensile per imballaggi (di fantasia)',
      'Preventivo settimanale per generi alimentari (di fantasia)',
      'Preventivo per articoli igienici (di fantasia)',
    ],
    'b2b_trade.holdReason': [
      'Verifica del credito disponibile (esempio)',
      'Verifica della data di consegna (esempio)',
      'Verifica delle specifiche dell’articolo (esempio)',
    ],

    // group_deal
    'group_deal.dealTitle': [
      'Acquisto di gruppo di agrumi invernali',
      'Acquisto di gruppo di auricolari senza fili',
      'Acquisto di gruppo di asciugamani in cotone',
    ],
    'group_deal.optionLabel': [
      'Formato standard',
      'Confezione regalo',
      'Colore standard',
    ],
    'group_deal.rewardLabel': [
      'Bollino di partecipazione',
      'Punti premio dimostrativi',
      'Vantaggio sulla spedizione',
    ],
    'group_deal.benefitTitle': [
      'Esempio di buono per spedizione gratuita',
      'Esempio di buono per il prossimo acquisto di gruppo',
    ],
    'group_deal.settleNote': [
      'Esempio di totale delle adesioni andate a buon fine.',
      'Esempio di totale escluse le adesioni annullate.',
    ],

    // fitness
    // A class name from the category label and the level label of the same
    // record: the level label stays after the word `livello`, so that it needs
    // no agreement with the category.
    'fitness.className': ['{category}, livello {level}'],
    'fitness.classCategoryLabel': ['Tappetino', 'Reformer', 'Sedia', 'Yoga'],
    'fitness.classLevelLabel': ['principiante', 'intermedio', 'avanzato'],
    'fitness.equipment': ['Tappetino', 'Reformer', 'Sedia', 'Blocco per yoga'],
    'fitness.studioRoom': [
      'Sala Pilates tappetino',
      'Sala Pilates Reformer',
      'Sala Pilates sedia',
      'Sala yoga',
    ],
    'fitness.instructorSpecialty': [
      'Corsi di tappetino',
      'Corsi di Reformer',
      'Corsi di yoga',
    ],
    'fitness.passName': [
      'Carnet da 10 lezioni di tappetino (esempio)',
      'Carnet da 20 lezioni di Reformer (esempio)',
      'Abbonamento mensile (esempio)',
    ],
    'fitness.cancelReason': [
      'Cambio di programma',
      'Cambio di orario della lezione',
    ],
    'fitness.noShowNote': [
      'Esempio di registrazione senza conferma di presenza.',
      'Esempio di assenza segnata dopo l’inizio della lezione.',
    ],

    // space_rental
    'space_rental.spaceName': [
      'Sala feste Ore Quattro (di fantasia)',
      'Sala studio Aurelvia (di fantasia)',
      'Sala prove Rivosereno (di fantasia)',
    ],
    'space_rental.districtName': [
      'Città di fantasia, quartiere Aurelvia',
      'Città di fantasia, quartiere Rivosereno',
      'Città di fantasia, quartiere Fraxinia',
    ],
    'space_rental.amenity': ['Wi-Fi', 'Lavagna bianca', 'Distributore d’acqua'],
    'space_rental.equipmentOption': [
      'Proiettore (esempio)',
      'Impianto audio (esempio)',
      'Un posto auto (esempio)',
    ],
    'space_rental.houseRule': [
      'Si prega di riporre l’attrezzatura dopo l’uso.',
      'Si prega di rispettare l’orario prenotato.',
    ],
    'space_rental.bookingPurpose': [
      'Incontro di studio',
      'Incontro tra amici',
      'Prove della band',
    ],
    'space_rental.guestMessage': [
      'Potrei sapere come si usa l’attrezzatura?',
      'Potrebbe inviarmi le istruzioni per l’accesso?',
    ],
    'space_rental.hostReply': [
      'Si prega di consultare la guida all’attrezzatura nella pagina della prenotazione.',
      'Le istruzioni per l’accesso sono indicate nei dettagli della prenotazione.',
    ],

    // dining
    'dining.restaurantName': [
      'Casa dei noodles alla perilla (di fantasia)',
      'Ristorante della pasta nel vicolo (di fantasia)',
      'Sala da tè Aurelvia (di fantasia)',
    ],
    'dining.menuName': [
      'Noodles alla perilla',
      'Pasta al pomodoro',
      'Ciotola di riso con verdure',
      'Tè caldo',
    ],
    // A table is `Tavolo per 1`, `Tavolo per 4`: no plural to agree.
    'dining.partyLabel': ['Tavolo per {n}'],
    'dining.noShowNote': [
      'Esempio di registrazione in coda senza conferma di arrivo.',
      'Esempio di assenza dopo l’orario comunicato.',
    ],
    'dining.loyaltyBenefit': [
      'Bevanda alla quinta visita (esempio)',
      'Buono dessert per i clienti abituali (esempio)',
    ],
    'dining.districtName': [
      'Città di fantasia, quartiere Aurelvia',
      'Città di fantasia, quartiere Rivosereno',
    ],

    // daycare
    'daycare.childName': ['Sofia', 'Leonardo', 'Aurora', 'Mattia', 'Giulia'],
    'daycare.className': ['Sezione Sole', 'Sezione Luna', 'Sezione Stella'],
    'daycare.ageLabel': ['1 anno', '2 anni', '3 anni', '4 anni', '5 anni'],
    // {name1} is the first given name drawn: no article and no preposition
    // stand before it, because `del` or `dell’` would depend on the name.
    'daycare.guardianLabel': ['{name1} (genitore o tutore)'],
    // The noun is the same for a woman and a man, and the name is drawn
    // without a sex.
    'daycare.teacherName': ['Insegnante {name1}'],
    'daycare.toiletNote': [
      'Un passaggio in bagno registrato (esempio)',
      'Due passaggi in bagno registrati (esempio)',
      'Nessuna registrazione (esempio)',
    ],
    'daycare.mealMenu': [
      'Riso integrale e stufato di verdure',
      'Zuppa di tofu e riso',
      'Riso saltato con verdure',
    ],
    'daycare.snackMenu': [
      'Spicchi di pera',
      'Patata dolce al vapore',
      'Yogurt naturale',
    ],
    'daycare.allergenLabel': [
      'Latte',
      'Uova',
      'Soia',
      'Grano',
      'Nessuna segnalata (esempio)',
    ],
    'daycare.activityTitle': [
      'Giochi sulla neve d’inverno',
      'Costruzione di casette di carta',
      'Gioco con i blocchi colorati',
    ],
    'daycare.albumCaption': [
      'Illustrazione di fantasia di bambini che costruiscono insieme con i blocchi',
      'Illustrazione di fantasia di giochi invernali',
    ],
    'daycare.drugLabel': [
      'Sciroppo contro la febbre (di fantasia)',
      'Sciroppo contro la tosse (di fantasia)',
      'Preparato idratante per uso cutaneo (di fantasia)',
    ],
    'daycare.dosageLabel': [
      'Esempio redatto dal genitore o tutore: 2 mL',
      'Esempio redatto dal genitore o tutore: 3 mL',
      'Esempio redatto dal genitore o tutore: piccola quantità',
    ],
    'daycare.noticeTitle': [
      'Avviso sui giochi invernali (esempio)',
      'Avviso di cambio menu (esempio)',
      'Avviso di controllo della sicurezza (esempio)',
    ],

    // exam_prep
    'exam_prep.subjectName': [
      'Basi di dati',
      'Basi di dati',
      'Reti',
      'Reti',
      'Reti',
      'Fondamenti di programmazione',
      'Fondamenti di programmazione',
      'Sicurezza informatica',
      'Sicurezza informatica',
    ],
    'exam_prep.unitName': [
      'Modellazione dei dati',
      'Fondamenti di SQL',
      'Livello di trasporto',
      'Instradamento',
      'Livello applicativo',
      'Variabili',
      'Strutture dati',
      'Fondamenti di crittografia',
      'Controllo degli accessi',
    ],
    'exam_prep.questionStem': [
      'Quale chiave distingue le righe di una tabella?',
      'Quale clausola SQL seleziona le righe in base a una condizione?',
      'Quale protocollo di trasporto gestisce l’ordinamento e la ritrasmissione?',
      'Quale dispositivo sceglie il percorso successivo di un pacchetto?',
      'Quale protocollo esprime le richieste e le risposte web?',
      'Che cosa memorizza un valore con un nome in un programma?',
      'Quale struttura rimuove per primo l’ultimo valore inserito?',
      'Che cosa calcola un’impronta di lunghezza fissa a partire da un input?',
      'Quale principio concede solo i permessi necessari per un’attività?',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      'Chiave primaria',
      'WHERE',
      'TCP',
      'Router',
      'HTTP',
      'Variabile',
      'Pila',
      'Funzione di hash',
      'Privilegio minimo',
    ],
    'exam_prep.wrongChoice1': [
      'Tipo di carattere',
      'Tipo di carattere',
      'JPEG',
      'Altoparlante',
      'PNG',
      'Bordo',
      'Coda FIFO',
      'Scelta del tipo di carattere',
      'Accesso pubblico',
    ],
    'exam_prep.wrongChoice2': [
      'Colore di sfondo',
      'Margine',
      'CSS',
      'Tastiera',
      'MP3',
      'Margine di pagina',
      'Immagine',
      'Zoom dello schermo',
      'Password condivisa',
    ],
    'exam_prep.wrongChoice3': [
      'Larghezza dello schermo',
      'Icona',
      'SVG',
      'Schermo',
      'TTF',
      'Immagine di sfondo',
      'File audio',
      'Riempimento dello sfondo',
      'Controlli saltati',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    // The choice is written in the case of the list (`Chiave primaria`), as the
    // term that opens a definition, because a test of the package compares the
    // explanation and the choice with the same case.
    'exam_prep.explanation': [
      'Chiave primaria: identifica ogni riga di una tabella.',
      'WHERE: questa clausola esprime una condizione per selezionare le righe.',
      'TCP gestisce l’ordinamento e la ritrasmissione di un flusso di byte.',
      'Router: sceglie il percorso successivo in base all’indirizzo di destinazione.',
      'HTTP esprime le richieste e le risposte web.',
      'Variabile: consente a un programma di fare riferimento a un valore tramite il suo nome.',
      'Pila: rimuove per primo l’ultimo valore inserito.',
      'Funzione di hash: calcola un’impronta di lunghezza fissa a partire da un input.',
      'Privilegio minimo: concede solo i permessi necessari per un’attività.',
    ],
    'exam_prep.examPaperTitle': [
      'Simulazione d’esame 1 (di fantasia)',
      'Simulazione d’esame 2 (di fantasia)',
      'Verifica di fine unità (di fantasia)',
    ],
    'exam_prep.studyTaskTitle': [
      'Risolvere dieci domande sul livello di trasporto',
      'Rivedere gli errori sul controllo degli accessi',
      'Verificare i fondamenti di SQL',
    ],
    'exam_prep.taxonomyName': [
      'Basi di dati',
      'Reti',
      'Fondamenti di programmazione',
      'Sicurezza informatica',
    ],

    // hrd
    'hrd.departmentName': [
      'Vendite',
      'Produzione',
      'Ricerca',
      'Assistenza clienti',
      'Amministrazione',
      'Logistica',
    ],
    'hrd.jobTitle': ['Collaboratore', 'Responsabile', 'Coordinatore di team'],
    'hrd.courseTitle': [
      'Gestire i dati personali nel 2026 (di fantasia)',
      'Lavorare in sicurezza insieme (di fantasia)',
      'Organizzare i registri di lavoro (di fantasia)',
    ],
    'hrd.courseKind': ['Obbligatorio', 'Professionale', 'Leadership'],
    'hrd.lessonTitle': [
      'Comprendere i principi di base',
      'Esaminare esempi di lavoro',
      'Verificare i registri',
    ],
    'hrd.chapterTitle': ['Introduzione', 'Esame di esempi', 'Riepilogo'],
    'hrd.nudgeTitle': [
      'Promemoria sulla scadenza della formazione (esempio)',
      'Promemoria sulla lezione non completata (esempio)',
    ],
    'hrd.exemptionReason': [
      'Attestato di completamento esterno (esempio)',
      'Verifica del periodo di congedo (esempio)',
      'Verifica di una formazione alternativa (esempio)',
    ],
    'hrd.classroomPlace': [
      'Aula formazione Aurelvia (di fantasia)',
      'Sala seminari Rivosereno (di fantasia)',
    ],

    // neighborhood
    'neighborhood.neighborhoodName': [
      'Quartiere Aurelvia (di fantasia)',
      'Quartiere Ginkgo (di fantasia)',
      'Quartiere Fraxinia (di fantasia)',
    ],
    'neighborhood.districtName': [
      'Città di fantasia, quartiere Rivosereno',
      'Città di fantasia, quartiere Pinelume',
    ],
    'neighborhood.nickname': [
      'FagiolinoAurelvia (di fantasia)',
      'StellaFraxinia (di fantasia)',
      'NuvolaDelVicolo (di fantasia)',
    ],
    'neighborhood.postTitle': [
      'Guanto blu trovato al parco giochi (esempio)',
      'Scopriamo insieme le passeggiate del quartiere (esempio)',
      'Regalo una piccola fioriera (esempio)',
    ],
    'neighborhood.postBody': [
      'Notizie di quartiere di fantasia. I dettagli sono in questo post.',
      'Esempio di post per i vicini; non sono inclusi numeri di telefono né indirizzi reali.',
    ],
    'neighborhood.commentBody': [
      'Grazie per aver condiviso la novità.',
      'Controllo e rispondo nel post.',
      'Posso controllare in serata.',
    ],
    'neighborhood.placeName': [
      'Panificio Aurelvia (di fantasia)',
      'Area di sosta del parco Rivosereno (di fantasia)',
      'Piccola biblioteca Fraxinia (di fantasia)',
    ],
    'neighborhood.openHours': ['08:00–21:00', '09:00–18:00', '10:00–20:00'],
    'neighborhood.bannedWord': [
      'pubblicità-esempio',
      'insulto-esempio',
      'parola-vietata-esempio',
    ],
    'neighborhood.keyword': [
      'guanto',
      'passeggiata',
      'condivisione',
      'notizie locali',
    ],

    // meetup
    'meetup.clubName': [
      'Corsa mattutina di Aurelvia (di fantasia)',
      'Gruppo di lettura di Rivosereno (di fantasia)',
      'Giochi da tavolo di Fraxinia (di fantasia)',
    ],
    'meetup.interestTag': [
      'Corsa',
      'Lettura',
      'Giochi da tavolo',
      'Fotografia',
      'Cucina',
      'Escursionismo',
    ],
    'meetup.clubIntro': [
      'Gruppo di fantasia che accoglie anche i vicini alla prima partecipazione.',
      'Gruppo di esempio per condividere piccole attività insieme.',
    ],
    'meetup.gatheringTitle': [
      'Incontro della terza settimana di gennaio (di fantasia)',
      'Chiacchierata sui libri nel fine settimana (di fantasia)',
      'Ritrovo per una passeggiata invernale (di fantasia)',
    ],
    'meetup.venueName': [
      'Ingresso del sentiero di Rivosereno (di fantasia)',
      'Sala incontri di Aurelvia (di fantasia)',
      'Area di sosta di Fraxinia (di fantasia)',
    ],
    'meetup.nickname': [
      'FagiolinoDellAlba (di fantasia)',
      'NuvolaDiLibri (di fantasia)',
      'PiccolaStella (di fantasia)',
    ],
    'meetup.duesItem': [
      'Quota di partecipazione all’incontro (esempio)',
      'Bevande in comune (esempio)',
      'Noleggio di attrezzatura in comune (esempio)',
    ],
    'meetup.joinAnswer': [
      'Vorrei partecipare alle attività da questo mese.',
      'Posso partecipare nelle mattine del fine settimana.',
    ],
    'meetup.ruleText': [
      'Si prega di rispettare il tempo di tutti.',
      'Si prega di conversare all’interno del gruppo senza pubblicare recapiti.',
      'Si prega di avvisare il gruppo in caso di disdetta.',
    ],
    'meetup.cadenceLabel': [
      'Ogni sabato alle 07:00',
      'Una domenica su due alle 10:00',
      'Il primo sabato del mese alle 14:00',
    ],

    // fandom
    // The two approved fictional creators of the fandom pack: Italian writes two
    // names of its own, never the Korean ones.
    'fandom.creatorName': ['Giardino della Clessidra', 'Venatura del Cielo'],
    'fandom.fanNickname': [
      'Stellina',
      'Germoglio',
      'Fagiolino lunare',
      'Goccia di luce',
    ],
    'fandom.benefitTitle': [
      'Esempio di immagine riservata ai membri',
      'Iscrizione simulata a un evento',
      'Anteprima anticipata di un filmato di fantasia',
    ],
    'fandom.postCaption': [
      'Illustrazione di fantasia di uno studio in inverno',
      'Esempio di post sulle ore di prova',
    ],
    'fandom.clipTitle': [
      'Prova di trenta secondi (di fantasia)',
      'Saluto dallo studio (di fantasia)',
      'Nota sonora d’inverno (di fantasia)',
    ],
    'fandom.letterBody': [
      'Mi è piaciuto il post di esempio di oggi e aspetto con piacere il prossimo aggiornamento.',
      'L’illustrazione dello studio d’inverno mi è sembrata calorosa. Un messaggio di incoraggiamento.',
    ],
    'fandom.eventTitle': [
      'Incontro invernale tra fan (di fantasia)',
      'Evento sulle storie dello studio (di fantasia)',
    ],
    'fandom.agendaTitle': [
      'Programma del piccolo teatro d’inverno (di fantasia)',
      'Conversazione in diretta di fantasia',
      'Calendario di uscita dei nuovi post',
    ],
    'fandom.venueLabel': [
      'Piccolo teatro d’inverno (di fantasia)',
      'Studio Aurelvia (di fantasia)',
      'Spazio online di esempio',
    ],

    // content
    'content.seriesTitle': [
      'L’isola postale del faro di carta (di fantasia)',
      'La piccola mappa dello stagno delle nuvole (di fantasia)',
      'Il giardino dell’orologio lento (di fantasia)',
    ],
    'content.penName': [
      'Fagiolo di Parole (di fantasia)',
      'Stella di Carta (di fantasia)',
      'Penna di Nuvola (di fantasia)',
    ],
    'content.synopsisLine': [
      'Personaggi di fantasia smistano lettere su una piccola isola.',
      'Una storia di fantasia su uno stagno disegnato che non compare sulla mappa.',
    ],
    'content.genreName': [
      'Fantasy',
      'Vita quotidiana',
      'Avventura',
      'Storie di scienza',
      'Saggio',
    ],
    'content.episodeTitle': [
      'La prima barchetta di carta (di fantasia)',
      'Un puntino sullo stagno (di fantasia)',
      'Un pomeriggio senza orologio (di fantasia)',
    ],
    'content.cutAltText': [
      'Illustrazione di un personaggio di fantasia che piega una barchetta di carta',
      'Illustrazione di due personaggi di fantasia accanto a uno stagno',
    ],
    'content.commentLine': [
      'La scena della barchetta di carta mi è rimasta nel cuore.',
      'Vorrei leggere il prossimo episodio di esempio.',
    ],
    'content.chapterParagraph': [
      'Nella cassetta della posta dell’isola giaceva un foglio bianco. Un bambino lo piegò fino a farne una piccola barca che somigliava allo stagno. Questo paragrafo è un esempio dimostrativo originale, di fantasia.',
      'Accanto all’orologio lento c’era una piccola fioriera. Invece di dare un nome alla pianta, due amici disegnarono le nuvole che avevano visto. Questo è un paragrafo di esempio originale, di fantasia.',
    ],
    'content.publisherName': [
      'Edizioni Faro di Carta (di fantasia)',
      'Edizioni Stagno delle Nuvole (di fantasia)',
    ],
    'content.audioTitle': [
      'Un pomeriggio a piegare barchette di carta (di fantasia)',
      'Note sonore di un piccolo stagno (di fantasia)',
    ],
    'content.newsletterName': [
      'Appunti settimanali del Faro di Carta (di fantasia)',
      'Piccole lettere dello Stagno delle Nuvole (di fantasia)',
    ],
    'content.articleHeadline': [
      'Organizzare gli appunti di ogni giorno in piccoli gruppi (di fantasia)',
      'Annotare i colori di una passeggiata invernale (di fantasia)',
    ],
    'content.topicName': [
      'Appunti quotidiani',
      'Passeggiate invernali',
      'Piccola scienza',
      'Abitudini di lettura',
    ],
    'content.genreTaxonomy': [
      'Fantasy',
      'Vita quotidiana',
      'Avventura',
      'Storie di scienza',
      'Saggio',
    ],
    'content.audioTaxonomy': ['Audiolibro', 'Podcast'],
    'content.topicTaxonomy': [
      'Appunti quotidiani',
      'Passeggiate invernali',
      'Piccola scienza',
      'Abitudini di lettura',
      'Osservazioni sulla vita quotidiana',
    ],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      'Controllo dello stato dell’invito al team',
      'Domanda sulle voci di una fattura di esempio',
      'Errore di esempio nell’esportazione in CSV',
      'Domanda sullo stato dell’integrazione',
      'Domanda su un pulsante di una schermata di esempio',
      'Domanda su dove trovare la guida',
    ],
    'helpdesk.ticketDescription': [
      'L’account di assistenza di fantasia mostra un invito in sospeso.',
      'Vorrei verificare le voci e il periodo della fattura di fantasia.',
      'Compare uno stato di errore quando si esportano in CSV i dati di esempio.',
      'Vorrei verificare la formulazione nella pagina di stato dell’integrazione di fantasia.',
      'La schermata di esempio resta invariata dopo aver premuto un pulsante.',
      'Dove posso trovare la pagina di guida dell’assistenza di fantasia?',
    ],
    'helpdesk.macroName': [
      'Conferma di ricezione di esempio',
      'Richiesta di ulteriori informazioni',
      'Comunicazione sullo stato di elaborazione',
    ],
    'helpdesk.helpArticleTitle': [
      'Guida di esempio agli inviti',
      'Come leggere una fattura di fantasia',
      'Esportare dati CSV di esempio',
    ],
    'helpdesk.csatComment': [
      'Ho letto la spiegazione.',
      'Le istruzioni di esempio erano facili da seguire.',
      'Ho altri dettagli da verificare.',
    ],
    // Same order as the draft categories in CoFakerHelpdesk. The agent speaks to
    // the customer with `Lei`.
    'helpdesk.draftBody': [
      'Controlli lo stato dell’invito nelle impostazioni dell’account. Questa bozza simulata dell’IA richiede la revisione di un operatore.',
      'Annoti insieme il metodo di accesso e l’errore di esempio. Questa bozza simulata dell’IA non modifica alcun account.',
      'Controlli il periodo e le voci della fattura di esempio. Questa bozza simulata dell’IA descrive prezzi di fantasia.',
      'Indichi il numero della fattura di esempio nella nota di assistenza. Questa bozza simulata dell’IA non è un vero avviso di pagamento.',
      'Controlli l’intervallo di date e il formato scelti per l’esportazione. Questa bozza simulata dell’IA registra un errore di esempio senza dati personali.',
      'Controlli i nomi delle colonne e lo stato del file nel CSV di esempio. Questa bozza simulata dell’IA richiede la revisione di un operatore.',
      'Annoti lo stato di integrazione di esempio e l’ora del controllo. Questa bozza simulata dell’IA non effettua chiamate esterne.',
      'Annoti la schermata e i passaggi per riprodurre il problema. Questa bozza simulata dell’IA non promette alcun risultato.',
    ],
    'helpdesk.topicName': ['Account', 'Fatturazione', 'Dati', 'Integrazione'],

    // campaign
    'campaign.brandName': [
      'Panificio Luce di Primavera (di fantasia)',
      'Libreria Luce Lunare (di fantasia)',
      'Caffè Giardino Verde (di fantasia)',
    ],
    'campaign.campaignTitle': [
      'Offerta invernale di esempio',
      'Novità di esempio per la prima visita',
      'Novità di esempio per il fine settimana',
    ],
    'campaign.offerCopy': [
      '(Pubblicità) Buono di esempio per un menu invernale di fantasia. Per non ricevere più messaggi, consulti le impostazioni demo.',
      '(Pubblicità) Offerta di esempio per un prodotto di fantasia. La disiscrizione è nelle impostazioni demo.',
    ],
    'campaign.couponTitle': [
      'Buono di esempio invernale del 20%',
      'Buono di esempio del 10% per la prima visita',
    ],
    'campaign.segmentName': [
      'Acquirenti di esempio degli ultimi 30 giorni',
      'Gruppo di esempio che ha dato il consenso',
      'Gruppo di esempio per le novità del fine settimana',
    ],
    'campaign.failReason': [
      'Numero del destinatario mancante (esempio)',
      'Nessun consenso al marketing (esempio)',
      'Nessun consenso all’invio notturno (esempio)',
    ],

    // workplace
    'workplace.department': [
      'Team front-end',
      'Team back-end',
      'Team design',
      'Assistenza clienti',
      'Risorse umane',
    ],
    'workplace.position': [
      'Collaboratore',
      'Responsabile',
      'Coordinatore di team',
    ],
    'workplace.workPlace': [
      'Sede Aurelvia (di fantasia)',
      'Centro operativo Rivosereno (di fantasia)',
      'Da remoto',
    ],
    'workplace.shiftName': [
      'Turno di giorno',
      'Turno del mattino',
      'Turno nel fine settimana',
    ],
    'workplace.approvalComment': [
      'Ho esaminato la registrazione di esempio allegata.',
      'Il motivo di esempio richiede un chiarimento.',
    ],
    'workplace.projectName': [
      'Rinnovo del portale clienti (di fantasia)',
      'Riordino della wiki interna (di fantasia)',
      'Esempio di miglioramento dell’accessibilità',
    ],
    'workplace.workItemTitle': [
      'Migliorare il testo dell’errore di accesso',
      'Verificare l’ordinamento della tabella di esempio',
      'Riordinare la visualizzazione dello stato delle notifiche',
    ],
    'workplace.labelName': [
      'Testi',
      'Accessibilità',
      'Backlog',
      'Da verificare',
    ],
    'workplace.milestoneTitle': [
      'Traguardo della prima revisione',
      'Schermata di esempio completata',
      'Verifica di non regressione',
    ],
    'workplace.sprintName': ['Sprint {n}'],
    'workplace.commentBody': [
      'Lascio un commento dopo aver controllato la schermata di esempio.',
      'Si prega di rivedere la formulazione prima della prossima attività.',
    ],
    'workplace.merchantName': [
      'Ristorante Fiori di Campo (di fantasia)',
      'Bar del vicolo (di fantasia)',
      'Cancelleria Aurelvia (di fantasia)',
    ],
    'workplace.accountName': [
      'Pasti (esempio)',
      'Trasporti (esempio)',
      'Riunioni (esempio)',
      'Materiali di consumo (esempio)',
      'Trasferte (esempio)',
      'Altro (esempio)',
    ],
    'workplace.rejectReasonText': [
      'Ricevuta di esempio mancante',
      'La classificazione della voce va verificata',
      'Il limite della politica aziendale di esempio va verificato',
    ],

    // brokerage
    'brokerage.projectTitle': [
      'Esempio di realizzazione di un portale clienti',
      'Rinnovo di fantasia di una schermata di servizio',
      'Esempio di realizzazione di una schermata di prenotazione',
    ],
    'brokerage.serviceCategory': [
      'Interfaccia web',
      'Interfaccia per app',
      'Design professionale',
      'Servizi a domicilio',
    ],
    'brokerage.providerName': [
      'Studio Soffitta del Codice (di fantasia)',
      'Laboratorio di interfacce Aurelvia (di fantasia)',
      'Laboratorio del quotidiano Rivosereno (di fantasia)',
    ],
    'brokerage.providerHeadline': [
      'Partner di fantasia che presenta schermate di esempio e registri dei lavori',
      'Profilo di esempio per esaminare l’ambito di un progetto di fantasia',
    ],
    'brokerage.skillTag': [
      'Dart',
      'Progettazione di interfacce',
      'Organizzazione dei dati',
      'Scrittura di testi',
    ],
    'brokerage.proposalMessage': [
      'Ho preparato l’ambito e i punti di controllo del calendario per l’esempio.',
      'Propongo punti di controllo per le fasi del progetto di fantasia.',
    ],
    'brokerage.portfolioTitle': [
      'Esempio di fantasia di portale clienti',
      'Scheda di esempio di una schermata di prenotazione',
      'Miglioramento di fantasia di una tabella di lavoro',
    ],
    'brokerage.milestoneLabel': [
      'Verifica dell’ambito',
      'Verifica della bozza della schermata',
      'Verifica di una funzione di esempio',
      'Verbale di consegna',
    ],
    'brokerage.homeServiceName': [
      'Pulizia del condizionatore (esempio)',
      'Piccolo trasloco (esempio)',
      'Controllo del rubinetto (esempio)',
      'Lezione di strumento musicale per principianti (esempio)',
    ],
    'brokerage.requestAnswer': [
      'Vorrei verificare l’ambito dei lavori prima di una visita.',
      'L’orario di esempio è una mattina del fine settimana.',
    ],
    'brokerage.regionDong': [
      'Città di fantasia, quartiere Aurelvia',
      'Città di fantasia, quartiere Rivosereno',
      'Città di fantasia, quartiere Fraxinia',
    ],
    'brokerage.reviewText': [
      'Ho esaminato la scheda dei lavori di esempio e le istruzioni.',
      'Le indicazioni di esempio sugli orari erano facili da seguire.',
    ],
    'brokerage.creditLabel': [
      'Credito per l’invio di un preventivo (esempio)',
      'Credito di rimborso per preventivo non visualizzato (esempio)',
      'Credito di ricarica (esempio)',
    ],
    'brokerage.advisorTitle': [
      'Consulente fiscale di fantasia',
      'Consulente legale di fantasia',
      'Consulente del lavoro di fantasia',
    ],
    'brokerage.consultTopic': [
      'Esempio di spiegazione della terminologia',
      'Esempio di elenco di controllo prima della consulenza',
      'Esempio di spiegazione di un elenco di documenti',
    ],
    'brokerage.qnaQuestion': [
      'Che cosa significa questo termine del sistema? (domanda di fantasia)',
      'Quali campi compaiono in una scheda di consulenza? (domanda di fantasia)',
    ],
    // Every text starts with the general-information prefix of the language
    // (`test/language_safety/it.dart`) and promises no result.
    'brokerage.qnaAnswerGeneric': [
      'Informazione generale di esempio. Una panoramica del sistema può elencare termini, ambito e documenti. Non contiene alcuna valutazione di un caso individuale.',
      'Informazione generale di esempio. Una scheda di consulenza distingue le domande dai materiali di riferimento. Non viene indicato alcun risultato specifico né alcuna linea di condotta.',
    ],
    'brokerage.consultNoteGeneric': [
      'Informazione generale, nota di esempio: presentati l’argomento della domanda e i termini del sistema. L’elenco dei documenti è composto da voci esplicative di fantasia.',
      'Informazione generale, nota di esempio: esaminato il formato della scheda di consulenza. Nessuna conclusione né consiglio su un caso individuale.',
    ],
    'brokerage.officeName': [
      'Studio di consulenza Aurelvia (di fantasia)',
      'Ufficio documentazione Rivosereno (di fantasia)',
    ],
    'brokerage.serviceTypeName': [
      'Pulizie',
      'Traslochi',
      'Riparazioni',
      'Lezioni',
    ],

    // logistics
    'logistics.zoneName': [
      'Zona 1 Pinelume (di fantasia)',
      'Zona 2 Pinelume (di fantasia)',
      'Zona Rivosereno (di fantasia)',
    ],
    'logistics.hubName': [
      'Centro di smistamento Aurelvia (di fantasia)',
      'Centro di smistamento Rivosereno (di fantasia)',
    ],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // The shape is the one of an Italian plate, two letters, the digits, and two
    // letters; the plate stays masked with `●●`.
    'logistics.vehiclePlate': ['AB {n}●●{m} CD'],
    'logistics.deliveryNote': [
      'Nessuna consegna incustodita; consegnare di persona.',
      'Si prega di suonare al citofono dell’ingresso comune.',
      'Si prega di rivolgersi alla portineria.',
    ],
    'logistics.entranceHint': [
      'Ingresso comune, codice ••••; chiamare la portineria',
      'Usare il pulsante di chiamata all’ingresso; nessun codice mostrato',
    ],
    'logistics.scanEvent': [
      'Arrivo al centro di smistamento',
      'Carico per il trasporto a lunga distanza',
      'In consegna',
      'Consegna completata',
      'Consegna non effettuata',
    ],
    'logistics.carrierLabel': [
      'Vettore di esempio A (di fantasia)',
      'Vettore di esempio B (di fantasia)',
      'Vettore merci di esempio C (di fantasia)',
    ],
    'logistics.freightType': [
      'Imballaggi',
      'Generi alimentari',
      'Materiali da costruzione',
      'Componenti elettronici',
      'Articoli per la casa',
    ],
    'logistics.routeSummary': [
      'Zona di fantasia Aurelvia → zona Rivosereno',
      'Zona di fantasia Fraxinia → zona Pinelume',
    ],
    'logistics.fareItem': [
      'Tariffa base (esempio)',
      'Supplemento sponda idraulica (esempio)',
      'Movimentazione manuale (esempio)',
      'Tempo di attesa (esempio)',
    ],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': [
      'Scatola di cartone piccola',
      'Nastro adesivo per imballaggio 48 mm',
      'Asciugamani in cotone, 3 pezzi',
      'Riso integrale 2 kg',
    ],
    'logistics.ownerLabel': [
      'Mittente A (di fantasia)',
      'Mittente B (di fantasia)',
      'Mittente C (di fantasia)',
    ],

    // hospitality
    'hospitality.propertyName': [
      'Tenuta nella Pineta (di fantasia)',
      'Albergo Rivosereno (di fantasia)',
      'Piccola locanda Fraxinia (di fantasia)',
    ],
    'hospitality.siteName': [
      'Piazzola Brezza di Pino A (di fantasia)',
      'Piazzola Profumo di Pino B (di fantasia)',
      'Piazzola Pigna C (di fantasia)',
    ],
    'hospitality.amenity': [
      'Area barbecue privata',
      'Doccia in comune',
      'Wi-Fi',
    ],
    'hospitality.stayOption': [
      'Kit per barbecue (esempio)',
      'Fascina di legna (esempio)',
      'Arrivo anticipato (esempio)',
    ],
    'hospitality.seasonName': [
      'Periodo base',
      'Alta stagione festiva (esempio)',
      'Periodo con offerta infrasettimanale (esempio)',
    ],
    'hospitality.ratePlan': [
      'Tariffa standard di esempio',
      'Tariffa con colazione di esempio',
      'Tariffa infrasettimanale di esempio',
    ],
    'hospitality.houseRule': [
      'Si prega di mantenere il silenzio negli spazi comuni durante la notte.',
      'Si prega di consultare l’elenco di controllo di esempio per la partenza.',
    ],
    'hospitality.reviewSnippet': [
      'Le istruzioni di esempio per la camera erano facili da leggere.',
      'Le istruzioni della struttura di fantasia sono ben organizzate.',
    ],
    'hospitality.hkCheckItem': [
      'Cambiare la biancheria da letto',
      'Pulire il bagno',
      'Controllare i prodotti di cortesia',
      'Controllare il minibar',
    ],
    'hospitality.maintenanceIssue': [
      'Controllo di una perdita nel bagno (esempio)',
      'Richiesta di controllo dell’illuminazione (esempio)',
      'Controllo del display del riscaldamento (esempio)',
      'Controllo di mobili danneggiati (esempio)',
    ],
    'hospitality.lostItemName': [
      'Ombrello blu',
      'Sciarpa grigia',
      'Un libro',
      'Bottiglia d’acqua',
    ],
    'hospitality.specialRequest': [
      'Piano alto, non fumatori (esempio)',
      'Richiesta di un cuscino in più (esempio)',
      'Richiesta di una camera tranquilla (esempio)',
    ],
    'hospitality.menuItem': [
      'Menu con zuppa di alghe',
      'Pasta alle verdure',
      'Yogurt alla frutta',
      'Tè caldo',
    ],
    'hospitality.menuOption': [
      'Meno riso',
      'Riso in porzione normale',
      'Contorno in più (esempio)',
      'Senza ghiaccio',
    ],
    'hospitality.amenityName': [
      'Asciugamano',
      'Acqua',
      'Spazzolino da denti',
      'Cuscino',
    ],
    'hospitality.localSpot': [
      'Locale delle zuppe del mattino (di fantasia)',
      'Caffè del vicolo (di fantasia)',
      'Sentiero di Aurelvia (di fantasia)',
    ],
    'hospitality.conciergeReply': [
      'Le istruzioni della struttura di fantasia compaiono nei dettagli del soggiorno.',
      'La richiesta è stata annotata nel registro di esempio.',
      'I luoghi nelle vicinanze sono tutti luoghi demo di fantasia.',
    ],
    'hospitality.folioItem': [
      'Costo della camera (esempio)',
      'Servizio in camera (esempio)',
      'Opzione aggiuntiva (esempio)',
    ],
  },
  // The texts of Italian that read like the English ones on purpose: names of
  // a currency, a country, and a city, a pet name, the discipline and the
  // apparatus of a Pilates studio, acronyms and file formats of the exam
  // questions, and loanwords that Italian shares with English (`Fantasy`,
  // `Podcast`, `Backlog`, `Sprint`). The language coverage gate reads this
  // list.
  allowSameAsEnglish: <String, List<String>>{
    'fx.currencyName.EUR': ['Euro'],
    'remit.countryName.VN': ['Vietnam'],
    'remit.countryName.NP': ['Nepal'],
    'vet.petName': ['Tofu'],
    'travel_wallet.cityName': ['Osaka', 'Tokyo', 'Bangkok', 'Hanoi'],
    'space_rental.amenity': ['Wi-Fi'],
    'hospitality.amenity': ['Wi-Fi'],
    'fitness.classCategoryLabel': ['Reformer', 'Yoga'],
    'fitness.equipment': ['Reformer'],
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'Router', 'HTTP'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF'],
    'hrd.courseKind': ['Leadership'],
    'content.genreName': ['Fantasy'],
    'content.genreTaxonomy': ['Fantasy'],
    'content.audioTaxonomy': ['Podcast'],
    'helpdesk.topicName': ['Account'],
    'brokerage.skillTag': ['Dart'],
    'workplace.labelName': ['Backlog'],
    'workplace.sprintName': ['Sprint {n}'],
    // The clinic data. Words that Italian shares with English: the name of a
    // clinic (`Demo`), a kind of care (`Laser`, `Lifting`, `Acne`), the unit
    // `ml`, a dosage form (`capsule`), an answer (`No`), the card networks, the
    // acronyms of the devices and of the tags, and the words of a screen
    // (`Tablet`, `Online`, `App`).
    'clinic.clinicNamePrefixes': ['Demo'],
    'clinic.visitPurposes.details': ['Laser', 'Lifting', 'Acne'],
    'clinic.procedures.unit': ['ml'],
    'clinic.drugForms.form': [' capsule'],
    // The units of a strength, which follow a space.
    'clinic.drugForms.unit': ['*'],
    'clinic.questions.options': ['No', 'Acne'],
    'clinic.cardIssuers': ['Visa', 'Mastercard', 'Amex'],
    'clinic.texts.labels': ['HIFU', 'RF', 'IPL'],
    'clinic.ops.patientTags.label': ['VIP', 'Lifting'],
    'clinic.ops.labels': ['Tablet', 'Online', 'App'],
    // The SaaS data. The names of two plans, the message channels that are named
    // by their acronym, and the word `account`, which are the same in both
    // languages.
    'saas.plans.name': ['Standard', 'Pro'],
    'saas.labels': ['SMS', 'LMS'],
    'saas.ops.auditTargets': ['account'],
  },
);
