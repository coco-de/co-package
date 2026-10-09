import '../co_l10n_bundle.dart';

/// Brazilian Portuguese domain text: the Portuguese counterpart of every
/// English key, with the same number of texts in the same order, so that one
/// seed picks the same record in English, Korean, and Portuguese. See
/// [CoL10nBundle].
///
/// The conventions of the language are in `docs/languages/pt.md`, and the ones
/// that a template has to keep are these:
///
/// - it is Brazilian Portuguese (the 2009 orthography): no European spelling or
///   word (`equipe`, not `equipa`; `tela`, not `ecrã`);
/// - the register is `você`: a notice or an instruction says `Por favor,` and
///   the imperative of `você` (`devolva`, `confira`), and a first-person line
///   of a customer says `gostaria de` or `poderia`;
/// - a fictional name ends with `(fictício)` and a sample label with
///   `(exemplo)`, and nothing else marks a text as fictional;
/// - a time is written `18h` (24 hours), a unit follows its number after a
///   no-break space (`U+00A0`: `2 mL`), and the percent sign follows the
///   number with no space (`10%`);
/// - a template that a value fills never puts `de`, `do`, `da`, `em`, `no`,
///   `na`, `a`, `ao`, or `por` right before the value, because the contraction
///   with the article (`de` + `a` = `da`) depends on the gender of the value; a
///   level follows `nível` (masculine), a count follows its label, and a
///   person is named after a colon or `por`.
const CoL10nBundle ptBundle = CoL10nBundle(
  language: 'pt',
  texts: <String, List<String>>{
    // common
    // The first letter of a given name, as English masks it.
    'common.maskedName': ['{initial}***'],
    'common.taxonomyChild': ['{root} · subtema {n}'],

    // fx
    'fx.currencyName.USD': ['Dólar americano'],
    'fx.currencyName.JPY': ['Iene japonês'],
    'fx.currencyName.EUR': ['Euro'],
    'fx.currencyName.CNY': ['Yuan chinês'],
    'fx.currencyName.THB': ['Baht tailandês'],
    'fx.currencyName.VND': ['Dong vietnamita'],
    'fx.currencyName.PHP': ['Peso filipino'],
    'fx.currencyName.NPR': ['Rupia nepalesa'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      'Casa de câmbio demo, aeroporto T1',
      'Casa de câmbio demo, Luzvale',
      'Casa de câmbio demo, aeroporto T2',
      'Casa de câmbio demo, Ribazul',
      'Casa de câmbio demo, Jacarandal',
    ],
    'fx.couponName': [
      'Desconto de 80% no spread do USD (exemplo)',
      'Desconto de 70% no spread do JPY (exemplo)',
      'Desconto na primeira operação de câmbio (exemplo)',
    ],
    'fx.tierName': ['Bronze', 'Prata', 'Ouro'],

    // remit
    'remit.countryName.VN': ['Vietnã'],
    'remit.countryName.PH': ['Filipinas'],
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.US': ['Estados Unidos'],
    'remit.countryName.CN': ['China'],
    'remit.bankName': ['Banco parceiro Lumarante (fictício)'],
    'remit.flagRule': [
      'Transferência de valor alto (regra de demonstração)',
      'Verificação de documentos adicionais (regra de demonstração)',
      'Verificação de solicitações repetidas (regra de demonstração)',
    ],

    // vet
    'vet.petName': ['Cevada', 'Borboleta', 'Pudim', 'Feijão', 'Nuvem'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['Maltês', 'Poodle', 'Sem raça definida'],
    'vet.breed.cat': ['Gato doméstico de pelo curto', 'Gato sem raça definida'],
    'vet.breed.small_mammal': ['Coelho', 'Hamster'],
    'vet.breed.bird': ['Periquito'],
    'vet.breed.reptile': ['Jabuti'],
    'vet.coatColor': ['Branco', 'Marrom', 'Preto', 'Tricolor', 'Cinza'],
    'vet.vaccineName': [
      'Vacina polivalente (exemplo)',
      'Vacina antirrábica (exemplo)',
      'Vacina polivalente felina (exemplo)',
    ],
    'vet.preventiveProduct': [
      'Exemplo de produto preventivo contra dirofilariose (fictício)',
      'Exemplo de produto preventivo contra parasitas externos (fictício)',
    ],
    'vet.vetDiagnosis': [
      'Observação da pele (exemplo)',
      'Observação digestiva (exemplo)',
      'Observação de saúde de rotina (exemplo)',
    ],
    'vet.vetDrug': [
      'Exemplo de produto para a pele (fictício)',
      'Exemplo de produto digestivo (fictício)',
      'Exemplo de produto para os olhos (fictício)',
    ],
    'vet.clinicRoom': [
      'Consultório veterinário 1',
      'Consultório veterinário 2',
      'Sala de vacinação',
    ],

    // grocery
    'grocery.originRegion': [
      'Zona de cultivo Luzvale (fictício)',
      'Zona de cultivo Ribazul (fictício)',
      'Zona de cultivo Campoalvo (fictício)',
    ],
    'grocery.harvestNote': [
      'As datas de colheita e de embalagem são ilustrativas.',
      'O texto sobre o frescor descreve um produto fictício.',
    ],
    'grocery.deliveryZone': [
      'Luzvale, zona A (demo)',
      'Ribazul, zona B (demo)',
      'Campoalvo, zona C (demo)',
    ],
    'grocery.slotLabel': ['Manhã cedo, 6h às 7h', 'Noite, 18h às 20h'],
    'grocery.substitutionNote': [
      'Exemplo de substituição por um item de peso semelhante.',
      'Exemplo de reembolso sem substituição.',
    ],
    'grocery.doorNote': [
      'Por favor, chame pelo interfone na entrada do prédio.',
      'Entrega em mãos, em vez de deixar na porta.',
    ],
    'grocery.categoryName': [
      'Frutas',
      'Legumes e verduras',
      'Pratos prontos',
      'Grãos',
      'Carnes',
      'Peixes e frutos do mar',
      'Laticínios',
    ],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': [
      'Morangos',
      'Espinafre',
      'Bolinhos recheados feitos à mão',
      'Arroz integral',
      'Sassami de frango',
      'Cavalinha congelada',
      'Leite',
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
      'Fones de ouvido sem fio',
      'Caixa organizadora dobrável',
      'Jogo de toalhas de algodão',
      'Xícara de cerâmica',
      'Petisco de cereais',
    ],
    'catalog.commerceUnit': ['1 par', '1 caixa', '3 peças', '1 peça', '200 g'],

    // booking
    'booking.cancelReason': [
      'Mudança de agenda (exemplo)',
      'Outro horário escolhido (exemplo)',
      'Motivo pessoal (exemplo)',
    ],

    // dental
    'dental.dentalProcedure': [
      'Raspagem',
      'Exemplo de tratamento de canal',
      'Exemplo de restauração em resina',
      'Exemplo de planejamento de coroa',
    ],
    'dental.dentalMaterial': [
      'Resina composta (exemplo)',
      'Zircônia (exemplo)',
      'Cerâmica (exemplo)',
    ],
    'dental.chairName': [
      'Cadeira odontológica 1',
      'Cadeira odontológica 2',
      'Cadeira odontológica 3',
    ],
    'dental.hygieneNote': [
      'Exemplo de registro de orientação sobre escovação.',
      'Exemplo de registro de observação da higiene bucal.',
    ],

    // homecare
    'homecare.careGrade': [
      'Nível de cuidado 1',
      'Nível de cuidado 2',
      'Nível de cuidado 3',
      'Nível de cuidado 4',
      'Nível de cuidado 5',
      'Nível de apoio cognitivo',
    ],
    'homecare.careTaskLabel': [
      'Auxílio na refeição',
      'Conferência do registro de medicação',
      'Auxílio na higiene',
      'Auxílio na locomoção',
      'Auxílio no uso do banheiro',
      'Conversa e companhia',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      'Casa de macarrão da viela (fictício)',
      'Loja de conveniência da estação (fictício)',
      'Pousada do viajante (fictício)',
    ],
    'travel_wallet.cityName': ['Osaka', 'Tóquio', 'Bangcoc', 'Hanói'],
    'travel_wallet.cardAlias': [
      'Cartão para passeios (fictício)',
      'Cartão de orçamento da viagem (fictício)',
    ],
    'travel_wallet.tripName': [
      'Quatro dias em Osaka',
      'Fim de semana em Bangcoc',
      'Passeio a pé por Hanói',
    ],

    // b2b_trade
    'b2b_trade.buyerCompany': [
      'Café Brisa Mansa (fictício)',
      'Padaria Farinha Fina (fictício)',
      'Empório Riacho Claro (fictício)',
    ],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      'Copos de papel de 360 ml, 1.000 unidades',
      'Batatas congeladas, 10 kg',
      'Sacolas de papel, 100 unidades',
      'Toalhas de higiene sem perfume, 20 unidades',
    ],
    'b2b_trade.quoteTitle': [
      'Orçamento mensal de embalagens (fictício)',
      'Orçamento semanal de alimentos (fictício)',
      'Orçamento de produtos de higiene (fictício)',
    ],
    'b2b_trade.holdReason': [
      'Verificação do limite de crédito disponível (exemplo)',
      'Verificação da data de entrega (exemplo)',
      'Verificação da especificação do item (exemplo)',
    ],

    // group_deal
    'group_deal.dealTitle': [
      'Compra coletiva de cítricos de inverno',
      'Compra coletiva de fones de ouvido sem fio',
      'Compra coletiva de toalhas de algodão',
    ],
    'group_deal.optionLabel': [
      'Tamanho padrão',
      'Embalagem para presente',
      'Cor padrão',
    ],
    'group_deal.rewardLabel': [
      'Selo de participação',
      'Pontos de recompensa ilustrativos',
      'Benefício de frete',
    ],
    'group_deal.benefitTitle': [
      'Exemplo de cupom de frete grátis',
      'Exemplo de cupom para a próxima compra coletiva',
    ],
    'group_deal.settleNote': [
      'Exemplo de total das participações concluídas.',
      'Exemplo de total sem as participações canceladas.',
    ],
  },
);
