import '../co_l10n_bundle.dart';

/// French domain text: the French counterpart of every English key, with the
/// same number of texts in the same order, so that one seed picks the same
/// record in English, Korean, and French. See [CoL10nBundle].
///
/// The conventions of the language are in `docs/languages/fr.md`, and the
/// ones that a template has to keep are these:
///
/// - the register is `vous`; a notice or an instruction that says nobody in
///   particular uses `merci de` and the infinitive;
/// - a fictional name ends with `(fictif)` and a sample label with
///   `(exemple)`, and nothing else marks a text as fictional;
/// - a no-break space (` `) stands before `:`, `;`, `?`, `!`, `%`, a unit,
///   and inside `«` `»`, and a narrow one (` `) between thousands;
/// - the apostrophe is `’`;
/// - a template that a value fills never puts `de`, `à`, `le`, or `la` right
///   before the value, because the elision (`d’Inès`) and the contraction
///   (`du`, `au`) depend on the value.
const CoL10nBundle frBundle = CoL10nBundle(
  language: 'fr',
  texts: <String, List<String>>{
    // common
    // The first letter of a given name, as English masks it.
    'common.maskedName': ['{initial}***'],
    'common.taxonomyChild': ['{root} · sous-thème {n}'],

    // fx
    'fx.currencyName.USD': ['Dollar américain'],
    'fx.currencyName.JPY': ['Yen japonais'],
    'fx.currencyName.EUR': ['Euro'],
    'fx.currencyName.CNY': ['Yuan chinois'],
    'fx.currencyName.THB': ['Baht thaïlandais'],
    'fx.currencyName.VND': ['Dông vietnamien'],
    'fx.currencyName.PHP': ['Peso philippin'],
    'fx.currencyName.NPR': ['Roupie népalaise'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      'Bureau de change démo, aéroport T1',
      'Bureau de change démo, Clairval',
      'Bureau de change démo, aéroport T2',
      'Bureau de change démo, Rivebleue',
      'Bureau de change démo, Frênaie',
    ],
    'fx.couponName': [
      'Remise de 80 % sur la marge USD (exemple)',
      'Remise de 70 % sur la marge JPY (exemple)',
      'Remise sur le premier change (exemple)',
    ],
    'fx.tierName': ['Bronze', 'Argent', 'Or'],

    // remit
    'remit.countryName.VN': ['Viêt Nam'],
    'remit.countryName.PH': ['Philippines'],
    'remit.countryName.NP': ['Népal'],
    'remit.countryName.US': ['États-Unis'],
    'remit.countryName.CN': ['Chine'],
    'remit.bankName': ['Banque partenaire Aubeval (fictif)'],
    'remit.flagRule': [
      'Virement de montant élevé (règle de démo)',
      'Vérification de documents supplémentaires (règle de démo)',
      'Vérification de demandes répétées (règle de démo)',
    ],

    // vet
    'vet.petName': ['Orge', 'Papillon', 'Tofu', 'Fève', 'Nuage'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['Bichon maltais', 'Caniche', 'Chien croisé'],
    'vet.breed.cat': ['Européen à poil court', 'Chat croisé'],
    'vet.breed.small_mammal': ['Lapin', 'Hamster'],
    'vet.breed.bird': ['Petite perruche'],
    'vet.breed.reptile': ['Tortue terrestre'],
    'vet.coatColor': ['Blanc', 'Brun', 'Noir', 'Tricolore', 'Gris'],
    'vet.vaccineName': [
      'Vaccin combiné (exemple)',
      'Vaccination antirabique (exemple)',
      'Vaccin combiné félin (exemple)',
    ],
    'vet.preventiveProduct': [
      'Exemple de préventif contre la dirofilariose (fictif)',
      'Exemple de préventif contre les parasites externes (fictif)',
    ],
    'vet.vetDiagnosis': [
      'Observation cutanée (exemple)',
      'Observation digestive (exemple)',
      'Observation de santé courante (exemple)',
    ],
    'vet.vetDrug': [
      'Exemple de soin cutané (fictif)',
      'Exemple de soin digestif (fictif)',
      'Exemple de soin oculaire (fictif)',
    ],
    'vet.clinicRoom': [
      'Salle de consultation vétérinaire 1',
      'Salle de consultation vétérinaire 2',
      'Salle de vaccination',
    ],

    // grocery
    'grocery.originRegion': [
      'Zone de culture de Clairval (fictif)',
      'Zone de culture de Rivebleue (fictif)',
      'Zone de culture de la Plaine (fictif)',
    ],
    'grocery.harvestNote': [
      'Les dates de récolte et de conditionnement sont données à titre d’exemple.',
      'Le texte de fraîcheur décrit un produit fictif.',
    ],
    'grocery.deliveryZone': [
      'Clairval, zone A (démo)',
      'Rivebleue, zone B (démo)',
      'Plaine, zone C (démo)',
    ],
    'grocery.slotLabel': ['Aube, de 6 h à 7 h', 'Soir, de 18 h à 20 h'],
    'grocery.substitutionNote': [
      'Exemple de remplacement par un produit de poids similaire.',
      'Exemple de remboursement sans remplacement.',
    ],
    'grocery.doorNote': [
      'Merci de sonner à l’entrée commune.',
      'Remise en main propre plutôt que dépôt devant la porte.',
    ],
    'grocery.categoryName': [
      'Fruits',
      'Légumes',
      'Plats préparés',
      'Céréales',
      'Viandes',
      'Produits de la mer',
      'Produits laitiers',
    ],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': [
      'Fraises',
      'Épinards',
      'Raviolis faits main',
      'Riz complet',
      'Filet de poulet',
      'Maquereau surgelé',
      'Lait',
    ],
    'catalog.groceryUnit': [
      '500 g',
      '200 g',
      '1 kg',
      '2 kg',
      '500 g',
      '600 g',
      '1 L',
    ],
    'catalog.commerceName': [
      'Écouteurs sans fil',
      'Boîte de rangement pliable',
      'Lot de serviettes en coton',
      'Tasse en céramique',
      'En-cas aux céréales',
    ],
    'catalog.commerceUnit': [
      '1 paire',
      '1 boîte',
      '3 pièces',
      '1 pièce',
      '200 g',
    ],

    // booking
    'booking.cancelReason': [
      'Changement d’agenda (exemple)',
      'Autre créneau choisi (exemple)',
      'Motif personnel (exemple)',
    ],

    // dental
    'dental.dentalProcedure': [
      'Détartrage',
      'Exemple de traitement de canal',
      'Exemple de restauration en résine',
      'Exemple de planification de couronne',
    ],
    'dental.dentalMaterial': [
      'Résine composite (exemple)',
      'Zircone (exemple)',
      'Céramique (exemple)',
    ],
    'dental.chairName': [
      'Fauteuil dentaire 1',
      'Fauteuil dentaire 2',
      'Fauteuil dentaire 3',
    ],
    'dental.hygieneNote': [
      'Exemple de note sur l’explication du brossage.',
      'Exemple de note sur l’observation de l’hygiène bucco-dentaire.',
    ],

    // homecare
    'homecare.careGrade': [
      'Niveau de prise en charge 1',
      'Niveau de prise en charge 2',
      'Niveau de prise en charge 3',
      'Niveau de prise en charge 4',
      'Niveau de prise en charge 5',
      'Niveau d’accompagnement cognitif',
    ],
    'homecare.careTaskLabel': [
      'Aide au repas',
      'Vérification de la prise des médicaments',
      'Aide à l’hygiène',
      'Aide aux déplacements',
      'Accompagnement aux toilettes',
      'Moment de conversation',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      'Échoppe de nouilles de la ruelle (fictif)',
      'Supérette de la gare (fictif)',
      'Auberge du voyageur (fictif)',
    ],
    'travel_wallet.cityName': ['Osaka', 'Tokyo', 'Bangkok', 'Hanoï'],
    'travel_wallet.cardAlias': [
      'Carte voyage escapade (fictif)',
      'Carte budget voyage (fictif)',
    ],
    'travel_wallet.tripName': [
      'Quatre jours à Osaka',
      'Week-end à Bangkok',
      'Balade à pied à Hanoï',
    ],

    // b2b_trade
    'b2b_trade.buyerCompany': [
      'Café Clairval (fictif)',
      'Boulangerie Mil-Grains (fictif)',
      'Épicerie Aulnaie (fictif)',
    ],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      'Gobelets en carton 35 cl, lot de 1 000',
      'Pommes de terre surgelées, 10 kg',
      'Sacs en papier, lot de 100',
      'Lingettes hygiéniques non parfumées, lot de 20',
    ],
    'b2b_trade.quoteTitle': [
      'Devis mensuel d’emballages (fictif)',
      'Devis hebdomadaire de produits alimentaires (fictif)',
      'Devis de produits d’hygiène (fictif)',
    ],
    'b2b_trade.holdReason': [
      'Vérification de l’encours disponible (exemple)',
      'Vérification de la date de livraison (exemple)',
      'Vérification des caractéristiques de l’article (exemple)',
    ],

    // group_deal
    'group_deal.dealTitle': [
      'Achat groupé d’agrumes d’hiver',
      'Achat groupé d’écouteurs sans fil',
      'Achat groupé de serviettes en coton',
    ],
    'group_deal.optionLabel': [
      'Taille standard',
      'Emballage cadeau',
      'Couleur standard',
    ],
    'group_deal.rewardLabel': [
      'Tampon de participation',
      'Points de récompense fictifs',
      'Avantage de livraison',
    ],
    'group_deal.benefitTitle': [
      'Exemple de bon de livraison gratuite',
      'Exemple de bon pour le prochain achat groupé',
    ],
    'group_deal.settleNote': [
      'Exemple de total des participations validées.',
      'Exemple de total hors participations annulées.',
    ],

    // fitness
    // A class name from the category label and the level label of the same
    // record: the level label stays after the word `niveau`, so that it needs
    // no agreement with the category.
    'fitness.className': ['{category}, niveau {level}'],
    'fitness.classCategoryLabel': ['Tapis', 'Reformer', 'Chaise', 'Yoga'],
    'fitness.classLevelLabel': ['débutant', 'intermédiaire', 'avancé'],
    'fitness.equipment': ['Tapis', 'Reformer', 'Chaise', 'Bloc de yoga'],
    'fitness.studioRoom': [
      'Salle Pilates tapis',
      'Salle Reformer',
      'Salle Pilates chaise',
      'Salle de yoga',
    ],
    'fitness.instructorSpecialty': [
      'Cours de tapis',
      'Cours de Reformer',
      'Cours de yoga',
    ],
    'fitness.passName': [
      'Carte de 10 cours de tapis (exemple)',
      'Carte de 20 cours de Reformer (exemple)',
      'Abonnement mensuel (exemple)',
    ],
    'fitness.cancelReason': [
      'Changement d’emploi du temps',
      'Changement d’horaire du cours',
    ],
    'fitness.noShowNote': [
      'Exemple de fiche sans confirmation de présence.',
      'Exemple de marquage d’absence après le début du cours.',
    ],

    // space_rental
    'space_rental.spaceName': [
      'Salle de fête Quatre Heures (fictif)',
      'Salle d’étude Clairval (fictif)',
      'Salle de répétition Rivebleue (fictif)',
    ],
    'space_rental.districtName': [
      'Ville fictive, quartier Clairval',
      'Ville fictive, quartier Rivebleue',
      'Ville fictive, quartier Frênaie',
    ],
    'space_rental.amenity': ['Wi-Fi', 'Tableau blanc', 'Fontaine à eau'],
    'space_rental.equipmentOption': [
      'Vidéoprojecteur (exemple)',
      'Matériel de sonorisation (exemple)',
      'Une place de parking (exemple)',
    ],
    'space_rental.houseRule': [
      'Merci de ranger le matériel après usage.',
      'Merci de respecter l’horaire réservé.',
    ],
    'space_rental.bookingPurpose': [
      'Séance d’étude en groupe',
      'Rencontre entre amis',
      'Répétition de groupe',
    ],
    'space_rental.guestMessage': [
      'Pourrais-je savoir comment utiliser le matériel ?',
      'Pourriez-vous m’envoyer les instructions d’accès ?',
    ],
    'space_rental.hostReply': [
      'Merci de consulter le guide du matériel sur la page de réservation.',
      'Les instructions d’accès figurent dans le détail de la réservation.',
    ],

    // dining
    'dining.restaurantName': [
      'Maison de nouilles au périlla (fictif)',
      'Restaurant de pâtes de la Ruelle (fictif)',
      'Salon de thé Clairval (fictif)',
    ],
    'dining.menuName': [
      'Nouilles au périlla',
      'Pâtes à la tomate',
      'Bol de riz aux légumes',
      'Thé chaud',
    ],
    // A table is `Table pour 1`, `Table pour 4`: no plural to agree.
    'dining.partyLabel': ['Table pour {n}'],
    'dining.noShowNote': [
      'Exemple de fiche d’attente sans confirmation d’arrivée.',
      'Exemple d’absence après l’heure annoncée.',
    ],
    'dining.loyaltyBenefit': [
      'Boisson offerte à la cinquième visite (exemple)',
      'Bon dessert pour client fidèle (exemple)',
    ],
    'dining.districtName': [
      'Ville fictive, quartier Clairval',
      'Ville fictive, quartier Rivebleue',
    ],

    // daycare
    'daycare.childName': ['Lou', 'Noé', 'Éva', 'Léon', 'Zoé'],
    'daycare.className': [
      'Classe du Soleil',
      'Classe de la Lune',
      'Classe des Étoiles',
    ],
    'daycare.ageLabel': ['1 an', '2 ans', '3 ans', '4 ans', '5 ans'],
    // {name1} is the first given name drawn: no preposition stands before it,
    // because `de` would have to elide before a name that starts with a vowel.
    'daycare.guardianLabel': ['{name1} (responsable légal)'],
    // The name is drawn without a sex, so the title takes both forms.
    'daycare.teacherName': ['Enseignant(e) {name1}'],
    'daycare.toiletNote': [
      'Un passage aux toilettes noté (exemple)',
      'Deux passages aux toilettes notés (exemple)',
      'Aucune note (exemple)',
    ],
    'daycare.mealMenu': [
      'Riz complet et ragoût de légumes',
      'Soupe au tofu et riz',
      'Riz sauté aux légumes',
    ],
    'daycare.snackMenu': [
      'Quartiers de poire',
      'Patate douce à la vapeur',
      'Yaourt nature',
    ],
    'daycare.allergenLabel': [
      'Lait',
      'Œuf',
      'Soja',
      'Blé',
      'Aucun signalé (exemple)',
    ],
    'daycare.activityTitle': [
      'Jeux d’hiver dans la neige',
      'Fabrication de maisons en papier',
      'Jeu de blocs de couleur',
    ],
    'daycare.albumCaption': [
      'Illustration fictive d’enfants empilant des blocs ensemble',
      'Illustration fictive de jeux d’hiver',
    ],
    'daycare.drugLabel': [
      'Sirop contre la fièvre (fictif)',
      'Sirop contre la toux (fictif)',
      'Topique hydratant (fictif)',
    ],
    'daycare.dosageLabel': [
      'Exemple saisi par le responsable légal : 2 mL',
      'Exemple saisi par le responsable légal : 3 mL',
      'Exemple saisi par le responsable légal : faible quantité',
    ],
    'daycare.noticeTitle': [
      'Avis sur les jeux d’hiver (exemple)',
      'Avis de changement de menu (exemple)',
      'Avis de contrôle de sécurité (exemple)',
    ],

    // exam_prep
    'exam_prep.subjectName': [
      'Bases de données',
      'Bases de données',
      'Réseaux',
      'Réseaux',
      'Réseaux',
      'Bases de la programmation',
      'Bases de la programmation',
      'Sécurité de l’information',
      'Sécurité de l’information',
    ],
    'exam_prep.unitName': [
      'Modélisation des données',
      'Bases de SQL',
      'Couche transport',
      'Routage',
      'Couche application',
      'Variables',
      'Structures de données',
      'Bases de la cryptographie',
      'Contrôle d’accès',
    ],
    'exam_prep.questionStem': [
      'Quelle clé permet de distinguer les lignes d’une table ?',
      'Quelle clause SQL permet de sélectionner des lignes selon une condition ?',
      'Quel protocole de transport gère l’ordre et la retransmission des données ?',
      'Quel équipement choisit le prochain chemin d’un paquet ?',
      'Quel protocole sert à exprimer les requêtes et les réponses web ?',
      'Qu’est-ce qui permet de stocker une valeur sous un nom dans un programme ?',
      'Quelle structure retire en premier la dernière valeur insérée ?',
      'Qu’est-ce qui calcule une empreinte de longueur fixe à partir d’une entrée ?',
      'Quel principe n’accorde que les droits nécessaires à une tâche ?',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      'Clé primaire',
      'WHERE',
      'TCP',
      'Routeur',
      'HTTP',
      'Variable',
      'Pile',
      'Fonction de hachage',
      'Moindre privilège',
    ],
    'exam_prep.wrongChoice1': [
      'Police',
      'Police',
      'JPEG',
      'Haut-parleur',
      'PNG',
      'Bordure',
      'File FIFO',
      'Choix de la police',
      'Accès public',
    ],
    'exam_prep.wrongChoice2': [
      'Couleur d’arrière-plan',
      'Marge',
      'CSS',
      'Clavier',
      'MP3',
      'Marge de page',
      'Image',
      'Zoom de l’écran',
      'Mot de passe partagé',
    ],
    'exam_prep.wrongChoice3': [
      'Largeur d’écran',
      'Icône',
      'SVG',
      'Écran',
      'TTF',
      'Image d’arrière-plan',
      'Fichier audio',
      'Remplissage d’arrière-plan',
      'Vérifications ignorées',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    'exam_prep.explanation': [
      'Une clé primaire identifie chaque ligne d’une table.',
      'La clause WHERE exprime une condition pour sélectionner des lignes.',
      'TCP gère l’ordre et la retransmission d’un flux d’octets.',
      'Un routeur choisit le prochain chemin à partir de l’adresse de destination.',
      'HTTP exprime les requêtes et les réponses web.',
      'Une variable permet à un programme de désigner une valeur par son nom.',
      'Une pile retire en premier la dernière valeur insérée.',
      'Une fonction de hachage calcule une empreinte de longueur fixe à partir d’une entrée.',
      'Le moindre privilège n’accorde que les droits nécessaires à une tâche.',
    ],
    'exam_prep.examPaperTitle': [
      'Sujet d’entraînement 1 (fictif)',
      'Sujet d’entraînement 2 (fictif)',
      'Contrôle de fin d’unité (fictif)',
    ],
    'exam_prep.studyTaskTitle': [
      'Résoudre dix questions sur la couche transport',
      'Revoir les erreurs sur le contrôle d’accès',
      'Vérifier les bases de SQL',
    ],
    'exam_prep.taxonomyName': [
      'Bases de données',
      'Réseaux',
      'Bases de la programmation',
      'Sécurité de l’information',
    ],

    // hrd
    'hrd.departmentName': [
      'Ventes',
      'Fabrication',
      'Recherche',
      'Support client',
      'Gestion administrative',
      'Logistique',
    ],
    'hrd.jobTitle': ['Collaborateur', 'Responsable', 'Chef d’équipe'],
    'hrd.courseTitle': [
      'Gérer les données personnelles en 2026 (fictif)',
      'Travailler ensemble en sécurité (fictif)',
      'Organiser les dossiers de travail (fictif)',
    ],
    'hrd.courseKind': ['Obligatoire', 'Métier', 'Encadrement'],
    'hrd.lessonTitle': [
      'Comprendre les principes de base',
      'Examiner des exemples de travail',
      'Vérifier les documents de suivi',
    ],
    'hrd.chapterTitle': ['Présentation', 'Revue d’exemples', 'Synthèse'],
    'hrd.nudgeTitle': [
      'Rappel d’échéance de formation (exemple)',
      'Rappel de leçon inachevée (exemple)',
    ],
    'hrd.exemptionReason': [
      'Justificatif de formation externe (exemple)',
      'Vérification de la période de congé (exemple)',
      'Vérification d’une formation équivalente (exemple)',
    ],
    'hrd.classroomPlace': [
      'Salle de formation Clairval (fictif)',
      'Salle de séminaire Rivebleue (fictif)',
    ],

    // neighborhood
    'neighborhood.neighborhoodName': [
      'Quartier Clairval (fictif)',
      'Quartier du Ginkgo (fictif)',
      'Quartier Frênaie (fictif)',
    ],
    'neighborhood.districtName': [
      'Ville fictive, quartier Rivebleue',
      'Ville fictive, quartier Aulnaie',
    ],
    'neighborhood.nickname': [
      'PoisClairval (fictif)',
      'EtoileFrenaie (fictif)',
      'NuageDeRuelle (fictif)',
    ],
    'neighborhood.postTitle': [
      'Gant bleu trouvé sur l’aire de jeux (exemple)',
      'À la découverte d’une balade dans le quartier (exemple)',
      'Partage d’une petite jardinière (exemple)',
    ],
    'neighborhood.postBody': [
      'Actualité fictive du quartier. Les détails figurent dans cette publication.',
      'Exemple de publication pour les voisins ; aucun numéro de téléphone ni adresse réelle n’est indiqué.',
    ],
    'neighborhood.commentBody': [
      'Merci d’avoir partagé cette nouvelle.',
      'Je vérifie et je réponds dans la publication.',
      'Je peux vérifier en soirée.',
    ],
    'neighborhood.placeName': [
      'Boulangerie Clairval (fictif)',
      'Abri du parc de Rivebleue (fictif)',
      'Petite bibliothèque Frênaie (fictif)',
    ],
    'neighborhood.openHours': [
      'De 8 h à 21 h',
      'De 9 h à 18 h',
      'De 10 h à 20 h',
    ],
    'neighborhood.bannedWord': [
      'publicité-exemple',
      'insulte-exemple',
      'mot-interdit-exemple',
    ],
    'neighborhood.keyword': ['gant', 'balade', 'partage', 'actualités locales'],

    // meetup
    'meetup.clubName': [
      'Course matinale de Clairval (fictif)',
      'Cercle de lecture de Rivebleue (fictif)',
      'Jeux de société de Frênaie (fictif)',
    ],
    'meetup.interestTag': [
      'Course à pied',
      'Lecture',
      'Jeux de société',
      'Photographie',
      'Cuisine',
      'Randonnée',
    ],
    'meetup.clubIntro': [
      'Groupe fictif qui accueille les voisins qui participent pour la première fois.',
      'Groupe d’exemple pour partager ensemble de petites activités.',
    ],
    'meetup.gatheringTitle': [
      'Rencontre de la troisième semaine de janvier (fictif)',
      'Discussion littéraire du week-end (fictif)',
      'Balade hivernale entre voisins (fictif)',
    ],
    'meetup.venueName': [
      'Entrée du sentier de Rivebleue (fictif)',
      'Salle de réunion Clairval (fictif)',
      'Abri de Frênaie (fictif)',
    ],
    'meetup.nickname': [
      'PoisAube (fictif)',
      'NuageLivre (fictif)',
      'PetiteEtoile (fictif)',
    ],
    'meetup.duesItem': [
      'Participation à la rencontre (exemple)',
      'Boissons partagées (exemple)',
      'Location de matériel partagée (exemple)',
    ],
    'meetup.joinAnswer': [
      'J’aimerais participer aux activités dès ce mois-ci.',
      'Je peux participer le week-end le matin.',
    ],
    'meetup.ruleText': [
      'Merci de respecter le temps de chacun.',
      'Merci d’échanger au sein du groupe sans publier de coordonnées.',
      'Merci de prévenir le groupe en cas d’annulation.',
    ],
    'meetup.cadenceLabel': [
      'Chaque samedi à 7 h',
      'Un dimanche sur deux à 10 h',
      'Premier samedi du mois à 14 h',
    ],

    // fandom
    // The two approved fictional creators of the fandom pack: French writes two
    // names of its own, never the Korean ones.
    'fandom.creatorName': ['Jardin du Sablier', 'Ciel de Lin'],
    'fandom.fanNickname': [
      'Petite étoile',
      'Jeune pousse',
      'Pois lunaire',
      'Goutte de lumière',
    ],
    'fandom.benefitTitle': [
      'Exemple d’image réservée aux membres',
      'Inscription simulée à un événement',
      'Avant-première d’un extrait fictif',
    ],
    'fandom.postCaption': [
      'Illustration fictive d’un atelier en hiver',
      'Exemple de publication sur le temps de répétition',
    ],
    'fandom.clipTitle': [
      'Répétition de trente secondes (fictif)',
      'Salut depuis l’atelier (fictif)',
      'Note sonore d’hiver (fictif)',
    ],
    'fandom.letterBody': [
      'J’ai aimé la publication d’exemple du jour et j’attends la suite avec impatience.',
      'L’illustration de l’atelier d’hiver m’a semblé chaleureuse. Je vous envoie mes encouragements.',
    ],
    'fandom.eventTitle': [
      'Rencontre d’hiver entre fans (fictif)',
      'Soirée histoires d’atelier (fictif)',
    ],
    'fandom.agendaTitle': [
      'Programme du petit théâtre d’hiver (fictif)',
      'Conversation fictive diffusée en direct',
      'Calendrier de sortie des nouvelles publications',
    ],
    'fandom.venueLabel': [
      'Petit théâtre d’hiver (fictif)',
      'Atelier Clairval (fictif)',
      'Espace en ligne d’exemple',
    ],

    // content
    'content.seriesTitle': [
      'L’île postale du phare de papier (fictif)',
      'La petite carte de l’étang des nuages (fictif)',
      'Le jardin de l’horloge lente (fictif)',
    ],
    'content.penName': [
      'Pois des Mots (fictif)',
      'Étoile de Papier (fictif)',
      'Plume de Nuage (fictif)',
    ],
    'content.synopsisLine': [
      'Des personnages fictifs trient des lettres sur une petite île.',
      'Une histoire fictive sur le dessin d’un étang absent de la carte.',
    ],
    'content.genreName': [
      'Fantasy',
      'Vie quotidienne',
      'Aventure',
      'Récits scientifiques',
      'Essai',
    ],
    'content.episodeTitle': [
      'Le premier bateau en papier (fictif)',
      'Un petit point sur l’étang (fictif)',
      'Un après-midi sans horloge (fictif)',
    ],
    'content.cutAltText': [
      'Illustration d’un personnage fictif pliant un bateau en papier',
      'Illustration de deux personnages fictifs au bord d’un étang',
    ],
    'content.commentLine': [
      'La scène du bateau en papier m’est restée en mémoire.',
      'J’aimerais lire le prochain épisode d’exemple.',
    ],
    'content.chapterParagraph': [
      'Une feuille blanche reposait dans la boîte aux lettres de l’île. Un enfant la plia en un petit bateau qui ressemblait à l’étang. Ce paragraphe est un exemple de démonstration fictif et original.',
      'Une petite jardinière se tenait près de l’horloge lente. Au lieu de nommer la plante, deux amis dessinèrent les nuages qu’ils avaient vus. Ceci est un paragraphe d’exemple fictif et original.',
    ],
    'content.publisherName': [
      'Éditions Phare de Papier (fictif)',
      'Éditions Étang des Nuages (fictif)',
    ],
    'content.audioTitle': [
      'Un après-midi à plier des bateaux en papier (fictif)',
      'Notes sonores d’un petit étang (fictif)',
    ],
    'content.newsletterName': [
      'Notes hebdomadaires du Phare de Papier (fictif)',
      'Petites lettres de l’Étang des Nuages (fictif)',
    ],
    'content.articleHeadline': [
      'Classer ses notes du quotidien en petits groupes (fictif)',
      'Garder trace des couleurs d’une balade d’hiver (fictif)',
    ],
    'content.topicName': [
      'Notes du quotidien',
      'Balades d’hiver',
      'Petite science',
      'Habitudes de lecture',
    ],
    'content.genreTaxonomy': [
      'Fantasy',
      'Vie quotidienne',
      'Aventure',
      'Récits scientifiques',
      'Essai',
    ],
    'content.audioTaxonomy': ['Livre audio', 'Podcast'],
    'content.topicTaxonomy': [
      'Notes du quotidien',
      'Balades d’hiver',
      'Petite science',
      'Habitudes de lecture',
      'Observations de la vie courante',
    ],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      'Merci de vérifier l’état de l’invitation d’équipe',
      'Question sur les lignes d’une facture d’exemple',
      'Erreur d’exportation CSV d’exemple',
      'Question sur l’état de l’intégration',
      'Question sur un bouton d’un écran d’exemple',
      'Question sur l’endroit où trouver l’aide',
    ],
    'helpdesk.ticketDescription': [
      'Le compte de support fictif affiche une invitation en attente.',
      'Je souhaite vérifier les lignes et la période de la facture fictive.',
      'Un état d’erreur apparaît lors de l’exportation des données d’exemple au format CSV.',
      'Je souhaite vérifier la formulation de la page d’état de l’intégration fictive.',
      'L’écran d’exemple reste identique après avoir appuyé sur un bouton.',
      'Où puis-je trouver la page d’aide du support fictif ?',
    ],
    'helpdesk.macroName': [
      'Accusé de réception d’exemple',
      'Demande d’informations complémentaires',
      'Avis sur l’état du traitement',
    ],
    'helpdesk.helpArticleTitle': [
      'Guide d’invitation d’exemple',
      'Lire une facture fictive',
      'Exporter des données CSV d’exemple',
    ],
    'helpdesk.csatComment': [
      'J’ai pris connaissance de l’explication.',
      'Les instructions d’exemple étaient faciles à suivre.',
      'J’ai des détails supplémentaires à vérifier.',
    ],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      'Vérifiez l’état de l’invitation dans les paramètres du compte. Ce brouillon d’IA simulé doit être relu par un conseiller.',
      'Notez ensemble la méthode de connexion et l’erreur d’exemple. Ce brouillon d’IA simulé ne modifie aucun compte.',
      'Vérifiez la période et les lignes de la facture d’exemple. Ce brouillon d’IA simulé décrit des prix fictifs.',
      'Indiquez le numéro de la facture d’exemple dans la note de support. Ce brouillon d’IA simulé n’est pas un véritable avis de paiement.',
      'Vérifiez la période et le format choisis pour l’exportation. Ce brouillon d’IA simulé consigne une erreur d’exemple sans donnée personnelle.',
      'Vérifiez les noms de colonnes et l’état du fichier dans le CSV d’exemple. Ce brouillon d’IA simulé doit être relu par un conseiller.',
      'Notez l’état d’intégration d’exemple et l’heure de la vérification. Ce brouillon d’IA simulé n’effectue aucun appel externe.',
      'Notez l’écran concerné et les étapes pour reproduire le problème. Ce brouillon d’IA simulé ne promet aucun résultat.',
    ],
    'helpdesk.topicName': ['Compte', 'Facturation', 'Données', 'Intégration'],

    // campaign
    'campaign.brandName': [
      'Boulangerie Aube de Printemps (fictif)',
      'Librairie Lune Douce (fictif)',
      'Café Verdure Claire (fictif)',
    ],
    'campaign.campaignTitle': [
      'Exemple d’offre d’hiver',
      'Exemple d’actualité pour une première visite',
      'Exemple d’actualité du week-end',
    ],
    'campaign.offerCopy': [
      '(Pub) Exemple de bon pour un menu d’hiver fictif. Pour vous désabonner, consultez les réglages de démonstration.',
      '(Pub) Exemple d’offre pour un produit fictif. Le désabonnement se trouve dans les réglages de démonstration.',
    ],
    'campaign.couponTitle': [
      'Bon d’exemple de 20 % pour l’hiver',
      'Bon d’exemple de 10 % pour une première visite',
    ],
    'campaign.segmentName': [
      'Acheteurs d’exemple des 30 derniers jours',
      'Groupe d’exemple ayant donné son accord',
      'Groupe d’exemple pour les actualités du week-end',
    ],
    'campaign.failReason': [
      'Numéro du destinataire manquant (exemple)',
      'Aucun consentement marketing (exemple)',
      'Aucun consentement pour l’envoi de nuit (exemple)',
    ],

    // workplace
    'workplace.department': [
      'Équipe front-end',
      'Équipe back-end',
      'Équipe design',
      'Support client',
      'Ressources humaines',
    ],
    'workplace.position': ['Collaborateur', 'Responsable', 'Chef d’équipe'],
    'workplace.workPlace': [
      'Bureau Clairval (fictif)',
      'Centre de travail Rivebleue (fictif)',
      'Télétravail',
    ],
    'workplace.shiftName': [
      'Poste de jour',
      'Poste du matin',
      'Permanence du week-end',
    ],
    'workplace.approvalComment': [
      'J’ai examiné le justificatif d’exemple joint.',
      'Le motif d’exemple doit être précisé.',
    ],
    'workplace.projectName': [
      'Refonte du portail client (fictif)',
      'Nettoyage du wiki interne (fictif)',
      'Exemple d’amélioration de l’accessibilité',
    ],
    'workplace.workItemTitle': [
      'Améliorer le message d’erreur de connexion',
      'Vérifier le tri du tableau d’exemple',
      'Clarifier l’affichage de l’état des notifications',
    ],
    'workplace.labelName': ['Textes', 'Accessibilité', 'Backlog', 'À vérifier'],
    'workplace.milestoneTitle': [
      'Jalon de première revue',
      'Écran d’exemple terminé',
      'Vérification de non-régression',
    ],
    'workplace.sprintName': ['Sprint {n}'],
    'workplace.commentBody': [
      'Je laisse mes remarques après avoir vérifié l’écran d’exemple.',
      'Merci de relire la formulation avant la prochaine tâche.',
    ],
    'workplace.merchantName': [
      'Restaurant Fleurs Sauvages (fictif)',
      'Casse-croûte de la Ruelle (fictif)',
      'Fournitures de bureau Clairval (fictif)',
    ],
    'workplace.accountName': [
      'Repas (exemple)',
      'Transports (exemple)',
      'Réunions (exemple)',
      'Fournitures (exemple)',
      'Déplacements (exemple)',
      'Autres (exemple)',
    ],
    'workplace.rejectReasonText': [
      'Justificatif d’exemple manquant',
      'Classement de la dépense à vérifier',
      'Plafond de la politique d’exemple à vérifier',
    ],

    // brokerage
    'brokerage.projectTitle': [
      'Exemple de création d’un portail client',
      'Refonte fictive d’un écran de service',
      'Exemple de création d’un écran de réservation',
    ],
    'brokerage.serviceCategory': [
      'Interface web',
      'Interface d’application',
      'Design professionnel',
      'Services à domicile',
    ],
    'brokerage.providerName': [
      'Studio Grenier du Code (fictif)',
      'Atelier d’interfaces Clairval (fictif)',
      'Atelier du quotidien Rivebleue (fictif)',
    ],
    'brokerage.providerHeadline': [
      'Partenaire fictif présentant des écrans d’exemple et un historique de travaux',
      'Profil d’exemple pour examiner le périmètre d’un projet fictif',
    ],
    'brokerage.skillTag': [
      'Dart',
      'Conception d’interfaces',
      'Organisation des données',
      'Rédaction de textes',
    ],
    'brokerage.proposalMessage': [
      'Périmètre et jalons de planning préparés pour l’exemple.',
      'Je propose des points de contrôle pour les étapes du projet fictif.',
    ],
    'brokerage.portfolioTitle': [
      'Exemple fictif de portail client',
      'Exemple de fiche d’écran de réservation',
      'Amélioration fictive d’un tableau de travail',
    ],
    'brokerage.milestoneLabel': [
      'Validation du périmètre',
      'Validation de la maquette',
      'Validation d’une fonction d’exemple',
      'Compte rendu de passation',
    ],
    'brokerage.homeServiceName': [
      'Nettoyage de climatiseur (exemple)',
      'Petit déménagement (exemple)',
      'Vérification de robinet (exemple)',
      'Cours d’instrument pour débutant (exemple)',
    ],
    'brokerage.requestAnswer': [
      'Je souhaiterais vérifier le périmètre avant la visite.',
      'Le créneau d’exemple est un matin de week-end.',
    ],
    'brokerage.regionDong': [
      'Ville fictive, quartier Clairval',
      'Ville fictive, quartier Rivebleue',
      'Ville fictive, quartier Frênaie',
    ],
    'brokerage.reviewText': [
      'J’ai consulté le compte rendu de travaux d’exemple et les consignes.',
      'Les consignes de planning d’exemple étaient faciles à suivre.',
    ],
    'brokerage.creditLabel': [
      'Crédit pour l’envoi d’un devis (exemple)',
      'Crédit de remboursement pour devis non consulté (exemple)',
      'Crédit de recharge (exemple)',
    ],
    'brokerage.advisorTitle': [
      'Spécialiste fiscal fictif',
      'Spécialiste juridique fictif',
      'Spécialiste du droit du travail fictif',
    ],
    'brokerage.consultTopic': [
      'Exemple d’explication de terminologie',
      'Exemple de liste de points à vérifier avant la consultation',
      'Exemple d’explication d’une liste de documents',
    ],
    'brokerage.qnaQuestion': [
      'Que signifie ce terme du dispositif ? (question fictive)',
      'Quels champs figurent dans une fiche de consultation ? (question fictive)',
    ],
    // Every text starts with the general-information prefix of the language
    // (`test/language_safety/fr.dart`) and promises no result.
    'brokerage.qnaAnswerGeneric': [
      'Information générale à titre d’exemple. Un aperçu du dispositif peut lister des termes, un périmètre et des documents. Il ne contient aucun jugement sur un cas particulier.',
      'Information générale à titre d’exemple. Une fiche de consultation distingue les questions des documents de référence. Aucun résultat précis ni aucune marche à suivre n’est indiqué.',
    ],
    'brokerage.consultNoteGeneric': [
      'Information générale, note d’exemple : sujet de la question et termes du dispositif présentés. La liste de documents se compose d’éléments explicatifs fictifs.',
      'Information générale, note d’exemple : format de la fiche de consultation passé en revue. Aucune conclusion ni aucun conseil sur un cas particulier.',
    ],
    'brokerage.officeName': [
      'Cabinet de consultation Clairval (fictif)',
      'Bureau de documentation Rivebleue (fictif)',
    ],
    'brokerage.serviceTypeName': [
      'Nettoyage',
      'Déménagement',
      'Réparation',
      'Cours',
    ],

    // logistics
    'logistics.zoneName': [
      'Zone 1 Aulnaie (fictif)',
      'Zone 2 Aulnaie (fictif)',
      'Zone Rivebleue (fictif)',
    ],
    'logistics.hubName': [
      'Plateforme logistique Clairval (fictif)',
      'Plateforme logistique Rivebleue (fictif)',
    ],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // The shape is the old French one, digits, letters, and the number of the
    // department; the plate stays masked with `●●`.
    'logistics.vehiclePlate': ['{n}●● AB {m}'],
    'logistics.deliveryNote': [
      'Pas de dépôt sans surveillance ; remise en main propre.',
      'Merci de sonner à l’entrée commune.',
      'Merci de passer par la loge du gardien.',
    ],
    'logistics.entranceHint': [
      'Entrée commune n° •••• ; appeler la loge',
      'Utiliser l’interphone de l’entrée ; aucun code affiché',
    ],
    'logistics.scanEvent': [
      'Arrivée à la plateforme',
      'Chargement longue distance',
      'En cours de livraison',
      'Livraison effectuée',
      'Livraison non effectuée',
    ],
    'logistics.carrierLabel': [
      'Transporteur d’exemple A (fictif)',
      'Transporteur d’exemple B (fictif)',
      'Transporteur de fret d’exemple C (fictif)',
    ],
    'logistics.freightType': [
      'Emballages',
      'Denrées alimentaires',
      'Matériaux de construction',
      'Composants électroniques',
      'Articles ménagers',
    ],
    'logistics.routeSummary': [
      'Zone fictive Clairval → zone Rivebleue',
      'Zone fictive Frênaie → zone Aulnaie',
    ],
    'logistics.fareItem': [
      'Tarif de base (exemple)',
      'Supplément hayon élévateur (exemple)',
      'Manutention manuelle (exemple)',
      'Temps d’attente (exemple)',
    ],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': [
      'Petite boîte en carton',
      'Ruban adhésif d’emballage 48 mm',
      'Serviettes en coton, 3 pièces',
      'Riz complet 2 kg',
    ],
    'logistics.ownerLabel': [
      'Chargeur A (fictif)',
      'Chargeur B (fictif)',
      'Chargeur C (fictif)',
    ],

    // hospitality
    'hospitality.propertyName': [
      'Domaine des Pins (fictif)',
      'Hôtel de repos Rivebleue (fictif)',
      'Petite auberge Frênaie (fictif)',
    ],
    'hospitality.siteName': [
      'Emplacement Brise des Pins A (fictif)',
      'Emplacement Parfum de Pin B (fictif)',
      'Emplacement Pomme de Pin C (fictif)',
    ],
    'hospitality.amenity': [
      'Espace barbecue privé',
      'Salle de douche commune',
      'Wi-Fi',
    ],
    'hospitality.stayOption': [
      'Kit de barbecue (exemple)',
      'Lot de bûches (exemple)',
      'Arrivée anticipée (exemple)',
    ],
    'hospitality.seasonName': [
      'Période standard',
      'Haute saison des vacances (exemple)',
      'Période de tarif semaine (exemple)',
    ],
    'hospitality.ratePlan': [
      'Tarif standard d’exemple',
      'Tarif d’exemple petit-déjeuner inclus',
      'Tarif d’exemple en semaine',
    ],
    'hospitality.houseRule': [
      'Merci de respecter le calme dans les espaces communs la nuit.',
      'Merci de consulter la liste de contrôle de départ d’exemple.',
    ],
    'hospitality.reviewSnippet': [
      'Les consignes d’exemple de la chambre étaient faciles à lire.',
      'Les consignes de l’hébergement fictif sont bien organisées.',
    ],
    'hospitality.hkCheckItem': [
      'Changer la literie',
      'Nettoyer la salle de bain',
      'Vérifier les produits d’accueil',
      'Vérifier le minibar',
    ],
    'hospitality.maintenanceIssue': [
      'Contrôle d’une fuite dans la salle de bain (exemple)',
      'Demande de contrôle de l’éclairage (exemple)',
      'Vérification de l’affichage du chauffage (exemple)',
      'Contrôle de meubles endommagés (exemple)',
    ],
    'hospitality.lostItemName': [
      'Parapluie bleu',
      'Écharpe grise',
      'Un livre',
      'Bouteille d’eau',
    ],
    'hospitality.specialRequest': [
      'Étage élevé, non-fumeur (exemple)',
      'Demande d’oreiller supplémentaire (exemple)',
      'Demande de chambre calme (exemple)',
    ],
    'hospitality.menuItem': [
      'Menu soupe aux algues',
      'Pâtes aux légumes',
      'Yaourt aux fruits',
      'Thé chaud',
    ],
    'hospitality.menuOption': [
      'Moins de riz',
      'Portion de riz normale',
      'Accompagnement supplémentaire (exemple)',
      'Sans glaçons',
    ],
    'hospitality.amenityName': [
      'Serviette',
      'Eau',
      'Brosse à dents',
      'Oreiller',
    ],
    'hospitality.localSpot': [
      'Soupes du matin (fictif)',
      'Café de la Ruelle (fictif)',
      'Sentier de Clairval (fictif)',
    ],
    'hospitality.conciergeReply': [
      'Les consignes de l’hébergement fictif figurent dans le détail du séjour.',
      'La demande a été enregistrée dans le registre d’exemple.',
      'Les lieux à proximité sont tous des lieux de démonstration fictifs.',
    ],
    'hospitality.folioItem': [
      'Tarif de la chambre (exemple)',
      'Service en chambre (exemple)',
      'Option supplémentaire (exemple)',
    ],
  },
  // The texts of French that read like the English ones on purpose: names of
  // currencies, countries, and cities, acronyms and file formats, loanwords
  // that French shares with English (`Reformer`, `Backlog`, `Sprint`), and
  // the Wi-Fi of an amenity. The language coverage gate reads this list.
  allowSameAsEnglish: <String, List<String>>{
    'fx.currencyName.EUR': ['Euro'],
    'fx.tierName': ['Bronze'],
    // The name of the country is spelled the same.
    'remit.countryName.PH': ['Philippines'],
    // A name of a pet, and an animal that has the same name in both languages.
    'vet.petName': ['Tofu'],
    'vet.breed.small_mammal': ['Hamster'],
    // Names of cities that French spells as English does.
    'travel_wallet.cityName': ['Osaka', 'Tokyo', 'Bangkok'],
    'space_rental.amenity': ['Wi-Fi'],
    'hospitality.amenity': ['Wi-Fi'],
    // The name of a Pilates apparatus and of a discipline.
    'fitness.classCategoryLabel': ['Reformer', 'Yoga'],
    'fitness.equipment': ['Reformer'],
    // Acronyms and file formats of the exam questions, and the word
    // `variable`, which is the same in both languages.
    'exam_prep.unitName': ['Variables'],
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'HTTP', 'Variable'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3', 'Image'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF'],
    // Names of genres and formats that French writes as English does.
    'content.genreName': ['Fantasy'],
    'content.genreTaxonomy': ['Fantasy'],
    'content.audioTaxonomy': ['Podcast'],
    // The name of a programming language.
    'brokerage.skillTag': ['Dart'],
    // Agile vocabulary that French teams keep in English.
    'workplace.labelName': ['Backlog'],
    'workplace.sprintName': ['Sprint {n}'],
  },
);
