import '../co_l10n_bundle.dart';

/// German domain text: the German counterpart of every English key, with the
/// same number of texts in the same order.
///
/// The texts are a draft written with an AI assistant that a native speaker
/// has to review; `docs/languages/de.md` lists the terms, the conventions, and
/// the texts to look at. A patient or customer is addressed with `Sie`.
///
/// The fictional place names are German-sounding inventions that stand in for
/// the invented names of the English bundle: Tannenlicht, Flussau, Eschenhain,
/// Tannenbach, and Feldmark. See [CoL10nBundle].
const CoL10nBundle deBundle = CoL10nBundle(
  language: 'de',
  texts: <String, List<String>>{
    // common
    // A masked name. {lastName} is a family name, {firstName} a given name, and
    // {initial} the first letter of a given name; only the placeholders a
    // template contains are drawn, so a language chooses which name it masks.
    'common.maskedName': ['{initial}***'],
    // The name of a child under a taxonomy root: {root} is the root name and {n}
    // the child number.
    'common.taxonomyChild': ['{root} · Unterthema {n}'],

    // fx
    'fx.currencyName.USD': ['US-Dollar'],
    'fx.currencyName.JPY': ['Japanischer Yen'],
    'fx.currencyName.EUR': ['Euro'],
    'fx.currencyName.CNY': ['Chinesischer Yuan'],
    'fx.currencyName.THB': ['Thailändischer Baht'],
    'fx.currencyName.VND': ['Vietnamesischer Dong'],
    'fx.currencyName.PHP': ['Philippinischer Peso'],
    'fx.currencyName.NPR': ['Nepalesische Rupie'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      'Demo-Wechselstube Flughafen T1',
      'Demo-Wechselstube Tannenlicht',
      'Demo-Wechselstube Flughafen T2',
      'Demo-Wechselstube Flussau',
      'Demo-Wechselstube Eschenhain',
    ],
    'fx.couponName': [
      '80 % Spread-Rabatt auf USD (Beispiel)',
      '70 % Spread-Rabatt auf JPY (Beispiel)',
      'Rabatt beim ersten Geldwechsel (Beispiel)',
    ],
    'fx.tierName': ['Bronze', 'Silber', 'Gold'],

    // remit
    'remit.countryName.VN': ['Vietnam'],
    'remit.countryName.PH': ['Philippinen'],
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.US': ['Vereinigte Staaten'],
    'remit.countryName.CN': ['China'],
    'remit.bankName': ['Partnerbank Lichtweide (fiktiv)'],
    'remit.flagRule': [
      'Hoher Einzelbetrag (Demo-Regel)',
      'Zusätzliche Dokumentenprüfung (Demo-Regel)',
      'Prüfung wiederholter Anfragen (Demo-Regel)',
    ],

    // vet
    'vet.petName': ['Hafer', 'Falter', 'Tofu', 'Bohne', 'Wölkchen'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['Malteser', 'Pudel', 'Mischling'],
    'vet.breed.cat': ['Europäisch Kurzhaar', 'Mischlingskatze'],
    'vet.breed.small_mammal': ['Kaninchen', 'Hamster'],
    'vet.breed.bird': ['Kleiner Papagei'],
    'vet.breed.reptile': ['Landschildkröte'],
    'vet.coatColor': ['Weiß', 'Braun', 'Schwarz', 'Dreifarbig', 'Grau'],
    'vet.vaccineName': [
      'Kombinationsimpfstoff (Beispiel)',
      'Tollwutimpfung (Beispiel)',
      'Kombinationsimpfstoff für Katzen (Beispiel)',
    ],
    'vet.preventiveProduct': [
      'Herzwurm-Prophylaxe, Beispielpräparat (fiktiv)',
      'Prophylaxe gegen Außenparasiten, Beispielpräparat (fiktiv)',
    ],
    'vet.vetDiagnosis': [
      'Hautbefund (Beispiel)',
      'Befund zur Verdauung (Beispiel)',
      'Routine-Gesundheitscheck (Beispiel)',
    ],
    'vet.vetDrug': [
      'Hautpflege-Beispielmittel (fiktiv)',
      'Verdauungs-Beispielmittel (fiktiv)',
      'Augenpflege-Beispielmittel (fiktiv)',
    ],
    'vet.clinicRoom': ['Behandlungsraum 1', 'Behandlungsraum 2', 'Impfraum'],

    // grocery
    'grocery.originRegion': [
      'Anbaugebiet Tannenlicht (fiktiv)',
      'Anbaugebiet Flussau (fiktiv)',
      'Anbaugebiet Feldmark (fiktiv)',
    ],
    'grocery.harvestNote': [
      'Ernte- und Verpackungsdatum sind beispielhaft.',
      'Der Frischehinweis beschreibt ein fiktives Produkt.',
    ],
    'grocery.deliveryZone': [
      'Demo-Liefergebiet Tannenlicht A',
      'Demo-Liefergebiet Flussau B',
      'Demo-Liefergebiet Feldmark C',
    ],
    'grocery.slotLabel': [
      'Frühmorgens 06:00–07:00 Uhr',
      'Abends 18:00–20:00 Uhr',
    ],
    'grocery.substitutionNote': [
      'Beispiel für einen Ersatzartikel mit ähnlichem Gewicht.',
      'Beispiel für eine Erstattung ohne Ersatzartikel.',
    ],
    'grocery.doorNote': [
      'Bitte am Hauseingang klingeln.',
      'Persönliche Übergabe statt Ablage vor der Tür.',
    ],
    'grocery.categoryName': [
      'Obst',
      'Gemüse',
      'Fertiggerichte',
      'Getreide',
      'Fleisch',
      'Fisch und Meeresfrüchte',
      'Milchprodukte',
    ],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': [
      'Erdbeeren',
      'Spinat',
      'Handgemachte Teigtaschen',
      'Naturreis',
      'Hähnchen-Innenfilet',
      'Tiefkühl-Makrele',
      'Milch',
    ],
    // A space between the number and the unit, as German writes it.
    'catalog.groceryUnit': [
      '500 g',
      '200 g',
      '1 kg',
      '2 kg',
      '500 g',
      '600 g',
      '1 l',
    ],
    'catalog.commerceName': [
      'Kabellose Ohrhörer',
      'Faltbare Aufbewahrungsbox',
      'Baumwoll-Handtuchset',
      'Keramiktasse',
      'Getreide-Snack',
    ],
    'catalog.commerceUnit': [
      '1 Paar',
      '1 Stück',
      '3 Stück',
      '1 Stück',
      '200 g',
    ],

    // booking
    'booking.cancelReason': [
      'Terminänderung (Beispiel)',
      'Anderen Zeitpunkt gewählt (Beispiel)',
      'Persönlicher Grund (Beispiel)',
    ],

    // dental
    'dental.dentalProcedure': [
      'Zahnsteinentfernung',
      'Wurzelkanalbehandlung (Beispiel)',
      'Kompositfüllung (Beispiel)',
      'Kronenplanung (Beispiel)',
    ],
    'dental.dentalMaterial': [
      'Komposit (Beispiel)',
      'Zirkonoxid (Beispiel)',
      'Keramik (Beispiel)',
    ],
    'dental.chairName': [
      'Behandlungsstuhl 1',
      'Behandlungsstuhl 2',
      'Behandlungsstuhl 3',
    ],
    'dental.hygieneNote': [
      'Beispieleintrag zur Erklärung der Putztechnik.',
      'Beispieleintrag zur Beobachtung der Mundhygiene.',
    ],

    // homecare
    'homecare.careGrade': [
      'Pflegegrad 1',
      'Pflegegrad 2',
      'Pflegegrad 3',
      'Pflegegrad 4',
      'Pflegegrad 5',
      'Kognitive Unterstützungsstufe',
    ],
    'homecare.careTaskLabel': [
      'Hilfe bei den Mahlzeiten',
      'Prüfung der Medikamentendokumentation',
      'Hilfe bei der Körperpflege',
      'Hilfe bei der Fortbewegung',
      'Hilfe beim Toilettengang',
      'Gespräch',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      'Nudelladen in der Gasse (fiktiv)',
      'Bahnhofskiosk (fiktiv)',
      'Reiseherberge (fiktiv)',
    ],
    'travel_wallet.cityName': ['Osaka', 'Tokio', 'Bangkok', 'Hanoi'],
    'travel_wallet.cardAlias': [
      'Ausflugs-Reisekarte (fiktiv)',
      'Reisebudget-Karte (fiktiv)',
    ],
    'travel_wallet.tripName': [
      'Vier Tage in Osaka',
      'Wochenende in Bangkok',
      'Hanoi zu Fuß',
    ],

    // b2b_trade
    'b2b_trade.buyerCompany': [
      'Café Morgenstille (fiktiv)',
      'Bäckerei Mehlwolke (fiktiv)',
      'Feinkost Tannenbach (fiktiv)',
    ],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      'Pappbecher 350 ml, 1.000 Stück',
      'Tiefkühlkartoffeln, 10 kg',
      'Papiertüten, 100 Stück',
      'Unparfümierte Hygienetücher, 20 Stück',
    ],
    'b2b_trade.quoteTitle': [
      'Angebot Verpackungsmaterial, monatlich (fiktiv)',
      'Angebot Lebensmittel, wöchentlich (fiktiv)',
      'Angebot Hygienebedarf (fiktiv)',
    ],
    'b2b_trade.holdReason': [
      'Prüfung des verfügbaren Kreditrahmens (Beispiel)',
      'Prüfung des Liefertermins (Beispiel)',
      'Prüfung der Artikelspezifikation (Beispiel)',
    ],

    // group_deal
    'group_deal.dealTitle': [
      'Sammelbestellung: Zitrusfrüchte im Winter',
      'Sammelbestellung: kabellose Ohrhörer',
      'Sammelbestellung: Baumwoll-Handtuchset',
    ],
    'group_deal.optionLabel': [
      'Normale Größe',
      'Geschenkverpackung',
      'Standardfarbe',
    ],
    'group_deal.rewardLabel': [
      'Teilnahmestempel',
      'Beispielhafte Bonuspunkte',
      'Versandvorteil',
    ],
    'group_deal.benefitTitle': [
      'Beispiel-Gutschein für kostenlosen Versand',
      'Beispiel-Gutschein für die nächste Sammelbestellung',
    ],
    'group_deal.settleNote': [
      'Beispielsumme der erfolgreichen Teilnahmen.',
      'Beispielsumme ohne stornierte Teilnahmen.',
    ],

    // fitness
    // A class name from the category label and the level label of the same
    // record.
    'fitness.className': ['{category} {level}'],
    'fitness.classCategoryLabel': [
      'Mattenpilates',
      'Reformer-Pilates',
      'Chair-Pilates',
      'Yoga',
    ],
    'fitness.classLevelLabel': ['Grundstufe', 'Mittelstufe', 'Oberstufe'],
    'fitness.equipment': [
      'Gymnastikmatte',
      'Reformer',
      'Pilates-Chair',
      'Yogablock',
    ],
    'fitness.studioRoom': [
      'Mattenraum',
      'Reformer-Raum',
      'Chair-Raum',
      'Yogaraum',
    ],
    'fitness.instructorSpecialty': [
      'Mattenpilates-Unterricht',
      'Reformer-Unterricht',
      'Yogaunterricht',
    ],
    'fitness.passName': [
      '10er-Karte Mattenpilates (Beispiel)',
      '20er-Karte Reformer (Beispiel)',
      'Monatskarte (Beispiel)',
    ],
    'fitness.cancelReason': ['Terminänderung', 'Änderung der Kurszeit'],
    'fitness.noShowNote': [
      'Beispieleintrag ohne Anwesenheitsbestätigung.',
      'Beispiel: Nach Kursbeginn als nicht erschienen markiert.',
    ],

    // space_rental
    'space_rental.spaceName': [
      'Partyraum Vier Uhr (fiktiv)',
      'Lernraum Tannenlicht (fiktiv)',
      'Proberaum Flussau (fiktiv)',
    ],
    'space_rental.districtName': [
      'Fiktive Stadt, Stadtteil Tannenlicht',
      'Fiktive Stadt, Stadtteil Flussau',
      'Fiktive Stadt, Stadtteil Eschenhain',
    ],
    'space_rental.amenity': ['WLAN', 'Whiteboard', 'Wasserspender'],
    'space_rental.equipmentOption': [
      'Beamer (Beispiel)',
      'Tontechnik (Beispiel)',
      'Ein Parkplatz (Beispiel)',
    ],
    'space_rental.houseRule': [
      'Bitte stellen Sie die Ausstattung nach der Nutzung an ihren Platz zurück.',
      'Bitte halten Sie die gebuchte Zeit ein.',
    ],
    'space_rental.bookingPurpose': [
      'Lerntreffen',
      'Treffen im Freundeskreis',
      'Bandprobe',
    ],
    'space_rental.guestMessage': [
      'Könnten Sie mir erklären, wie die Ausstattung funktioniert?',
      'Bitte schicken Sie mir die Hinweise zum Zutritt.',
    ],
    'space_rental.hostReply': [
      'Bitte beachten Sie die Geräteanleitung auf der Buchungsseite.',
      'Die Hinweise zum Zutritt finden Sie in den Buchungsdetails.',
    ],

    // dining
    'dining.restaurantName': [
      'Nudelhaus Perilla (fiktiv)',
      'Pastaladen in der Gasse (fiktiv)',
      'Teestube Tannenlicht (fiktiv)',
    ],
    'dining.menuName': [
      'Perilla-Nudeln',
      'Tomatenpasta',
      'Gemüse-Reisschale',
      'Heißer Tee',
    ],
    // The number goes last, so the text is right for one guest and for eight.
    'dining.partyLabel': ['Tisch für {n}'],
    'dining.noShowNote': [
      'Beispieleintrag der Warteliste ohne Ankunftsbestätigung.',
      'Beispiel: Nach der angekündigten Zeit nicht erschienen.',
    ],
    'dining.loyaltyBenefit': [
      'Getränk beim fünften Besuch (Beispiel)',
      'Dessertgutschein für die Stammkundschaft (Beispiel)',
    ],
    'dining.districtName': [
      'Fiktive Stadt, Stadtteil Tannenlicht',
      'Fiktive Stadt, Stadtteil Flussau',
    ],

    // daycare
    'daycare.childName': ['Mila', 'Ben', 'Lina', 'Finn', 'Emil'],
    'daycare.className': ['Sonnengruppe', 'Mondgruppe', 'Sterngruppe'],
    'daycare.ageLabel': ['1 Jahr', '2 Jahre', '3 Jahre', '4 Jahre', '5 Jahre'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.guardianLabel': ['Erziehungsberechtigte von {name1}'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.teacherName': ['Erzieher:in {name1}'],
    'daycare.toiletNote': [
      'Ein Toilettengang notiert (Beispiel)',
      'Zwei Toilettengänge notiert (Beispiel)',
      'Nichts notiert (Beispiel)',
    ],
    'daycare.mealMenu': [
      'Naturreis mit Gemüseeintopf',
      'Tofu-Suppe mit Reis',
      'Gebratener Reis mit Gemüse',
    ],
    'daycare.snackMenu': [
      'Birnenspalten',
      'Gedämpfte Süßkartoffel',
      'Naturjoghurt',
    ],
    'daycare.allergenLabel': [
      'Milch',
      'Ei',
      'Soja',
      'Weizen',
      'Keine bekannt (Beispiel)',
    ],
    'daycare.activityTitle': [
      'Spielen im Schnee',
      'Papierhäuser basteln',
      'Spiel mit bunten Bausteinen',
    ],
    'daycare.albumCaption': [
      'Fiktive Illustration: gemeinsam Bausteine stapeln',
      'Fiktive Illustration vom Spielen im Winter',
    ],
    'daycare.drugLabel': [
      'Fiebersaft (fiktiv)',
      'Hustensaft (fiktiv)',
      'Pflegecreme (fiktiv)',
    ],
    'daycare.dosageLabel': [
      'Angabe der Erziehungsberechtigten (Beispiel): 2 ml',
      'Angabe der Erziehungsberechtigten (Beispiel): 3 ml',
      'Angabe der Erziehungsberechtigten (Beispiel): geringe Menge',
    ],
    'daycare.noticeTitle': [
      'Hinweis zum Spielen im Winter (Beispiel)',
      'Hinweis zur Speiseplanänderung (Beispiel)',
      'Hinweis zur Sicherheitskontrolle (Beispiel)',
    ],

    // exam_prep
    'exam_prep.subjectName': [
      'Datenbanken',
      'Datenbanken',
      'Netzwerke',
      'Netzwerke',
      'Netzwerke',
      'Grundlagen der Programmierung',
      'Grundlagen der Programmierung',
      'Informationssicherheit',
      'Informationssicherheit',
    ],
    'exam_prep.unitName': [
      'Datenmodellierung',
      'SQL-Grundlagen',
      'Transportschicht',
      'Wegewahl',
      'Anwendungsschicht',
      'Variablen',
      'Datenstrukturen',
      'Grundlagen der Kryptografie',
      'Zugriffskontrolle',
    ],
    'exam_prep.questionStem': [
      'Welcher Schlüssel unterscheidet die Zeilen einer Tabelle voneinander?',
      'Welche SQL-Klausel wählt Zeilen anhand einer Bedingung aus?',
      'Welches Transportprotokoll sorgt für die richtige Reihenfolge und die erneute Übertragung?',
      'Welches Gerät wählt den nächsten Weg eines Pakets aus?',
      'Welches Protokoll beschreibt Webanfragen und Webantworten?',
      'Was speichert in einem Programm einen Wert unter einem Namen?',
      'Welche Datenstruktur entnimmt zuerst den zuletzt eingefügten Wert?',
      'Was berechnet aus einer Eingabe eine Zusammenfassung fester Länge?',
      'Welches Prinzip vergibt nur die für eine Aufgabe nötigen Berechtigungen?',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      'Primärschlüssel',
      'WHERE',
      'TCP',
      'Router',
      'HTTP',
      'Variable',
      'Stapelspeicher',
      'Hashfunktion',
      'Prinzip der minimalen Rechte',
    ],
    'exam_prep.wrongChoice1': [
      'Schriftart',
      'Schriftart',
      'JPEG',
      'Lautsprecher',
      'PNG',
      'Rahmen',
      'FIFO-Warteschlange',
      'Schriftauswahl',
      'Öffentlicher Zugriff',
    ],
    'exam_prep.wrongChoice2': [
      'Hintergrundfarbe',
      'Außenabstand',
      'CSS',
      'Tastatur',
      'MP3',
      'Seitenrand',
      'Bild',
      'Bildschirmzoom',
      'Gemeinsames Passwort',
    ],
    'exam_prep.wrongChoice3': [
      'Bildschirmbreite',
      'Symbol',
      'SVG',
      'Bildschirm',
      'TTF',
      'Hintergrundbild',
      'Audiodatei',
      'Hintergrundfüllung',
      'Übersprungene Prüfungen',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    'exam_prep.explanation': [
      'Ein Primärschlüssel identifiziert jede Zeile einer Tabelle eindeutig.',
      'Die WHERE-Klausel formuliert die Bedingung für die ausgewählten Zeilen.',
      'TCP sorgt für Reihenfolge und erneute Übertragung eines Bytestroms.',
      'Ein Router wählt anhand der Zieladresse den nächsten Weg aus.',
      'HTTP beschreibt Webanfragen und Webantworten.',
      'Eine Variable erlaubt es einem Programm, einen Wert über seinen Namen anzusprechen.',
      'Ein Stapelspeicher gibt den zuletzt eingefügten Wert zuerst wieder heraus.',
      'Eine Hashfunktion berechnet aus einer Eingabe eine Zusammenfassung fester Länge.',
      'Das Prinzip der minimalen Rechte vergibt nur die für eine Aufgabe nötigen Berechtigungen.',
    ],
    'exam_prep.examPaperTitle': [
      'Übungsklausur 1 (fiktiv)',
      'Übungsklausur 2 (fiktiv)',
      'Kapiteltest (fiktiv)',
    ],
    'exam_prep.studyTaskTitle': [
      'Zehn Aufgaben zur Transportschicht lösen',
      'Fehler bei der Zugriffskontrolle wiederholen',
      'SQL-Grundlagen prüfen',
    ],
    'exam_prep.taxonomyName': [
      'Datenbanken',
      'Netzwerke',
      'Grundlagen der Programmierung',
      'Informationssicherheit',
    ],

    // hrd
    'hrd.departmentName': [
      'Vertrieb',
      'Produktion',
      'Forschung',
      'Kundenservice',
      'Verwaltung',
      'Logistik',
    ],
    'hrd.jobTitle': ['Mitarbeiter:in', 'Manager:in', 'Teamleitung'],
    'hrd.courseTitle': [
      'Umgang mit personenbezogenen Daten 2026 (fiktiv)',
      'Gemeinsam sicher arbeiten (fiktiv)',
      'Arbeitsunterlagen ordnen (fiktiv)',
    ],
    'hrd.courseKind': ['Pflicht', 'Fachlich', 'Führung'],
    'hrd.lessonTitle': [
      'Grundprinzipien verstehen',
      'Praxisbeispiele durchgehen',
      'Aufzeichnungen prüfen',
    ],
    'hrd.chapterTitle': [
      'Einführung',
      'Beispiele durchgehen',
      'Zusammenfassung',
    ],
    'hrd.nudgeTitle': [
      'Erinnerung an die Schulungsfrist (Beispiel)',
      'Erinnerung an offene Lektionen (Beispiel)',
    ],
    'hrd.exemptionReason': [
      'Externer Abschlussnachweis (Beispiel)',
      'Prüfung des Abwesenheitszeitraums (Beispiel)',
      'Prüfung einer Ersatzschulung (Beispiel)',
    ],
    'hrd.classroomPlace': [
      'Schulungsraum Tannenlicht (fiktiv)',
      'Seminarraum Flussau (fiktiv)',
    ],

    // neighborhood
    'neighborhood.neighborhoodName': [
      'Viertel Tannenlicht (fiktiv)',
      'Viertel Ginkgo (fiktiv)',
      'Viertel Eschenhain (fiktiv)',
    ],
    'neighborhood.districtName': [
      'Fiktive Stadt, Stadtteil Flussau',
      'Fiktive Stadt, Stadtteil Tannenbach',
    ],
    'neighborhood.nickname': [
      'TannenBohne (fiktiv)',
      'EschenStern (fiktiv)',
      'GassenWolke (fiktiv)',
    ],
    'neighborhood.postTitle': [
      'Blauer Handschuh auf dem Spielplatz gefunden (Beispiel)',
      'Gemeinsam einen Spazierweg im Viertel erkunden (Beispiel)',
      'Kleinen Blumentopf zu verschenken (Beispiel)',
    ],
    'neighborhood.postBody': [
      'Fiktive Neuigkeiten aus dem Viertel. Einzelheiten stehen in diesem Beitrag.',
      'Beispielbeitrag für die Nachbarschaft; er enthält weder eine Telefonnummer noch eine echte Adresse.',
    ],
    'neighborhood.commentBody': [
      'Danke für die Neuigkeiten.',
      'Ich schaue nach und antworte im Beitrag.',
      'Ich kann abends nachsehen.',
    ],
    'neighborhood.placeName': [
      'Bäckerei Tannenlicht (fiktiv)',
      'Unterstand im Park Flussau (fiktiv)',
      'Kleine Bücherei Eschenhain (fiktiv)',
    ],
    'neighborhood.openHours': [
      '08:00–21:00 Uhr',
      '09:00–18:00 Uhr',
      '10:00–20:00 Uhr',
    ],
    'neighborhood.bannedWord': [
      'Werbebeispiel',
      'Schimpfwortbeispiel',
      'Sperrwortbeispiel',
    ],
    'neighborhood.keyword': [
      'Handschuh',
      'Spaziergang',
      'Verschenken',
      'Neuigkeiten im Viertel',
    ],

    // meetup
    'meetup.clubName': [
      'Morgenlauf Tannenlicht (fiktiv)',
      'Leserunde Flussau (fiktiv)',
      'Brettspielrunde Eschenhain (fiktiv)',
    ],
    'meetup.interestTag': [
      'Laufen',
      'Lesen',
      'Brettspiele',
      'Fotografie',
      'Kochen',
      'Wandern',
    ],
    'meetup.clubIntro': [
      'Fiktive Gruppe, in der auch Erstteilnehmende aus der Nachbarschaft willkommen sind.',
      'Beispielgruppe, die kleine Aktivitäten gemeinsam unternimmt.',
    ],
    'meetup.gatheringTitle': [
      'Gruppentreffen in der dritten Januarwoche (fiktiv)',
      'Bücherrunde am Wochenende (fiktiv)',
      'Winterspaziergang der Gruppe (fiktiv)',
    ],
    'meetup.venueName': [
      'Eingang zum Spazierweg Flussau (fiktiv)',
      'Gruppenraum Tannenlicht (fiktiv)',
      'Unterstand Eschenhain (fiktiv)',
    ],
    'meetup.nickname': [
      'MorgenBohne (fiktiv)',
      'BuchWolke (fiktiv)',
      'KleinStern (fiktiv)',
    ],
    'meetup.duesItem': [
      'Teilnahmegebühr (Beispiel)',
      'Anteil für Getränke (Beispiel)',
      'Anteil für Leihgeräte (Beispiel)',
    ],
    'meetup.joinAnswer': [
      'Ich möchte ab diesem Monat bei den Aktivitäten mitmachen.',
      'Ich kann an Wochenendvormittagen teilnehmen.',
    ],
    'meetup.ruleText': [
      'Bitte respektieren Sie die Zeit der anderen.',
      'Bitte tauschen Sie sich in der Gruppe aus, ohne Kontaktdaten zu veröffentlichen.',
      'Bitte sagen Sie der Gruppe Bescheid, wenn Sie absagen.',
    ],
    'meetup.cadenceLabel': [
      'Jeden Samstag, 07:00 Uhr',
      'Jeden zweiten Sonntag, 10:00 Uhr',
      'Jeden ersten Samstag im Monat, 14:00 Uhr',
    ],

    // fandom
    // The two approved fictional creators of the fandom pack. German writes two
    // fictional names of its own, never the Korean ones.
    'fandom.creatorName': ['Sanduhrgarten', 'Himmelsfaden'],
    'fandom.fanNickname': ['Stern', 'Spross', 'Mondbohne', 'Lichttropfen'],
    'fandom.benefitTitle': [
      'Beispielbild aus dem Mitgliederbereich',
      'Simulierte Gewinnspielteilnahme',
      'Fiktiven Clip vorab ansehen',
    ],
    'fandom.postCaption': [
      'Fiktive Illustration eines Ateliers im Winter',
      'Beispielbeitrag über die Probenzeit',
    ],
    'fandom.clipTitle': [
      'Dreißig Sekunden Probe (fiktiv)',
      'Gruß aus dem Atelier (fiktiv)',
      'Winterklang-Notiz (fiktiv)',
    ],
    'fandom.letterBody': [
      'Der heutige Beispielbeitrag hat mir gefallen. Ich freue mich auf die nächsten Neuigkeiten.',
      'Die Illustration vom Winteratelier wirkte warm. Ich wünsche Ihnen viel Kraft.',
    ],
    'fandom.eventTitle': [
      'Winter-Fantreffen (fiktiv)',
      'Veranstaltung „Geschichten aus dem Atelier“ (fiktiv)',
    ],
    'fandom.agendaTitle': [
      'Programm im kleinen Wintertheater (fiktiv)',
      'Fiktives Sendungsgespräch',
      'Zeitplan für neue Beiträge',
    ],
    'fandom.venueLabel': [
      'Kleines Wintertheater (fiktiv)',
      'Atelier Tannenlicht (fiktiv)',
      'Online-Beispielraum',
    ],

    // content
    'content.seriesTitle': [
      'Die Postinsel des Papierleuchtturms (fiktiv)',
      'Die kleine Karte des Wolkenteichs (fiktiv)',
      'Der Garten der langsamen Uhr (fiktiv)',
    ],
    'content.penName': [
      'WortBohne (fiktiv)',
      'PapierStern (fiktiv)',
      'WolkenFeder (fiktiv)',
    ],
    'content.synopsisLine': [
      'Fiktive Figuren sortieren auf einer kleinen Insel Briefe.',
      'Eine fiktive Geschichte darüber, einen Teich zu zeichnen, den es auf der Karte nicht gibt.',
    ],
    'content.genreName': [
      'Fantasy',
      'Alltag',
      'Abenteuer',
      'Wissenschaftsgeschichten',
      'Essay',
    ],
    'content.episodeTitle': [
      'Das erste Papierboot (fiktiv)',
      'Ein kleiner Punkt auf dem Teich (fiktiv)',
      'Ein Nachmittag ohne Uhr (fiktiv)',
    ],
    'content.cutAltText': [
      'Illustration: Eine fiktive Figur faltet ein Papierboot',
      'Illustration: Zwei fiktive Figuren am Teich',
    ],
    'content.commentLine': [
      'Die Szene mit dem Papierboot ist mir im Gedächtnis geblieben.',
      'Ich würde gern die nächste Beispielfolge lesen.',
    ],
    'content.chapterParagraph': [
      'Im Briefkasten der Insel lag ein leeres Blatt. Ein Kind faltete es zu einem kleinen Boot in der Form des Teichs. Dieser Absatz ist ein eigens geschriebenes fiktives Demobeispiel.',
      'Neben der langsamen Uhr stand ein kleiner Blumentopf. Das Freundespaar zeichnete die Wolken, die es gesehen hatte, statt die Pflanze zu benennen. Dies ist ein eigens geschriebener fiktiver Beispielabsatz.',
    ],
    'content.publisherName': [
      'Papierleuchtturm Verlag (fiktiv)',
      'Wolkenteich Verlag (fiktiv)',
    ],
    'content.audioTitle': [
      'Ein Nachmittag beim Papierbootfalten (fiktiv)',
      'Klangnotizen eines kleinen Teichs (fiktiv)',
    ],
    'content.newsletterName': [
      'Papierleuchtturm – Wochennotizen (fiktiv)',
      'Wolkenteich – kleine Briefe (fiktiv)',
    ],
    'content.articleHeadline': [
      'Alltagsnotizen in kleine Gruppen ordnen (fiktiv)',
      'Die Farben eines Winterspaziergangs festhalten (fiktiv)',
    ],
    'content.topicName': [
      'Alltagsnotizen',
      'Winterspaziergänge',
      'Kleine Wissenschaft',
      'Lesegewohnheiten',
    ],
    'content.genreTaxonomy': [
      'Fantasy',
      'Alltag',
      'Abenteuer',
      'Wissenschaftsgeschichten',
      'Essay',
    ],
    'content.audioTaxonomy': ['Hörbuch', 'Podcast'],
    'content.topicTaxonomy': [
      'Alltagsnotizen',
      'Winterspaziergänge',
      'Kleine Wissenschaft',
      'Lesegewohnheiten',
      'Alltagsbeobachtungen',
    ],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      'Bitte den Status der Teameinladung prüfen',
      'Frage zu den Positionen einer Beispielrechnung',
      'Fehler beim Beispiel-CSV-Export',
      'Frage zum Status der Anbindung',
      'Frage zu einer Schaltfläche im Beispielbildschirm',
      'Frage: Wo finde ich die Hilfe?',
    ],
    'helpdesk.ticketDescription': [
      'Im fiktiven Support-Konto wird eine ausstehende Einladung angezeigt.',
      'Ich möchte die Positionen und den Zeitraum der fiktiven Rechnung prüfen.',
      'Beim Export der Beispieldaten als CSV erscheint ein Fehlerstatus.',
      'Ich möchte den Wortlaut auf der fiktiven Statusseite der Anbindung prüfen.',
      'Der Beispielbildschirm bleibt nach dem Klick auf eine Schaltfläche unverändert.',
      'Wo finde ich die fiktive Hilfeseite des Supports?',
    ],
    'helpdesk.macroName': [
      'Beispiel: Eingangsbestätigung',
      'Prüfung zusätzlicher Informationen',
      'Hinweis zum Bearbeitungsstand',
    ],
    'helpdesk.helpArticleTitle': [
      'Beispielanleitung zur Einladung',
      'Eine fiktive Rechnung lesen',
      'Beispieldaten als CSV exportieren',
    ],
    'helpdesk.csatComment': [
      'Ich habe mir die Erklärung angesehen.',
      'Die Beispielanleitung war leicht nachzuvollziehen.',
      'Ich habe noch Einzelheiten zu klären.',
    ],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      'Prüfen Sie den Einladungsstatus in den Kontoeinstellungen. Dieser simulierte KI-Entwurf muss vom Support-Team geprüft werden.',
      'Notieren Sie die Anmeldemethode zusammen mit dem Beispielfehler. Dieser simulierte KI-Entwurf ändert nichts am Konto.',
      'Prüfen Sie Zeitraum und Positionen der Beispielrechnung. Dieser simulierte KI-Entwurf beschreibt fiktive Preise.',
      'Halten Sie die Beispiel-Rechnungsnummer in der Supportnotiz fest. Dieser simulierte KI-Entwurf ist keine echte Zahlungsmitteilung.',
      'Prüfen Sie den für den Export gewählten Zeitraum und das Format. Dieser simulierte KI-Entwurf hält einen Beispielfehler ohne personenbezogene Daten fest.',
      'Prüfen Sie Spaltennamen und Dateistatus in der Beispiel-CSV. Dieser simulierte KI-Entwurf muss vom Support-Team geprüft werden.',
      'Notieren Sie den Beispielstatus der Anbindung und den Zeitpunkt der Prüfung. Dieser simulierte KI-Entwurf führt keine externen Aufrufe aus.',
      'Notieren Sie die betroffene Ansicht und die Schritte zur Reproduktion. Dieser simulierte KI-Entwurf verspricht kein Ergebnis.',
    ],
    'helpdesk.topicName': ['Konto', 'Abrechnung', 'Daten', 'Anbindung'],

    // campaign
    'campaign.brandName': [
      'Bäckerei Frühlingslicht (fiktiv)',
      'Buchladen Mondschein (fiktiv)',
      'Café Grüner Garten (fiktiv)',
    ],
    'campaign.campaignTitle': [
      'Winter-Beispielangebot',
      'Beispielinfo zum ersten Besuch',
      'Beispielinfo fürs Wochenende',
    ],
    'campaign.offerCopy': [
      '(Werbung) Beispielgutschein für ein fiktives Wintermenü. Zum Abmelden siehe die Demo-Einstellungen.',
      '(Werbung) Beispielangebot für ein fiktives Produkt. Die Abmeldung finden Sie in den Demo-Einstellungen.',
    ],
    'campaign.couponTitle': [
      'Winter-Beispielgutschein 20 %',
      'Beispielgutschein 10 % für den ersten Besuch',
    ],
    'campaign.segmentName': [
      'Beispielgruppe: Käufe der letzten 30 Tage',
      'Beispielgruppe mit Werbeeinwilligung',
      'Beispielgruppe für Wochenend-Infos',
    ],
    'campaign.failReason': [
      'Empfängernummer fehlt (Beispiel)',
      'Keine Werbeeinwilligung (Beispiel)',
      'Keine Einwilligung für Nachtzeiten (Beispiel)',
    ],

    // workplace
    'workplace.department': [
      'Frontend-Team',
      'Backend-Team',
      'Design-Team',
      'Kundensupport',
      'Personalabteilung',
    ],
    'workplace.position': ['Mitarbeiter:in', 'Manager:in', 'Teamleitung'],
    'workplace.workPlace': [
      'Büro Tannenlicht (fiktiv)',
      'Arbeitszentrum Flussau (fiktiv)',
      'Homeoffice',
    ],
    'workplace.shiftName': ['Tagschicht', 'Frühschicht', 'Wochenenddienst'],
    'workplace.approvalComment': [
      'Den angehängten Beispieleintrag geprüft.',
      'Der Beispielgrund muss noch geklärt werden.',
    ],
    'workplace.projectName': [
      'Überarbeitung des Kundenportals (fiktiv)',
      'Aufräumen des internen Wikis (fiktiv)',
      'Beispiel: Verbesserung der Barrierefreiheit',
    ],
    'workplace.workItemTitle': [
      'Fehlertext bei der Anmeldung verbessern',
      'Sortierung der Beispieltabelle prüfen',
      'Anzeige des Benachrichtigungsstatus aufräumen',
    ],
    'workplace.labelName': [
      'Texte',
      'Barrierefreiheit',
      'Backlog',
      'Prüfung nötig',
    ],
    'workplace.milestoneTitle': [
      'Erster Prüfmeilenstein',
      'Beispielansicht fertig',
      'Regressionsprüfung',
    ],
    'workplace.sprintName': ['Sprint {n}'],
    'workplace.commentBody': [
      'Feedback nach Prüfung der Beispielansicht.',
      'Bitte prüfen Sie den Wortlaut vor der nächsten Aufgabe.',
    ],
    'workplace.merchantName': [
      'Gasthaus Wildblume (fiktiv)',
      'Imbiss in der Gasse (fiktiv)',
      'Bürobedarf Tannenlicht (fiktiv)',
    ],
    'workplace.accountName': [
      'Verpflegung (Beispiel)',
      'Fahrtkosten (Beispiel)',
      'Besprechung (Beispiel)',
      'Verbrauchsmaterial (Beispiel)',
      'Reisekosten (Beispiel)',
      'Sonstiges (Beispiel)',
    ],
    'workplace.rejectReasonText': [
      'Beispielbeleg fehlt',
      'Zuordnung der Position muss geprüft werden',
      'Beispiel-Richtliniengrenze muss geprüft werden',
    ],

    // brokerage
    'brokerage.projectTitle': [
      'Beispiel: Aufbau eines Kundenportals',
      'Fiktive Überarbeitung einer Service-Ansicht',
      'Beispiel: Aufbau einer Buchungsansicht',
    ],
    'brokerage.serviceCategory': [
      'Weboberfläche',
      'App-Oberfläche',
      'Arbeitsplatzdesign',
      'Haushaltsservice',
    ],
    'brokerage.providerName': [
      'Studio Codedachboden (fiktiv)',
      'Oberflächenwerkstatt Tannenlicht (fiktiv)',
      'Hauswerkstatt Flussau (fiktiv)',
    ],
    'brokerage.providerHeadline': [
      'Fiktiver Partnerbetrieb mit Beispielansichten und Arbeitsnachweisen',
      'Beispielprofil zur gemeinsamen Prüfung des Umfangs eines fiktiven Projekts',
    ],
    'brokerage.skillTag': [
      'Dart',
      'Oberflächenplanung',
      'Datenaufbereitung',
      'Texterstellung',
    ],
    'brokerage.proposalMessage': [
      'Umfang und Kontrollpunkte für den Zeitplan des Beispiels vorbereitet.',
      'Ich schlage Kontrollpunkte für die Phasen des fiktiven Projekts vor.',
    ],
    'brokerage.portfolioTitle': [
      'Fiktives Kundenportal als Beispiel',
      'Beispielaufzeichnung einer Buchungsansicht',
      'Fiktive Verbesserung einer Arbeitstabelle',
    ],
    'brokerage.milestoneLabel': [
      'Umfangsprüfung',
      'Prüfung des Ansichtsentwurfs',
      'Prüfung der Beispielfunktion',
      'Übergabeprotokoll',
    ],
    'brokerage.homeServiceName': [
      'Klimaanlagenreinigung (Beispiel)',
      'Kleiner Umzug (Beispiel)',
      'Wasserhahn-Prüfung (Beispiel)',
      'Instrumentalunterricht für den Einstieg (Beispiel)',
    ],
    'brokerage.requestAnswer': [
      'Ich möchte vor dem Besuch den Umfang klären.',
      'Der Beispieltermin ist ein Wochenendvormittag.',
    ],
    'brokerage.regionDong': [
      'Fiktive Stadt, Stadtteil Tannenlicht',
      'Fiktive Stadt, Stadtteil Flussau',
      'Fiktive Stadt, Stadtteil Eschenhain',
    ],
    'brokerage.reviewText': [
      'Ich habe den Beispielarbeitsnachweis und die Hinweise geprüft.',
      'Die Hinweise zum Beispieltermin waren leicht verständlich.',
    ],
    'brokerage.creditLabel': [
      'Credits für die Angebotsabgabe (Beispiel)',
      'Erstattete Credits für ungesehene Angebote (Beispiel)',
      'Aufgeladene Credits (Beispiel)',
    ],
    'brokerage.advisorTitle': [
      'Fiktive Fachperson für Steuern',
      'Fiktive Fachperson für Recht',
      'Fiktive Fachperson für Arbeitsrecht',
    ],
    'brokerage.consultTopic': [
      'Beispiel: Erläuterung von Fachbegriffen',
      'Beispiel: Checkliste vor dem Beratungsgespräch',
      'Beispiel: Erläuterung einer Unterlagenliste',
    ],
    'brokerage.qnaQuestion': [
      'Was bedeutet dieser Fachbegriff des Systems? (fiktive Frage)',
      'Welche Felder enthält ein Beratungsprotokoll? (fiktive Frage)',
    ],
    // The two general-information texts begin with `Allgemeine`, as the safety
    // declaration of German says.
    'brokerage.qnaAnswerGeneric': [
      'Allgemeine Information als Beispiel. Eine Systemübersicht kann Begriffe, Geltungsbereich und Unterlagen auflisten. Eine Bewertung des Einzelfalls ist darin nicht enthalten.',
      'Allgemeine Information als Beispiel. Ein Beratungsprotokoll trennt Fragen und Nachschlagematerial. Es wird weder ein bestimmtes Ergebnis noch ein bestimmtes Vorgehen genannt.',
    ],
    'brokerage.consultNoteGeneric': [
      'Allgemeine Beispielnotiz: Das Fragethema und die Systembegriffe wurden vorgestellt. Die Unterlagenliste besteht aus fiktiven Erläuterungspunkten.',
      'Allgemeine Beispielnotiz: Das Format des Beratungsprotokolls wurde besprochen. Zum Einzelfall gibt es weder ein Ergebnis noch einen Ratschlag.',
    ],
    'brokerage.officeName': [
      'Beratungsbüro Tannenlicht (fiktiv)',
      'Aktenbüro Flussau (fiktiv)',
    ],
    'brokerage.serviceTypeName': [
      'Reinigung',
      'Umzug',
      'Reparatur',
      'Unterricht',
    ],

    // logistics
    'logistics.zoneName': [
      'Zone Tannenbach 1 (fiktiv)',
      'Zone Tannenbach 2 (fiktiv)',
      'Zone Flussau (fiktiv)',
    ],
    'logistics.hubName': [
      'Verteilzentrum Tannenlicht (fiktiv)',
      'Verteilzentrum Flussau (fiktiv)',
    ],
    // A masked plate: {n} is a two-digit number and {m} the last two digits. A
    // German plate is a district code, one or two letters, and up to four
    // digits; the letters are masked.
    'logistics.vehiclePlate': ['M-●● {n}{m}'],
    'logistics.deliveryNote': [
      'Keine Ablage vor der Tür; bitte persönlich übergeben.',
      'Bitte am Hauseingang klingeln.',
      'Bitte an der Pforte nachfragen.',
    ],
    'logistics.entranceHint': [
      'Hauseingang, Code ••••; Pforte anrufen',
      'Klingel am Eingang benutzen; kein Passwort angezeigt',
    ],
    'logistics.scanEvent': [
      'Ankunft im Verteilzentrum',
      'Verladung im Hauptlauf',
      'In Zustellung',
      'Zustellung abgeschlossen',
      'Zustellung nicht erfolgt',
    ],
    'logistics.carrierLabel': [
      'Beispiel-Zustelldienst A (fiktiv)',
      'Beispiel-Zustelldienst B (fiktiv)',
      'Beispiel-Spedition C (fiktiv)',
    ],
    'logistics.freightType': [
      'Verpackungsmaterial',
      'Lebensmittel',
      'Baumaterial',
      'Elektronikteile',
      'Haushaltswaren',
    ],
    'logistics.routeSummary': [
      'Fiktive Zone Tannenlicht → Zone Flussau',
      'Fiktive Zone Eschenhain → Zone Tannenbach',
    ],
    'logistics.fareItem': [
      'Grundfracht (Beispiel)',
      'Zuschlag Hebebühne (Beispiel)',
      'Zuschlag Handentladung (Beispiel)',
      'Wartezeit (Beispiel)',
    ],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': [
      'Kleiner Pappkarton',
      'Packband 48 mm',
      'Baumwollhandtücher, 3 Stück',
      'Naturreis 2 kg',
    ],
    'logistics.ownerLabel': [
      'Versandunternehmen A (fiktiv)',
      'Versandunternehmen B (fiktiv)',
      'Versandunternehmen C (fiktiv)',
    ],

    // hospitality
    'hospitality.propertyName': [
      'Ferienanlage Kiefernwald (fiktiv)',
      'Erholungshotel Flussau (fiktiv)',
      'Kleine Herberge Eschenhain (fiktiv)',
    ],
    'hospitality.siteName': [
      'Stellplatz Kiefernbrise A (fiktiv)',
      'Stellplatz Kiefernduft B (fiktiv)',
      'Stellplatz Kiefernzapfen C (fiktiv)',
    ],
    'hospitality.amenity': [
      'Eigener Grillplatz',
      'Gemeinschaftsdusche',
      'WLAN',
    ],
    'hospitality.stayOption': [
      'Grillset (Beispiel)',
      'Bündel Brennholz (Beispiel)',
      'Früher Check-in (Beispiel)',
    ],
    'hospitality.seasonName': [
      'Normalsaison',
      'Hochsaison an Feiertagen (Beispiel)',
      'Wochentags-Angebotszeitraum (Beispiel)',
    ],
    'hospitality.ratePlan': [
      'Beispiel-Standardtarif',
      'Beispieltarif mit Frühstück',
      'Beispieltarif für Wochentage',
    ],
    'hospitality.houseRule': [
      'Bitte halten Sie die Gemeinschaftsbereiche nachts ruhig.',
      'Bitte beachten Sie die Beispiel-Checkliste zur Abreise.',
    ],
    'hospitality.reviewSnippet': [
      'Die Hinweise zum Beispielzimmer waren gut lesbar.',
      'Die Hinweise zur fiktiven Unterkunft sind übersichtlich.',
    ],
    'hospitality.hkCheckItem': [
      'Bettwäsche wechseln',
      'Bad reinigen',
      'Ausstattung prüfen',
      'Minibar prüfen',
    ],
    'hospitality.maintenanceIssue': [
      'Prüfung auf Wasserschaden im Bad (Beispiel)',
      'Anfrage zur Prüfung der Beleuchtung (Beispiel)',
      'Prüfung der Heizungsanzeige (Beispiel)',
      'Prüfung auf Möbelschaden (Beispiel)',
    ],
    'hospitality.lostItemName': [
      'Blauer Regenschirm',
      'Grauer Schal',
      'Ein Buch',
      'Wasserflasche',
    ],
    'hospitality.specialRequest': [
      'Hohes Stockwerk, Nichtraucherzimmer (Beispiel)',
      'Wunsch nach zusätzlichem Kissen (Beispiel)',
      'Wunsch nach ruhigem Zimmer (Beispiel)',
    ],
    'hospitality.menuItem': [
      'Algensuppen-Menü',
      'Gemüsepasta',
      'Fruchtjoghurt',
      'Heißer Tee',
    ],
    'hospitality.menuOption': [
      'Weniger Reis',
      'Normale Portion Reis',
      'Extra Beilage (Beispiel)',
      'Ohne Eis',
    ],
    'hospitality.amenityName': ['Handtuch', 'Wasser', 'Zahnbürste', 'Kissen'],
    'hospitality.localSpot': [
      'Suppenstube für den Morgen (fiktiv)',
      'Café in der Gasse (fiktiv)',
      'Spazierweg Tannenlicht (fiktiv)',
    ],
    'hospitality.conciergeReply': [
      'Die Hinweise zur fiktiven Unterkunft stehen in den Aufenthaltsdetails.',
      'Die Anfrage wurde im Beispielregister vermerkt.',
      'Alle Orte in der Nähe sind fiktive Demo-Orte.',
    ],
    'hospitality.folioItem': [
      'Zimmerpreis (Beispiel)',
      'Zimmerservice (Beispiel)',
      'Zusatzoption (Beispiel)',
    ],
  },
  // The texts that German writes as English does: names of countries, cities,
  // and currencies, acronyms and file formats, and the loanwords or the words
  // that are the same in both languages. The language coverage gate reads this
  // list; a text that can be translated is not on it.
  allowSameAsEnglish: <String, List<String>>{
    // The name of a currency, a loyalty tier, and a country is the same word.
    'fx.currencyName.EUR': ['Euro'],
    'fx.tierName': ['Bronze', 'Gold'],
    'remit.countryName.VN': ['Vietnam'],
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.CN': ['China'],
    // The name of a pet, and an animal that has the same name in German.
    'vet.petName': ['Tofu'],
    'vet.breed.small_mammal': ['Hamster'],
    // Cities that German writes as English does.
    'travel_wallet.cityName': ['Osaka', 'Bangkok', 'Hanoi'],
    // Loanwords of a sport, a piece of equipment, and a genre or a medium.
    'fitness.classCategoryLabel': ['Yoga'],
    'fitness.equipment': ['Reformer'],
    'space_rental.amenity': ['Whiteboard'],
    'content.genreName': ['Fantasy', 'Essay'],
    'content.genreTaxonomy': ['Fantasy', 'Essay'],
    'content.audioTaxonomy': ['Podcast'],
    // Words of software work that German keeps: a sprint, a backlog, and the
    // name of a programming language.
    'workplace.sprintName': ['Sprint {n}'],
    'workplace.labelName': ['Backlog'],
    'brokerage.skillTag': ['Dart'],
    // Acronyms, file formats, and the terms of the exam questions that are the
    // same word in German.
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'Router', 'HTTP', 'Variable'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF'],
  },
);
