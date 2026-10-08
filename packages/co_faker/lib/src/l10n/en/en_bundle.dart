import '../co_l10n_bundle.dart';

/// English domain text: the labels, names, and sentences of the domain packs and
/// the dedicated generators.
///
/// English is the reference of every language. A key is `<pack>.<role>` (or
/// `<generator>.<name>`), and its value is the list of texts the key can show;
/// a key with one sentence is a list of one, and `{name}` marks a placeholder the
/// generator fills in. Another language keeps the same number of texts for a
/// key, in the same order, so one seed picks the same entry in each language,
/// and it may leave a key out to fall back to English. See [CoL10nBundle].
const CoL10nBundle enBundle = CoL10nBundle(
  language: 'en',
  texts: <String, List<String>>{
    // common
    // A masked name. {lastName} is a family name and {initial} the first letter
    // of a given name; only the placeholders a template contains are drawn, so a
    // language chooses which name it masks.
    'common.maskedName': ['{initial}***'],
    // The name of a child under a taxonomy root: {root} is the root name and {n}
    // the child number.
    'common.taxonomyChild': ['{root} · subtopic {n}'],

    // fx
    'fx.currencyName.USD': ['US dollar'],
    'fx.currencyName.JPY': ['Japanese yen'],
    'fx.currencyName.EUR': ['Euro'],
    'fx.currencyName.CNY': ['Chinese yuan'],
    'fx.currencyName.THB': ['Thai baht'],
    'fx.currencyName.VND': ['Vietnamese dong'],
    'fx.currencyName.PHP': ['Philippine peso'],
    'fx.currencyName.NPR': ['Nepalese rupee'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      'Demo airport T1 exchange',
      'Demo Solbit exchange',
      'Demo airport T2 exchange',
      'Demo Garam exchange',
      'Demo Mulpare exchange',
    ],
    'fx.couponName': [
      'USD 80% spread discount (example)',
      'JPY 70% spread discount (example)',
      'First exchange discount (example)',
    ],
    'fx.tierName': ['Bronze', 'Silver', 'Gold'],

    // remit
    'remit.countryName.VN': ['Vietnam'],
    'remit.countryName.PH': ['Philippines'],
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.US': ['United States'],
    'remit.countryName.CN': ['China'],
    'remit.bankName': ['Nuri partner bank (fictional)'],
    'remit.flagRule': [
      'Large transfer (demo rule)',
      'Additional document check (demo rule)',
      'Repeated request check (demo rule)',
    ],

    // vet
    'vet.petName': ['Barley', 'Butterfly', 'Tofu', 'Bean', 'Cloud'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['Maltese', 'Poodle', 'Mixed dog'],
    'vet.breed.cat': ['Domestic shorthair', 'Mixed cat'],
    'vet.breed.small_mammal': ['Rabbit', 'Hamster'],
    'vet.breed.bird': ['Small parrot'],
    'vet.breed.reptile': ['Tortoise'],
    'vet.coatColor': ['White', 'Brown', 'Black', 'Tricolor', 'Gray'],
    'vet.vaccineName': [
      'Combination vaccine (example)',
      'Rabies vaccination (example)',
      'Feline combination vaccine (example)',
    ],
    'vet.preventiveProduct': [
      'Heartworm preventive example (fictional)',
      'External parasite preventive example (fictional)',
    ],
    'vet.vetDiagnosis': [
      'Skin observation (example)',
      'Digestive observation (example)',
      'Routine health observation (example)',
    ],
    'vet.vetDrug': [
      'Skin care example (fictional)',
      'Digestive care example (fictional)',
      'Eye care example (fictional)',
    ],
    'vet.clinicRoom': ['Vet room 1', 'Vet room 2', 'Vaccination room'],

    // grocery
    'grocery.originRegion': [
      'Solbit growing zone (fictional)',
      'Garam growing zone (fictional)',
      'Field growing zone (fictional)',
    ],
    'grocery.harvestNote': [
      'Harvest and packing dates are illustrative.',
      'Freshness text describes a fictional product.',
    ],
    'grocery.deliveryZone': [
      'Demo Solbit zone A',
      'Demo Garam zone B',
      'Demo Field zone C',
    ],
    'grocery.slotLabel': ['Dawn 06:00–07:00', 'Evening 18:00–20:00'],
    'grocery.substitutionNote': [
      'Example replacement with a similar weight.',
      'Example refund without substitution.',
    ],
    'grocery.doorNote': [
      'Please ring at the shared entrance.',
      'Hand delivery instead of leaving at the door.',
    ],
    'grocery.categoryName': [
      'Fruit',
      'Vegetables',
      'Prepared foods',
      'Grain',
      'Meat',
      'Seafood',
      'Dairy',
    ],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': [
      'Strawberries',
      'Spinach',
      'Handmade dumplings',
      'Brown rice',
      'Chicken tenderloin',
      'Frozen mackerel',
      'Milk',
    ],
    // Korean and English output have always shown the same unit labels.
    'catalog.groceryUnit': ['500g', '200g', '1kg', '2kg', '500g', '600g', '1L'],
    'catalog.commerceName': [
      'Wireless earphones',
      'Folding storage box',
      'Cotton towel set',
      'Ceramic cup',
      'Grain snack',
    ],
    // Korean and English output have always shown the same unit labels.
    'catalog.commerceUnit': ['1 pair', '1 box', '3 pieces', '1 piece', '200g'],

    // booking
    'booking.cancelReason': [
      'Schedule changed (example)',
      'Another time chosen (example)',
      'Personal reason (example)',
    ],

    // dental
    'dental.dentalProcedure': [
      'Scaling',
      'Root canal example',
      'Resin restoration example',
      'Crown planning example',
    ],
    'dental.dentalMaterial': [
      'Composite resin (example)',
      'Zirconia (example)',
      'Ceramic (example)',
    ],
    'dental.chairName': ['Dental chair 1', 'Dental chair 2', 'Dental chair 3'],
    'dental.hygieneNote': [
      'Example record of brushing explanation.',
      'Example record of oral hygiene observation.',
    ],

    // homecare
    'homecare.careGrade': [
      'Care grade 1',
      'Care grade 2',
      'Care grade 3',
      'Care grade 4',
      'Care grade 5',
      'Cognitive support grade',
    ],
    'homecare.careTaskLabel': [
      'Meal assistance',
      'Medication record check',
      'Hygiene assistance',
      'Mobility assistance',
      'Toileting assistance',
      'Conversation',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      'Lane noodle shop (fictional)',
      'Station convenience shop (fictional)',
      'Traveler lodge (fictional)',
    ],
    'travel_wallet.cityName': ['Osaka', 'Tokyo', 'Bangkok', 'Hanoi'],
    'travel_wallet.cardAlias': [
      'Outing travel card (fictional)',
      'Trip budget card (fictional)',
    ],
    'travel_wallet.tripName': [
      'Four days in Osaka',
      'Bangkok weekend',
      'Hanoi walking trip',
    ],

    // b2b_trade
    'b2b_trade.buyerCompany': [
      'Onsae cafe (fictional)',
      'Mildam bakery (fictional)',
      'Solnae food shop (fictional)',
    ],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      '12oz paper cups, 1000 pieces',
      'Frozen potatoes, 10kg',
      'Paper bags, 100 pieces',
      'Unscented hygiene towels, 20 pieces',
    ],
    'b2b_trade.quoteTitle': [
      'Monthly packaging quote (fictional)',
      'Weekly food quote (fictional)',
      'Hygiene supplies quote (fictional)',
    ],
    'b2b_trade.holdReason': [
      'Available credit check (example)',
      'Delivery date check (example)',
      'Item specification check (example)',
    ],

    // group_deal
    'group_deal.dealTitle': [
      'Winter citrus group deal',
      'Wireless earphone group deal',
      'Cotton towel group deal',
    ],
    'group_deal.optionLabel': [
      'Regular size',
      'Gift wrapping',
      'Standard color',
    ],
    'group_deal.rewardLabel': [
      'Participation stamp',
      'Illustrative reward points',
      'Shipping benefit',
    ],
    'group_deal.benefitTitle': [
      'Example free shipping coupon',
      'Example next deal coupon',
    ],
    'group_deal.settleNote': [
      'Example total of successful participations.',
      'Example total excluding canceled participations.',
    ],

    // fitness
    // A class name from the category label and the level label of the same
    // record.
    'fitness.className': ['{category} {level}'],
    'fitness.classCategoryLabel': ['Mat', 'Reformer', 'Chair', 'Yoga'],
    'fitness.classLevelLabel': ['beginner', 'intermediate', 'advanced'],
    'fitness.equipment': ['Mat', 'Reformer', 'Chair', 'Yoga block'],
    'fitness.studioRoom': [
      'Mat room',
      'Reformer room',
      'Chair room',
      'Yoga room',
    ],
    'fitness.instructorSpecialty': [
      'Mat instruction',
      'Reformer instruction',
      'Yoga instruction',
    ],
    'fitness.passName': [
      '10 mat classes (example)',
      '20 reformer classes (example)',
      'Monthly pass (example)',
    ],
    'fitness.cancelReason': ['Schedule changed', 'Class time changed'],
    'fitness.noShowNote': [
      'Example record without attendance confirmation.',
      'Example marked absent after class start.',
    ],

    // space_rental
    'space_rental.spaceName': [
      'Four oclock party room (fictional)',
      'Solbit study room (fictional)',
      'Garam rehearsal room (fictional)',
    ],
    'space_rental.districtName': [
      'Fictional city, Solbit district',
      'Fictional city, Garam district',
      'Fictional city, Mulpare district',
    ],
    'space_rental.amenity': ['Wi-Fi', 'Whiteboard', 'Water dispenser'],
    'space_rental.equipmentOption': [
      'Projector (example)',
      'Sound equipment (example)',
      'One parking spot (example)',
    ],
    'space_rental.houseRule': [
      'Please return equipment after use.',
      'Please keep to the booked time.',
    ],
    'space_rental.bookingPurpose': [
      'Study gathering',
      'Friends gathering',
      'Band rehearsal',
    ],
    'space_rental.guestMessage': [
      'Could I check how to use the equipment?',
      'Please share the entry instructions.',
    ],
    'space_rental.hostReply': [
      'Please see the equipment guide on the booking page.',
      'Entry instructions appear in the booking details.',
    ],

    // dining
    'dining.restaurantName': [
      'Perilla noodle shop (fictional)',
      'Lane pasta shop (fictional)',
      'Solbit tea room (fictional)',
    ],
    'dining.menuName': [
      'Perilla noodles',
      'Tomato pasta',
      'Vegetable rice bowl',
      'Warm tea',
    ],
    'dining.partyLabel': ['Party of {n}'],
    'dining.noShowNote': [
      'Example queue record without arrival confirmation.',
      'Example absence after the announced time.',
    ],
    'dining.loyaltyBenefit': [
      'Fifth visit drink (example)',
      'Regular guest dessert coupon (example)',
    ],
    'dining.districtName': [
      'Fictional city, Solbit district',
      'Fictional city, Garam district',
    ],

    // daycare
    'daycare.childName': ['Jiu', 'Haneul', 'Daon', 'Narae', 'Sodam'],
    'daycare.className': ['Sun class', 'Moon class', 'Star class'],
    'daycare.ageLabel': ['Age 1', 'Age 2', 'Age 3', 'Age 4', 'Age 5'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.guardianLabel': ['{name2} guardian'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.teacherName': ['Teacher {name2}'],
    'daycare.toiletNote': [
      'One toileting record (example)',
      'Two toileting records (example)',
      'No record (example)',
    ],
    'daycare.mealMenu': [
      'Brown rice and vegetable stew',
      'Tofu soup and rice',
      'Vegetable fried rice',
    ],
    'daycare.snackMenu': [
      'Pear slices',
      'Steamed sweet potato',
      'Plain yogurt',
    ],
    'daycare.allergenLabel': [
      'Milk',
      'Egg',
      'Soy',
      'Wheat',
      'None noted (example)',
    ],
    'daycare.activityTitle': [
      'Winter snow play',
      'Making paper houses',
      'Color block play',
    ],
    'daycare.albumCaption': [
      'Fictional illustration of building blocks together',
      'Fictional winter play illustration',
    ],
    'daycare.drugLabel': [
      'Fever syrup (fictional)',
      'Cough syrup (fictional)',
      'Moisturizing topical (fictional)',
    ],
    'daycare.dosageLabel': [
      'Guardian-authored example: 2mL',
      'Guardian-authored example: 3mL',
      'Guardian-authored example: small amount',
    ],
    'daycare.noticeTitle': [
      'Winter play notice (example)',
      'Meal change notice (example)',
      'Safety check notice (example)',
    ],

    // exam_prep
    'exam_prep.subjectName': [
      'Database',
      'Database',
      'Networking',
      'Networking',
      'Networking',
      'Programming basics',
      'Programming basics',
      'Information security',
      'Information security',
    ],
    'exam_prep.unitName': [
      'Data modeling',
      'SQL basics',
      'Transport layer',
      'Routing',
      'Application layer',
      'Variables',
      'Data structures',
      'Cryptography basics',
      'Access control',
    ],
    'exam_prep.questionStem': [
      'Which key distinguishes rows in a table?',
      'Which SQL clause selects rows by a condition?',
      'Which transport protocol handles ordering and retransmission?',
      'Which device selects the next packet route?',
      'Which protocol expresses web requests and responses?',
      'What stores a value under a program name?',
      'Which structure removes the last inserted value first?',
      'What computes a fixed-length summary of an input?',
      'Which principle grants only the permissions needed for a task?',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      'Primary key',
      'WHERE',
      'TCP',
      'Router',
      'HTTP',
      'Variable',
      'Stack',
      'Hash function',
      'Least privilege',
    ],
    'exam_prep.wrongChoice1': [
      'Font',
      'Font',
      'JPEG',
      'Speaker',
      'PNG',
      'Border',
      'FIFO queue',
      'Font selection',
      'Public access',
    ],
    'exam_prep.wrongChoice2': [
      'Background color',
      'Margin',
      'CSS',
      'Keyboard',
      'MP3',
      'Page margin',
      'Image',
      'Screen zoom',
      'Shared password',
    ],
    'exam_prep.wrongChoice3': [
      'Screen width',
      'Icon',
      'SVG',
      'Monitor',
      'TTF',
      'Background image',
      'Audio file',
      'Background fill',
      'Skipped checks',
    ],
    'exam_prep.explanation': [
      'A Primary key identifies each row in a table.',
      'The WHERE clause expresses a condition for selected rows.',
      'TCP handles ordering and retransmission of a byte stream.',
      'A Router selects the next route using the destination address.',
      'HTTP expresses web requests and responses.',
      'A Variable lets a program refer to a value by name.',
      'A Stack removes the last inserted value first.',
      'A Hash function computes a fixed-length summary of an input.',
      'Least privilege grants only the permissions needed for a task.',
    ],
    'exam_prep.examPaperTitle': [
      'Practice paper 1 (fictional)',
      'Practice paper 2 (fictional)',
      'Unit check paper (fictional)',
    ],
    'exam_prep.studyTaskTitle': [
      'Solve ten transport questions',
      'Review access-control mistakes',
      'Check SQL basics',
    ],
    'exam_prep.taxonomyName': [
      'Database',
      'Networking',
      'Programming basics',
      'Information security',
    ],

    // hrd
    'hrd.departmentName': [
      'Sales',
      'Production',
      'Research',
      'Support',
      'Administration',
      'Logistics',
    ],
    'hrd.jobTitle': ['Associate', 'Manager', 'Team lead'],
    'hrd.courseTitle': [
      'Handling personal information 2026 (fictional)',
      'Working safely together (fictional)',
      'Organizing work records (fictional)',
    ],
    'hrd.courseKind': ['Mandatory', 'Professional', 'Leadership'],
    'hrd.lessonTitle': [
      'Understand basic principles',
      'Review work examples',
      'Check records',
    ],
    'hrd.chapterTitle': ['Introduction', 'Example review', 'Summary'],
    'hrd.nudgeTitle': [
      'Training deadline reminder (example)',
      'Incomplete lesson reminder (example)',
    ],
    'hrd.exemptionReason': [
      'External completion evidence (example)',
      'Leave-period check (example)',
      'Alternative training check (example)',
    ],
    'hrd.classroomPlace': [
      'Solbit classroom (fictional)',
      'Garam seminar room (fictional)',
    ],

    // neighborhood
    'neighborhood.neighborhoodName': [
      'Solbit neighborhood (fictional)',
      'Ginkgo neighborhood (fictional)',
      'Mulpare neighborhood (fictional)',
    ],
    'neighborhood.districtName': [
      'Fictional city, Garam district',
      'Fictional city, Solnae district',
    ],
    'neighborhood.nickname': [
      'SolbitBean (fictional)',
      'MulpareStar (fictional)',
      'LaneCloud (fictional)',
    ],
    'neighborhood.postTitle': [
      'Blue glove found at the playground (example)',
      'Exploring a neighborhood walk (example)',
      'Sharing a small planter (example)',
    ],
    'neighborhood.postBody': [
      'Fictional neighborhood news. Details are in this post.',
      'Example post for neighbors; no phone number or real address is included.',
    ],
    'neighborhood.commentBody': [
      'Thanks for sharing the update.',
      'I will check and reply in the post.',
      'I can check in the evening.',
    ],
    'neighborhood.placeName': [
      'Solbit bakery (fictional)',
      'Garam park shelter (fictional)',
      'Mulpare small library (fictional)',
    ],
    'neighborhood.openHours': ['08:00–21:00', '09:00–18:00', '10:00–20:00'],
    'neighborhood.bannedWord': [
      'advertising-example',
      'abuse-example',
      'blocked-word-example',
    ],
    'neighborhood.keyword': ['glove', 'walk', 'sharing', 'local news'],

    // meetup
    'meetup.clubName': [
      'Solbit morning run (fictional)',
      'Garam reading group (fictional)',
      'Mulpare board games (fictional)',
    ],
    'meetup.interestTag': [
      'Running',
      'Reading',
      'Board games',
      'Photography',
      'Cooking',
      'Hiking',
    ],
    'meetup.clubIntro': [
      'Fictional group welcoming first-time neighbors.',
      'Example group sharing small activities together.',
    ],
    'meetup.gatheringTitle': [
      'Third January gathering (fictional)',
      'Weekend book conversation (fictional)',
      'Winter walk gathering (fictional)',
    ],
    'meetup.venueName': [
      'Garam walking path entrance (fictional)',
      'Solbit gathering room (fictional)',
      'Mulpare shelter (fictional)',
    ],
    'meetup.nickname': [
      'DawnBean (fictional)',
      'BookCloud (fictional)',
      'SmallStar (fictional)',
    ],
    'meetup.duesItem': [
      'Gathering fee (example)',
      'Shared drinks (example)',
      'Shared equipment hire (example)',
    ],
    'meetup.joinAnswer': [
      'I would like to join activities this month.',
      'I can participate on weekend mornings.',
    ],
    'meetup.ruleText': [
      'Please respect each others time.',
      'Please chat within the group without publishing contact details.',
      'Please tell the group when canceling.',
    ],
    'meetup.cadenceLabel': [
      'Every Saturday 07:00',
      'Alternate Sundays 10:00',
      'First Saturday each month 14:00',
    ],

    // fandom
    'fandom.fanNickname': ['Star', 'Sprout', 'MoonBean', 'LightDrop'],
    'fandom.benefitTitle': [
      'Example member-only picture',
      'Simulated event entry',
      'Early fictional clip preview',
    ],
    'fandom.postCaption': [
      'Fictional illustration of a winter studio',
      'Example post about rehearsal time',
    ],
    'fandom.clipTitle': [
      'Thirty-second rehearsal (fictional)',
      'Studio greeting (fictional)',
      'Winter sound note (fictional)',
    ],
    'fandom.letterBody': [
      'I enjoyed todays example post and look forward to the next update.',
      'The winter studio illustration felt warm. Sending encouragement.',
    ],
    'fandom.eventTitle': [
      'Winter fan gathering (fictional)',
      'Studio stories event (fictional)',
    ],
    'fandom.agendaTitle': [
      'Winter small theater schedule (fictional)',
      'Fictional broadcast conversation',
      'New post release schedule',
    ],
    'fandom.venueLabel': [
      'Winter small theater (fictional)',
      'Solbit studio (fictional)',
      'Online example space',
    ],

    // content
    'content.seriesTitle': [
      'Postal island of the paper lighthouse (fictional)',
      'Small map of the cloud pond (fictional)',
      'Garden of the slow clock (fictional)',
    ],
    'content.penName': [
      'WordBean (fictional)',
      'PaperStar (fictional)',
      'CloudPen (fictional)',
    ],
    'content.synopsisLine': [
      'Fictional characters organize letters on a small island.',
      'A fictional story about drawing a pond absent from the map.',
    ],
    'content.genreName': [
      'Fantasy',
      'Everyday life',
      'Adventure',
      'Science stories',
      'Essay',
    ],
    'content.episodeTitle': [
      'The first paper boat (fictional)',
      'A small dot on the pond (fictional)',
      'An afternoon without a clock (fictional)',
    ],
    'content.cutAltText': [
      'Illustration of a fictional character folding a paper boat',
      'Illustration of two fictional characters beside a pond',
    ],
    'content.commentLine': [
      'The paper boat scene stayed with me.',
      'I would like to read the next example episode.',
    ],
    'content.chapterParagraph': [
      'A blank sheet lay in the island mailbox. A child folded it into a small boat shaped like the pond. This paragraph is an original fictional demo example.',
      'A small planter stood beside the slow clock. Two friends drew the clouds they had seen instead of naming the plant. This is an original fictional example paragraph.',
    ],
    'content.publisherName': [
      'Paper Lighthouse publishing (fictional)',
      'Cloud Pond publishing (fictional)',
    ],
    'content.audioTitle': [
      'An afternoon folding paper boats (fictional)',
      'Sound notes of a small pond (fictional)',
    ],
    'content.newsletterName': [
      'Paper Lighthouse weekly notes (fictional)',
      'Cloud Pond small letters (fictional)',
    ],
    'content.articleHeadline': [
      'Organizing everyday notes into small groups (fictional)',
      'Recording colors from a winter walk (fictional)',
    ],
    'content.topicName': [
      'Everyday notes',
      'Winter walks',
      'Small science',
      'Reading habits',
    ],
    'content.genreTaxonomy': [
      'Fantasy',
      'Everyday life',
      'Adventure',
      'Science stories',
      'Essay',
    ],
    'content.audioTaxonomy': ['Audiobook', 'Podcast'],
    'content.topicTaxonomy': [
      'Everyday notes',
      'Winter walks',
      'Small science',
      'Reading habits',
      'Life observations',
    ],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      'Please check the team invitation status',
      'Question about example invoice lines',
      'Example CSV export error',
      'Question about integration status',
      'Question about an example screen button',
      'Question about finding help',
    ],
    'helpdesk.ticketDescription': [
      'The fictional support account shows a pending invitation.',
      'I would like to check the lines and period of the fictional invoice.',
      'An error state appears when exporting the example data to CSV.',
      'I would like to check the wording on the fictional integration status page.',
      'The example screen remains the same after pressing a button.',
      'Where can I find the fictional support help page?',
    ],
    'helpdesk.macroName': [
      'Example receipt acknowledgement',
      'Additional information check',
      'Processing status notice',
    ],
    'helpdesk.helpArticleTitle': [
      'Example invitation guide',
      'Reading a fictional invoice',
      'Exporting example CSV data',
    ],
    'helpdesk.csatComment': [
      'I reviewed the explanation.',
      'The example instructions were easy to follow.',
      'I have additional details to check.',
    ],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      'Check the invitation status in account settings. This simulated AI draft needs agent review.',
      'Record the login method and example error together. This simulated AI draft makes no account changes.',
      'Check the period and lines on the example invoice. This simulated AI draft describes fictional prices.',
      'Record the example invoice number in the support note. This simulated AI draft is not a real payment notice.',
      'Check the date range and format selected for export. This simulated AI draft records an example error without personal information.',
      'Check column names and file status in the example CSV. This simulated AI draft requires agent review.',
      'Record the example integration status and check time. This simulated AI draft makes no external calls.',
      'Record the screen and reproduction steps. This simulated AI draft promises no outcome.',
    ],
    'helpdesk.topicName': ['Account', 'Billing', 'Data', 'Integration'],

    // campaign
    'campaign.brandName': [
      'Springlight bakery (fictional)',
      'Moonlight bookshop (fictional)',
      'Green Garden cafe (fictional)',
    ],
    'campaign.campaignTitle': [
      'Winter example offer',
      'First visit example news',
      'Weekend example news',
    ],
    'campaign.offerCopy': [
      '(Ad) Example coupon for a fictional winter menu. See demo settings for opt-out.',
      '(Ad) Example offer for a fictional product. Opt-out is in demo settings.',
    ],
    'campaign.couponTitle': [
      'Winter 20% example coupon',
      'First visit 10% example coupon',
    ],
    'campaign.segmentName': [
      'Example buyers in the last 30 days',
      'Example opted-in group',
      'Example weekend-news group',
    ],
    'campaign.failReason': [
      'Missing recipient number (example)',
      'No marketing consent (example)',
      'No night-time consent (example)',
    ],

    // workplace
    'workplace.department': [
      'Frontend team',
      'Backend team',
      'Design team',
      'Customer support',
      'HR team',
    ],
    'workplace.position': ['Associate', 'Manager', 'Team lead'],
    'workplace.workPlace': [
      'Solbit office (fictional)',
      'Garam work center (fictional)',
      'Remote',
    ],
    'workplace.shiftName': ['Day shift', 'Morning shift', 'Weekend duty'],
    'workplace.approvalComment': [
      'Reviewed the attached example record.',
      'The example reason needs further clarification.',
    ],
    'workplace.projectName': [
      'Customer portal refresh (fictional)',
      'Internal wiki cleanup (fictional)',
      'Example accessibility improvement',
    ],
    'workplace.workItemTitle': [
      'Improve login error wording',
      'Check example table sorting',
      'Organize notification state display',
    ],
    'workplace.labelName': [
      'Copy',
      'Accessibility',
      'Backlog',
      'Needs checking',
    ],
    'workplace.milestoneTitle': [
      'First review milestone',
      'Example screen complete',
      'Regression check',
    ],
    'workplace.sprintName': ['Sprint {n}'],
    'workplace.commentBody': [
      'Leaving feedback after checking the example screen.',
      'Please review the wording before the next task.',
    ],
    'workplace.merchantName': [
      'Wildflower dining (fictional)',
      'Lane snack shop (fictional)',
      'Solbit office supplies (fictional)',
    ],
    'workplace.accountName': [
      'Meals (example)',
      'Transport (example)',
      'Meeting (example)',
      'Supplies (example)',
      'Travel (example)',
      'Other (example)',
    ],
    'workplace.rejectReasonText': [
      'Missing example receipt',
      'Item classification needs checking',
      'Example policy limit needs checking',
    ],

    // brokerage
    'brokerage.projectTitle': [
      'Example customer portal build',
      'Fictional service screen refresh',
      'Example booking screen build',
    ],
    'brokerage.serviceCategory': [
      'Web interface',
      'App interface',
      'Workplace design',
      'Home service',
    ],
    'brokerage.providerName': [
      'Code Attic studio (fictional)',
      'Solbit interface workshop (fictional)',
      'Garam home workshop (fictional)',
    ],
    'brokerage.providerHeadline': [
      'Fictional partner showing example screens and work records',
      'Example profile for reviewing a fictional project scope',
    ],
    'brokerage.skillTag': [
      'Dart',
      'Interface planning',
      'Data organization',
      'Copy writing',
    ],
    'brokerage.proposalMessage': [
      'Prepared scope and schedule checkpoints for the example.',
      'Proposing checkpoints for the fictional project stages.',
    ],
    'brokerage.portfolioTitle': [
      'Fictional customer portal example',
      'Example booking screen record',
      'Fictional work table improvement',
    ],
    'brokerage.milestoneLabel': [
      'Scope check',
      'Screen draft check',
      'Example function check',
      'Handoff record',
    ],
    'brokerage.homeServiceName': [
      'Air-conditioner cleaning (example)',
      'Small move (example)',
      'Tap check (example)',
      'Beginner instrument lesson (example)',
    ],
    'brokerage.requestAnswer': [
      'I would like to check the scope before a visit.',
      'The example schedule is a weekend morning.',
    ],
    'brokerage.regionDong': [
      'Fictional city, Solbit district',
      'Fictional city, Garam district',
      'Fictional city, Mulpare district',
    ],
    'brokerage.reviewText': [
      'Reviewed the example work record and instructions.',
      'The example schedule instructions were easy to follow.',
    ],
    'brokerage.creditLabel': [
      'Quote submission credit (example)',
      'Unviewed quote refund credit (example)',
      'Top-up credit (example)',
    ],
    'brokerage.advisorTitle': [
      'Fictional tax specialist',
      'Fictional legal specialist',
      'Fictional labor specialist',
    ],
    'brokerage.consultTopic': [
      'Example explanation of terminology',
      'Example pre-consultation checklist',
      'Example document list explanation',
    ],
    'brokerage.qnaQuestion': [
      'What does this system term mean? (fictional question)',
      'What fields appear in a consultation record? (fictional question)',
    ],
    'brokerage.qnaAnswerGeneric': [
      'General information example. A system overview may list terms, scope and documents. This contains no judgment about an individual case.',
      'General information example. A consultation record separates questions from reference materials. No specific result or course of action is given.',
    ],
    'brokerage.consultNoteGeneric': [
      'General example note: introduced the question topic and system terms. The document list consists of fictional explanatory items.',
      'General example note: reviewed the consultation record format. There is no conclusion or advice about an individual case.',
    ],
    'brokerage.officeName': [
      'Solbit consultation office (fictional)',
      'Garam records office (fictional)',
    ],
    'brokerage.serviceTypeName': ['Cleaning', 'Moving', 'Repair', 'Lessons'],

    // logistics
    'logistics.zoneName': [
      'Solnae zone 1 (fictional)',
      'Solnae zone 2 (fictional)',
      'Garam zone (fictional)',
    ],
    'logistics.hubName': ['Solbit hub (fictional)', 'Garam hub (fictional)'],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // Korean and English output have always shown this Korean plate format.
    'logistics.vehiclePlate': ['{n}가●●{m}'],
    'logistics.deliveryNote': [
      'No unattended delivery; hand over directly.',
      'Please ring at the shared entrance.',
      'Please check with the security desk.',
    ],
    'logistics.entranceHint': [
      'Shared entrance #••••; call security desk',
      'Use the entrance call button; no password shown',
    ],
    'logistics.scanEvent': [
      'Hub arrival',
      'Line-haul loading',
      'Out for delivery',
      'Delivery complete',
      'Delivery not completed',
    ],
    'logistics.carrierLabel': [
      'Example carrier A (fictional)',
      'Example carrier B (fictional)',
      'Example freight carrier C (fictional)',
    ],
    'logistics.freightType': [
      'Packaging',
      'Food supplies',
      'Building materials',
      'Electronic parts',
      'Household goods',
    ],
    'logistics.routeSummary': [
      'Fictional Solbit zone → Garam zone',
      'Fictional Mulpare zone → Solnae zone',
    ],
    'logistics.fareItem': [
      'Base fare (example)',
      'Liftgate add-on (example)',
      'Manual handling (example)',
      'Waiting time (example)',
    ],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': [
      'Small paper box',
      'Packaging tape 48mm',
      'Cotton towels, 3 pieces',
      'Brown rice 2kg',
    ],
    'logistics.ownerLabel': [
      'Cargo owner A (fictional)',
      'Cargo owner B (fictional)',
      'Cargo owner C (fictional)',
    ],

    // hospitality
    'hospitality.propertyName': [
      'Pine stay grounds (fictional)',
      'Garam rest hotel (fictional)',
      'Mulpare small lodge (fictional)',
    ],
    'hospitality.siteName': [
      'Pine Breeze site A (fictional)',
      'Pine Scent site B (fictional)',
      'Pine Cone site C (fictional)',
    ],
    'hospitality.amenity': [
      'Private barbecue area',
      'Shared shower room',
      'Wi-Fi',
    ],
    'hospitality.stayOption': [
      'Barbecue grill set (example)',
      'Firewood bundle (example)',
      'Early check-in (example)',
    ],
    'hospitality.seasonName': [
      'Regular season',
      'Holiday high season (example)',
      'Weekday offer season (example)',
    ],
    'hospitality.ratePlan': [
      'Standard example rate',
      'Breakfast example rate',
      'Weekday example rate',
    ],
    'hospitality.houseRule': [
      'Please keep shared spaces quiet at night.',
      'Please review the example departure checklist.',
    ],
    'hospitality.reviewSnippet': [
      'The example room instructions were easy to read.',
      'The fictional property instructions are organized.',
    ],
    'hospitality.hkCheckItem': [
      'Change bedding',
      'Clean bathroom',
      'Check amenities',
      'Check minibar',
    ],
    'hospitality.maintenanceIssue': [
      'Bathroom leak check (example)',
      'Light inspection request (example)',
      'Heating display check (example)',
      'Furniture damage check (example)',
    ],
    'hospitality.lostItemName': [
      'Blue umbrella',
      'Gray scarf',
      'One book',
      'Water bottle',
    ],
    'hospitality.specialRequest': [
      'High floor, non-smoking (example)',
      'Extra pillow request (example)',
      'Quiet room request (example)',
    ],
    'hospitality.menuItem': [
      'Seaweed soup meal',
      'Vegetable pasta',
      'Fruit yogurt',
      'Warm tea',
    ],
    'hospitality.menuOption': [
      'Less rice',
      'Regular rice',
      'Extra side dish (example)',
      'No ice',
    ],
    'hospitality.amenityName': ['Towel', 'Water', 'Toothbrush', 'Pillow'],
    'hospitality.localSpot': [
      'Morning soup shop (fictional)',
      'Lane cafe (fictional)',
      'Solbit walking path (fictional)',
    ],
    'hospitality.conciergeReply': [
      'Fictional property instructions appear in stay details.',
      'Recorded the request in the example register.',
      'Nearby places are all fictional demo locations.',
    ],
    'hospitality.folioItem': [
      'Room charge (example)',
      'Room service (example)',
      'Extra option (example)',
    ],
  },
);
