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

    // @@NEXT@@
  },
);
