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
  },
);
