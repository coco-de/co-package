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
///   no-break space (`U+00A0`: `2\u00A0mL`), and the percent sign follows the
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
      '500\u00A0g',
      '200\u00A0g',
      '1\u00A0kg',
      '2\u00A0kg',
      '500\u00A0g',
      '600\u00A0g',
      '1\u00A0L',
    ],
    'catalog.groceryKindName': ['Ovos', 'Carne Hanwoo para sopa', 'Rúcula'],
    // `10 un.`: the abbreviation reads for any count.
    'catalog.groceryPackLabel': ['{n} un.'],
    'catalog.commerceName': [
      'Fones de ouvido sem fio',
      'Caixa organizadora dobrável',
      'Jogo de toalhas de algodão',
      'Xícara de cerâmica',
      'Petisco de cereais',
    ],
    'catalog.commerceUnit': [
      '1 par',
      '1 caixa',
      '3 peças',
      '1 peça',
      '200\u00A0g',
    ],

    // booking
    'booking.cancelReason': [
      'Mudança de agenda (exemplo)',
      'Outro horário escolhido (exemplo)',
      'Motivo pessoal (exemplo)',
    ],

    // dental
    'dental.dentalProcedure': [
      'Limpeza dental',
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
      'Copos de papel de 360\u00A0ml, 1.000 unidades',
      'Batatas congeladas, 10\u00A0kg',
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

    // fitness
    // A class name from the category label and the level label of the same
    // record: the level follows `nível`, which is masculine, so that the label
    // needs no agreement with the category (`Cadeira, nível intermediário`).
    'fitness.className': ['{category}, nível {level}'],
    'fitness.classCategoryLabel': ['Solo', 'Reformer', 'Cadeira', 'Ioga'],
    'fitness.classLevelLabel': ['iniciante', 'intermediário', 'avançado'],
    'fitness.equipment': ['Colchonete', 'Reformer', 'Cadeira', 'Bloco de ioga'],
    'fitness.studioRoom': [
      'Sala de Pilates solo',
      'Sala de reformer',
      'Sala de cadeira',
      'Sala de ioga',
    ],
    'fitness.instructorSpecialty': [
      'Instrução de Pilates solo',
      'Instrução de reformer',
      'Instrução de ioga',
    ],
    'fitness.instructorCareer': [
      '5 anos dando aulas de Pilates solo',
      '3 anos no reformer',
      '8 anos de ioga em grupo',
      '2 anos de treino em pequenos grupos',
      '6 anos de sessões de reabilitação',
    ],
    'fitness.passName': [
      'Pacote de 10 aulas de Pilates solo (exemplo)',
      'Pacote de 20 aulas de reformer (exemplo)',
      'Plano mensal (exemplo)',
    ],
    'fitness.cancelReason': ['Mudança de agenda', 'Mudança de horário da aula'],
    'fitness.noShowNote': [
      'Exemplo de registro sem confirmação de presença.',
      'Exemplo de falta registrada após o início da aula.',
    ],

    // space_rental
    'space_rental.spaceName': [
      'Salão de festas Quatro da Tarde (fictício)',
      'Sala de estudos Luzvale (fictício)',
      'Sala de ensaio Ribazul (fictício)',
    ],
    'space_rental.districtName': [
      'Cidade fictícia, bairro Luzvale',
      'Cidade fictícia, bairro Ribazul',
      'Cidade fictícia, bairro Jacarandal',
    ],
    'space_rental.amenity': ['Wi-Fi', 'Quadro branco', 'Bebedouro'],
    'space_rental.equipmentOption': [
      'Projetor (exemplo)',
      'Equipamento de som (exemplo)',
      'Uma vaga de estacionamento (exemplo)',
    ],
    'space_rental.houseRule': [
      'Por favor, devolva os equipamentos após o uso.',
      'Por favor, respeite o horário reservado.',
    ],
    'space_rental.bookingPurpose': [
      'Encontro de estudos',
      'Encontro de amigos',
      'Ensaio de banda',
    ],
    'space_rental.guestMessage': [
      'Poderia me explicar como usar os equipamentos?',
      'Poderia enviar as instruções de acesso?',
    ],
    'space_rental.hostReply': [
      'Por favor, consulte o guia de equipamentos na página da reserva.',
      'As instruções de acesso aparecem nos detalhes da reserva.',
    ],

    // dining
    'dining.restaurantName': [
      'Casa de macarrão de perilla (fictício)',
      'Massas da Viela (fictício)',
      'Casa de chá Luzvale (fictício)',
    ],
    'dining.menuName': [
      'Macarrão de perilla',
      'Massa ao molho de tomate',
      'Tigela de arroz com legumes',
      'Chá quente',
    ],
    // A table is `Mesa para 1`, `Mesa para 4`: no plural to agree.
    'dining.partyLabel': ['Mesa para {n}'],
    'dining.noShowNote': [
      'Exemplo de registro de fila sem confirmação de chegada.',
      'Exemplo de ausência após o horário informado.',
    ],
    'dining.loyaltyBenefit': [
      'Bebida na quinta visita (exemplo)',
      'Cupom de sobremesa para cliente frequente (exemplo)',
    ],
    'dining.districtName': [
      'Cidade fictícia, bairro Luzvale',
      'Cidade fictícia, bairro Ribazul',
    ],

    // daycare
    'daycare.childName': ['Lia', 'Davi', 'Alice', 'Theo', 'Maya'],
    'daycare.className': ['Turma do Sol', 'Turma da Lua', 'Turma da Estrela'],
    'daycare.ageLabel': ['1 ano', '2 anos', '3 anos', '4 anos', '5 anos'],
    // {name1} is the first given name drawn: only `por` stands before it, which
    // does not contract with a name.
    'daycare.guardianLabel': ['Responsável por {name1}'],
    // The name is drawn without a sex, so the title takes both forms.
    'daycare.teacherName': ['Professor(a) {name1}'],
    'daycare.toiletNote': [
      'Uma ida ao banheiro registrada (exemplo)',
      'Duas idas ao banheiro registradas (exemplo)',
      'Nenhum registro (exemplo)',
    ],
    'daycare.mealMenu': [
      'Arroz integral com ensopado de legumes',
      'Sopa de tofu com arroz',
      'Arroz frito com legumes',
    ],
    'daycare.snackMenu': [
      'Fatias de pera',
      'Batata-doce cozida no vapor',
      'Iogurte natural',
    ],
    'daycare.allergenLabel': [
      'Leite',
      'Ovo',
      'Soja',
      'Trigo',
      'Nenhum registrado (exemplo)',
    ],
    'daycare.activityTitle': [
      'Brincadeiras na neve no inverno',
      'Construindo casinhas de papel',
      'Brincadeira com blocos coloridos',
    ],
    'daycare.albumCaption': [
      'Ilustração fictícia de amigos empilhando blocos juntos',
      'Ilustração fictícia de brincadeiras de inverno',
    ],
    'daycare.drugLabel': [
      'Antitérmico líquido (fictício)',
      'Xarope para tosse (fictício)',
      'Hidratante tópico (fictício)',
    ],
    'daycare.medicationStorage': [
      'Temperatura ambiente',
      'Manter na geladeira',
      'Proteger da luz do sol',
    ],
    'daycare.symptom': [
      'Coriza',
      'Tosse leve',
      'Febre baixa',
      'Manchas vermelhas na pele',
      'Dor de barriga',
    ],
    'daycare.dosageLabel': [
      'Exemplo preenchido pelo responsável: 2\u00A0mL',
      'Exemplo preenchido pelo responsável: 3\u00A0mL',
      'Exemplo preenchido pelo responsável: pequena quantidade',
    ],
    'daycare.noticeTitle': [
      'Aviso sobre brincadeiras de inverno (exemplo)',
      'Aviso de mudança no cardápio (exemplo)',
      'Aviso de verificação de segurança (exemplo)',
    ],

    // exam_prep
    'exam_prep.subjectName': [
      'Banco de dados',
      'Banco de dados',
      'Redes',
      'Redes',
      'Redes',
      'Fundamentos de programação',
      'Fundamentos de programação',
      'Segurança da informação',
      'Segurança da informação',
    ],
    'exam_prep.unitName': [
      'Modelagem de dados',
      'Fundamentos de SQL',
      'Camada de transporte',
      'Roteamento',
      'Camada de aplicação',
      'Variáveis',
      'Estruturas de dados',
      'Fundamentos de criptografia',
      'Controle de acesso',
    ],
    'exam_prep.questionStem': [
      'Qual chave distingue as linhas de uma tabela?',
      'Qual cláusula SQL seleciona linhas por meio de uma condição?',
      'Qual protocolo de transporte cuida da ordenação e da retransmissão?',
      'Qual equipamento escolhe a próxima rota de um pacote?',
      'Qual protocolo expressa requisições e respostas da web?',
      'O que guarda um valor sob um nome no programa?',
      'Qual estrutura remove primeiro o último valor inserido?',
      'O que calcula um resumo de tamanho fixo a partir de uma entrada?',
      'Qual princípio concede apenas as permissões necessárias para uma tarefa?',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      'Chave primária',
      'WHERE',
      'TCP',
      'Roteador',
      'HTTP',
      'Variável',
      'Pilha',
      'Função de hash',
      'Privilégio mínimo',
    ],
    'exam_prep.wrongChoice1': [
      'Fonte',
      'Fonte',
      'JPEG',
      'Alto-falante',
      'PNG',
      'Borda',
      'Fila FIFO',
      'Seleção de fonte',
      'Acesso público',
    ],
    'exam_prep.wrongChoice2': [
      'Cor de fundo',
      'Margem',
      'CSS',
      'Teclado',
      'MP3',
      'Margem da página',
      'Imagem',
      'Zoom da tela',
      'Senha compartilhada',
    ],
    'exam_prep.wrongChoice3': [
      'Largura da tela',
      'Ícone',
      'SVG',
      'Monitor',
      'TTF',
      'Imagem de fundo',
      'Arquivo de áudio',
      'Preenchimento de fundo',
      'Verificações ignoradas',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    // A term that opens a definition is written in the case of the list
    // (`Chave primária: ...`), because a test of the package compares the
    // explanation and the choice with the same case.
    'exam_prep.explanation': [
      'Chave primária: identifica cada linha de uma tabela.',
      'A cláusula WHERE expressa uma condição para selecionar linhas.',
      'O TCP cuida da ordenação e da retransmissão de um fluxo de bytes.',
      'Roteador: escolhe a próxima rota usando o endereço de destino.',
      'O HTTP expressa requisições e respostas da web.',
      'Variável: permite que um programa se refira a um valor pelo nome.',
      'Pilha: remove primeiro o último valor inserido.',
      'Função de hash: calcula um resumo de tamanho fixo a partir de uma entrada.',
      'Privilégio mínimo: concede apenas as permissões necessárias para uma tarefa.',
    ],
    'exam_prep.examPaperTitle': [
      'Simulado 1 (fictício)',
      'Simulado 2 (fictício)',
      'Prova de verificação da unidade (fictício)',
    ],
    'exam_prep.studyTaskTitle': [
      'Resolver dez questões sobre a camada de transporte',
      'Revisar os erros de controle de acesso',
      'Conferir os fundamentos de SQL',
    ],
    'exam_prep.taxonomyName': [
      'Banco de dados',
      'Redes',
      'Fundamentos de programação',
      'Segurança da informação',
    ],

    // hrd
    'hrd.departmentName': [
      'Vendas',
      'Produção',
      'Pesquisa',
      'Suporte',
      'Administração',
      'Logística',
    ],
    'hrd.jobTitle': ['Analista', 'Gerente', 'Líder de equipe'],
    'hrd.courseTitle': [
      'Tratamento de dados pessoais 2026 (fictício)',
      'Trabalhando com segurança em equipe (fictício)',
      'Organização de registros de trabalho (fictício)',
    ],
    'hrd.courseKind': ['Obrigatório', 'Profissional', 'Liderança'],
    'hrd.lessonTitle': [
      'Entender os princípios básicos',
      'Analisar exemplos de trabalho',
      'Conferir os registros',
    ],
    'hrd.chapterTitle': ['Introdução', 'Revisão de exemplos', 'Resumo'],
    'hrd.nudgeTitle': [
      'Lembrete de prazo do treinamento (exemplo)',
      'Lembrete de aula incompleta (exemplo)',
    ],
    'hrd.exemptionReason': [
      'Comprovante de conclusão externa (exemplo)',
      'Verificação do período de licença (exemplo)',
      'Verificação de treinamento alternativo (exemplo)',
    ],
    'hrd.classroomPlace': [
      'Sala de treinamento Luzvale (fictício)',
      'Sala de seminários Ribazul (fictício)',
    ],

    // neighborhood
    'neighborhood.neighborhoodName': [
      'Bairro Luzvale (fictício)',
      'Bairro Ginkgo (fictício)',
      'Bairro Jacarandal (fictício)',
    ],
    'neighborhood.districtName': [
      'Cidade fictícia, bairro Ribazul',
      'Cidade fictícia, bairro Solriacho',
    ],
    'neighborhood.nickname': [
      'FeijãoLuzvale (fictício)',
      'EstrelaJacarandal (fictício)',
      'NuvemDaViela (fictício)',
    ],
    'neighborhood.postTitle': [
      'Luva azul encontrada no parquinho (exemplo)',
      'Vamos descobrir um percurso de caminhada pelo bairro (exemplo)',
      'Vamos compartilhar um vasinho de planta (exemplo)',
    ],
    'neighborhood.postBody': [
      'Notícia fictícia do bairro. Os detalhes estão nesta publicação.',
      'Publicação de exemplo para os vizinhos; não inclui número de telefone nem endereço real.',
    ],
    'neighborhood.commentBody': [
      'Agradeço por compartilhar a novidade.',
      'Vou conferir e responder na publicação.',
      'Posso conferir à noite.',
    ],
    'neighborhood.placeName': [
      'Padaria Luzvale (fictício)',
      'Abrigo do parque Ribazul (fictício)',
      'Pequena biblioteca Jacarandal (fictício)',
    ],
    'neighborhood.openHours': ['8h às 21h', '9h às 18h', '10h às 20h'],
    'neighborhood.bannedWord': [
      'propaganda-exemplo',
      'ofensa-exemplo',
      'palavra-bloqueada-exemplo',
    ],
    'neighborhood.keyword': [
      'luva',
      'passeio',
      'compartilhamento',
      'notícias locais',
    ],

    // meetup
    'meetup.clubName': [
      'Corrida matinal de Luzvale (fictício)',
      'Clube de leitura de Ribazul (fictício)',
      'Jogos de tabuleiro de Jacarandal (fictício)',
    ],
    'meetup.interestTag': [
      'Corrida',
      'Leitura',
      'Jogos de tabuleiro',
      'Fotografia',
      'Culinária',
      'Trilhas',
    ],
    'meetup.availableDays': [
      'Noites de dias úteis',
      'Fins de semana',
      'Terça e quinta',
      'Sábado de manhã',
      'Qualquer dia',
    ],
    'meetup.clubIntro': [
      'Grupo fictício que acolhe vizinhos que participam pela primeira vez.',
      'Grupo de exemplo para compartilhar pequenas atividades juntos.',
    ],
    'meetup.gatheringTitle': [
      'Encontro da terceira semana de janeiro (fictício)',
      'Conversa sobre livros no fim de semana (fictício)',
      'Encontro de caminhada de inverno (fictício)',
    ],
    'meetup.venueName': [
      'Entrada da trilha de Ribazul (fictício)',
      'Sala de encontros de Luzvale (fictício)',
      'Abrigo de Jacarandal (fictício)',
    ],
    'meetup.nickname': [
      'FeijãoDaAurora (fictício)',
      'NuvemDeLivros (fictício)',
      'PequenaEstrela (fictício)',
    ],
    'meetup.duesItem': [
      'Taxa do encontro (exemplo)',
      'Bebidas divididas (exemplo)',
      'Aluguel de equipamentos dividido (exemplo)',
    ],
    'meetup.joinAnswer': [
      'Gostaria de participar das atividades a partir deste mês.',
      'Posso participar nas manhãs de fim de semana.',
    ],
    'meetup.ruleText': [
      'Por favor, respeite o tempo de todos.',
      'Por favor, converse dentro do grupo sem divulgar dados de contato.',
      'Por favor, avise o grupo ao cancelar.',
    ],
    'meetup.cadenceLabel': [
      'Todos os sábados, às 7h',
      'Domingos alternados, às 10h',
      'Primeiro sábado de cada mês, às 14h',
    ],

    // fandom
    // The two approved fictional creators of the fandom pack: Portuguese writes
    // two names of its own, never the Korean ones.
    'fandom.creatorName': ['Jardim da Ampulheta', 'Brisa de Linho'],
    'fandom.fanNickname': [
      'Estrelinha',
      'Brotinho',
      'Feijão Lunar',
      'Gota de Luz',
    ],
    'fandom.benefitTitle': [
      'Exemplo de imagem exclusiva para membros',
      'Inscrição simulada em evento',
      'Prévia antecipada de um clipe fictício',
    ],
    'fandom.postCaption': [
      'Ilustração fictícia de um estúdio no inverno',
      'Exemplo de publicação sobre o horário de ensaio',
    ],
    'fandom.clipTitle': [
      'Ensaio de trinta segundos (fictício)',
      'Saudação do estúdio (fictício)',
      'Nota sonora de inverno (fictício)',
    ],
    'fandom.letterBody': [
      'Gostei da publicação de exemplo de hoje e aguardo as próximas novidades.',
      'A ilustração do estúdio no inverno me pareceu acolhedora. Envio meu apoio.',
    ],
    'fandom.eventTitle': [
      'Encontro de fãs de inverno (fictício)',
      'Evento de histórias do estúdio (fictício)',
    ],
    'fandom.agendaTitle': [
      'Programação do pequeno teatro de inverno (fictício)',
      'Conversa fictícia transmitida ao vivo',
      'Cronograma de lançamento de novas publicações',
    ],
    'fandom.venueLabel': [
      'Pequeno teatro de inverno (fictício)',
      'Estúdio Luzvale (fictício)',
      'Espaço on-line de exemplo',
    ],

    // content
    'content.seriesTitle': [
      'A ilha postal do farol de papel (fictício)',
      'O pequeno mapa do lago das nuvens (fictício)',
      'O jardim do relógio lento (fictício)',
    ],
    'content.penName': [
      'Feijão das Palavras (fictício)',
      'Estrela de Papel (fictício)',
      'Pena de Nuvem (fictício)',
    ],
    'content.synopsisLine': [
      'Personagens fictícios organizam cartas em uma pequena ilha.',
      'Uma história fictícia sobre desenhar um lago que não está no mapa.',
    ],
    'content.genreName': [
      'Fantasia',
      'Cotidiano',
      'Aventura',
      'Histórias de ciência',
      'Ensaio',
    ],
    'content.seriesSection': [
      'Semanais',
      'Novidades',
      'Concluídas',
      'Diárias',
      'Séries curtas',
    ],
    'content.episodeTitle': [
      'O primeiro barquinho de papel (fictício)',
      'Um pequeno ponto no lago (fictício)',
      'Uma tarde sem relógio (fictício)',
    ],
    'content.cutAltText': [
      'Ilustração de um personagem fictício dobrando um barquinho de papel',
      'Ilustração de dois personagens fictícios ao lado de um lago',
    ],
    'content.commentLine': [
      'A cena do barquinho de papel ficou na minha memória.',
      'Gostaria de ler o próximo episódio de exemplo.',
    ],
    'content.chapterParagraph': [
      'Uma folha em branco repousava na caixa de correio da ilha. Uma criança a dobrou num barquinho com o formato do lago. Este parágrafo é um exemplo de demonstração fictício e original.',
      'Havia um pequeno vaso ao lado do relógio lento. Em vez de dar um nome à planta, dois amigos desenharam as nuvens que tinham visto. Este é um parágrafo de exemplo fictício e original.',
    ],
    'content.publisherName': [
      'Editora Farol de Papel (fictício)',
      'Editora Lago das Nuvens (fictício)',
    ],
    'content.audioTitle': [
      'Uma tarde dobrando barquinhos de papel (fictício)',
      'Notas sonoras de um pequeno lago (fictício)',
    ],
    'content.newsletterName': [
      'Notas semanais do Farol de Papel (fictício)',
      'Cartinhas do Lago das Nuvens (fictício)',
    ],
    'content.articleHeadline': [
      'Organizando anotações do dia a dia em pequenos grupos (fictício)',
      'Registrando as cores de uma caminhada de inverno (fictício)',
    ],
    'content.topicName': [
      'Anotações do dia a dia',
      'Caminhadas de inverno',
      'Pequena ciência',
      'Hábitos de leitura',
    ],
    'content.genreTaxonomy': [
      'Fantasia',
      'Cotidiano',
      'Aventura',
      'Histórias de ciência',
      'Ensaio',
    ],
    'content.audioTaxonomy': ['Audiolivro', 'Podcast'],
    'content.topicTaxonomy': [
      'Anotações do dia a dia',
      'Caminhadas de inverno',
      'Pequena ciência',
      'Hábitos de leitura',
      'Observações do cotidiano',
    ],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      'Por favor, verifique o status do convite da equipe',
      'Dúvida sobre os itens de uma fatura de exemplo',
      'Erro de exemplo ao exportar CSV',
      'Dúvida sobre o status da integração',
      'Dúvida sobre o botão de uma tela de exemplo',
      'Dúvida sobre onde encontrar a ajuda',
    ],
    'helpdesk.ticketDescription': [
      'A conta de suporte fictícia mostra um convite pendente.',
      'Gostaria de conferir os itens e o período da fatura fictícia.',
      'Aparece uma mensagem de erro ao exportar os dados de exemplo para CSV.',
      'Gostaria de conferir o texto da página de status da integração fictícia.',
      'A tela de exemplo continua igual depois que aperto um botão.',
      'Onde encontro a página de ajuda do suporte fictício?',
    ],
    'helpdesk.macroName': [
      'Exemplo de confirmação de recebimento',
      'Verificação de informações adicionais',
      'Aviso de status do processamento',
    ],
    'helpdesk.helpArticleTitle': [
      'Exemplo de guia de convites',
      'Como ler uma fatura fictícia',
      'Exportação de dados CSV de exemplo',
    ],
    'helpdesk.csatComment': [
      'Conferi a explicação.',
      'As instruções de exemplo foram fáceis de seguir.',
      'Tenho mais detalhes para conferir.',
    ],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      'Confira o status do convite nas configurações da conta. Este rascunho de IA simulado precisa ser revisado por um atendente.',
      'Registre juntos o método de login e o erro de exemplo. Este rascunho de IA simulado não faz nenhuma alteração na conta.',
      'Confira o período e os itens da fatura de exemplo. Este rascunho de IA simulado descreve preços fictícios.',
      'Registre o número da fatura de exemplo na nota de suporte. Este rascunho de IA simulado não é um aviso de pagamento real.',
      'Confira o intervalo de datas e o formato selecionados para a exportação. Este rascunho de IA simulado registra um erro de exemplo sem dados pessoais.',
      'Confira os nomes das colunas e o status do arquivo no CSV de exemplo. Este rascunho de IA simulado exige revisão de um atendente.',
      'Registre o status de integração de exemplo e o horário da verificação. Este rascunho de IA simulado não faz chamadas externas.',
      'Registre a tela e os passos para reproduzir o problema. Este rascunho de IA simulado não promete nenhum resultado.',
    ],
    'helpdesk.topicName': ['Conta', 'Cobrança', 'Dados', 'Integração'],

    // campaign
    'campaign.brandName': [
      'Padaria Luz de Primavera (fictício)',
      'Livraria Luar (fictício)',
      'Café Jardim Verde (fictício)',
    ],
    'campaign.campaignTitle': [
      'Exemplo de oferta de inverno',
      'Exemplo de novidades para a primeira visita',
      'Exemplo de novidades do fim de semana',
    ],
    'campaign.offerCopy': [
      '(Publicidade) Exemplo de cupom para um cardápio de inverno fictício. Para não receber mais mensagens, veja as configurações da demonstração.',
      '(Publicidade) Exemplo de oferta para um produto fictício. O cancelamento do recebimento está nas configurações da demonstração.',
    ],
    'campaign.couponTitle': [
      'Cupom de exemplo de 20% para o inverno',
      'Cupom de exemplo de 10% na primeira visita',
    ],
    'campaign.segmentName': [
      'Compradores de exemplo dos últimos 30 dias',
      'Grupo de exemplo que aceitou receber ofertas',
      'Grupo de exemplo das novidades de fim de semana',
    ],
    'campaign.failReason': [
      'Número do destinatário ausente (exemplo)',
      'Sem consentimento para marketing (exemplo)',
      'Sem consentimento para envio noturno (exemplo)',
    ],

    // workplace
    'workplace.department': [
      'Equipe de front-end',
      'Equipe de back-end',
      'Equipe de design',
      'Suporte ao cliente',
      'Recursos humanos',
    ],
    'workplace.approverRole': [
      'Líder de equipe',
      'Chefia do departamento',
      'Gerência de RH',
      'Revisão financeira',
      'Diretoria',
    ],
    'workplace.closeSection': [
      'Folha de pagamento',
      'Despesas',
      'Frequência',
      'Benefícios',
      'Provisões',
    ],
    'workplace.position': ['Analista', 'Gerente', 'Líder de equipe'],
    'workplace.workPlace': [
      'Escritório Luzvale (fictício)',
      'Centro de trabalho Ribazul (fictício)',
      'Remoto',
    ],
    'workplace.shiftName': [
      'Turno do dia',
      'Turno da manhã',
      'Plantão de fim de semana',
    ],
    'workplace.approvalComment': [
      'Analisei o registro de exemplo anexado.',
      'O motivo de exemplo precisa de mais esclarecimentos.',
    ],
    'workplace.projectName': [
      'Renovação do portal do cliente (fictício)',
      'Organização do wiki interno (fictício)',
      'Exemplo de melhoria de acessibilidade',
    ],
    'workplace.workItemTitle': [
      'Melhorar o texto do erro de login',
      'Conferir a ordenação da tabela de exemplo',
      'Organizar a exibição do status das notificações',
    ],
    'workplace.labelName': [
      'Texto',
      'Acessibilidade',
      'Backlog',
      'Precisa de verificação',
    ],
    'workplace.milestoneTitle': [
      'Marco da primeira revisão',
      'Tela de exemplo concluída',
      'Verificação de regressão',
    ],
    'workplace.sprintName': ['Sprint {n}'],
    'workplace.commentBody': [
      'Deixo meu comentário depois de conferir a tela de exemplo.',
      'Por favor, revise o texto antes da próxima tarefa.',
    ],
    'workplace.merchantName': [
      'Restaurante Flor Silvestre (fictício)',
      'Lanchonete da Viela (fictício)',
      'Papelaria Luzvale (fictício)',
    ],
    'workplace.accountName': [
      'Refeições (exemplo)',
      'Transporte (exemplo)',
      'Reuniões (exemplo)',
      'Suprimentos (exemplo)',
      'Viagens (exemplo)',
      'Outros (exemplo)',
    ],
    'workplace.rejectReasonText': [
      'Falta o comprovante de exemplo',
      'A classificação do item precisa ser verificada',
      'O limite da política de exemplo precisa ser verificado',
    ],

    // brokerage
    'brokerage.projectTitle': [
      'Exemplo de criação de portal do cliente',
      'Renovação fictícia de uma tela de serviço',
      'Exemplo de criação de tela de agendamento',
    ],
    'brokerage.serviceCategory': [
      'Interface web',
      'Interface de aplicativo',
      'Design corporativo',
      'Serviços residenciais',
    ],
    'brokerage.providerName': [
      'Estúdio Sótão do Código (fictício)',
      'Oficina de interfaces Luzvale (fictício)',
      'Oficina doméstica Ribazul (fictício)',
    ],
    'brokerage.providerHeadline': [
      'Parceiro fictício que apresenta telas de exemplo e registros de trabalho',
      'Perfil de exemplo para analisar o escopo de um projeto fictício',
    ],
    'brokerage.skillTag': [
      'Dart',
      'Planejamento de interfaces',
      'Organização de dados',
      'Redação de textos',
    ],
    'brokerage.proposalMessage': [
      'Preparei o escopo e os pontos de verificação do cronograma para o exemplo.',
      'Proponho pontos de verificação para as etapas do projeto fictício.',
    ],
    'brokerage.portfolioTitle': [
      'Exemplo fictício de portal do cliente',
      'Registro de exemplo de tela de agendamento',
      'Melhoria fictícia de uma tabela de trabalho',
    ],
    'brokerage.milestoneLabel': [
      'Verificação do escopo',
      'Verificação do rascunho das telas',
      'Verificação de função de exemplo',
      'Registro de entrega',
    ],
    'brokerage.homeServiceName': [
      'Limpeza de ar-condicionado (exemplo)',
      'Mudança de pequeno porte (exemplo)',
      'Verificação de torneira (exemplo)',
      'Aula de instrumento para iniciantes (exemplo)',
    ],
    'brokerage.requestAnswer': [
      'Gostaria de confirmar o escopo antes da visita.',
      'O horário de exemplo é uma manhã de fim de semana.',
    ],
    'brokerage.regionDong': [
      'Cidade fictícia, bairro Luzvale',
      'Cidade fictícia, bairro Ribazul',
      'Cidade fictícia, bairro Jacarandal',
    ],
    'brokerage.reviewText': [
      'Conferi o registro de trabalho de exemplo e as instruções.',
      'As instruções de horário de exemplo foram fáceis de seguir.',
    ],
    'brokerage.creditLabel': [
      'Crédito para envio de orçamento (exemplo)',
      'Crédito de reembolso de orçamento não visualizado (exemplo)',
      'Crédito de recarga (exemplo)',
    ],
    'brokerage.advisorTitle': [
      'Especialista tributário fictício',
      'Especialista jurídico fictício',
      'Especialista trabalhista fictício',
    ],
    'brokerage.consultTopic': [
      'Exemplo de explicação de terminologia',
      'Exemplo de lista de verificação antes da consulta',
      'Exemplo de explicação de lista de documentos',
    ],
    'brokerage.qnaQuestion': [
      'O que significa este termo do sistema? (pergunta fictícia)',
      'Quais campos aparecem em um registro de consulta? (pergunta fictícia)',
    ],
    // Every text starts with the general-information prefix of the language
    // (`test/language_safety/pt.dart`) and promises no result.
    'brokerage.qnaAnswerGeneric': [
      'Informação geral de exemplo. Uma visão geral do sistema pode listar termos, abrangência e documentos. Não contém nenhum julgamento sobre um caso individual.',
      'Informação geral de exemplo. Um registro de consulta separa as perguntas dos materiais de referência. Nenhum resultado específico nem linha de ação é indicado.',
    ],
    'brokerage.consultNoteGeneric': [
      'Informação geral, nota de exemplo: apresentou o tema da pergunta e os termos do sistema. A lista de documentos é composta de itens explicativos fictícios.',
      'Informação geral, nota de exemplo: revisou o formato do registro de consulta. Não há conclusão nem recomendação sobre um caso individual.',
    ],
    'brokerage.officeName': [
      'Escritório de atendimento Luzvale (fictício)',
      'Escritório de registros Ribazul (fictício)',
    ],
    'brokerage.serviceTypeName': ['Limpeza', 'Mudança', 'Conserto', 'Aulas'],

    // logistics
    'logistics.zoneName': [
      'Zona 1 Solriacho (fictício)',
      'Zona 2 Solriacho (fictício)',
      'Zona Ribazul (fictício)',
    ],
    'logistics.hubName': [
      'Centro de distribuição Luzvale (fictício)',
      'Centro de distribuição Ribazul (fictício)',
    ],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // The shape is the Brazilian plate (three letters, a hyphen, four digits),
    // with `●●` hiding its first two letters.
    'logistics.vehiclePlate': ['●●C-{n}{m}'],
    'logistics.deliveryNote': [
      'Não deixar na porta; entregar em mãos.',
      'Por favor, chame pelo interfone na entrada do prédio.',
      'Por favor, confirme na portaria.',
    ],
    'logistics.exceptionDetail': [
      'Ninguém atendeu à porta; foi deixado um aviso.',
      'A senha de entrada do prédio não funcionou.',
      'A caixa chegou amassada; foram tiradas fotos.',
      'O destinatário pediu a entrega para amanhã.',
      'O endereço não tem número do apartamento.',
    ],
    'logistics.entranceHint': [
      'Entrada do prédio nº ••••; chamar a portaria',
      'Usar o interfone da entrada; nenhuma senha exibida',
    ],
    'logistics.scanEvent': [
      'Chegada ao centro de distribuição',
      'Carregamento para transferência',
      'Saiu para entrega',
      'Entrega concluída',
      'Entrega não realizada',
    ],
    'logistics.carrierLabel': [
      'Transportadora de exemplo A (fictício)',
      'Transportadora de exemplo B (fictício)',
      'Transportadora de cargas de exemplo C (fictício)',
    ],
    'logistics.freightType': [
      'Embalagens',
      'Insumos alimentícios',
      'Materiais de construção',
      'Componentes eletrônicos',
      'Utilidades domésticas',
    ],
    'logistics.routeSummary': [
      'Zona fictícia Luzvale → zona Ribazul',
      'Zona fictícia Jacarandal → zona Solriacho',
    ],
    'logistics.fareItem': [
      'Frete base (exemplo)',
      'Adicional de plataforma elevatória (exemplo)',
      'Manuseio manual (exemplo)',
      'Tempo de espera (exemplo)',
    ],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': [
      'Caixa de papelão pequena',
      'Fita de embalagem 48\u00A0mm',
      'Toalhas de algodão, 3 unidades',
      'Arroz integral 2\u00A0kg',
    ],
    'logistics.ownerLabel': [
      'Embarcador A (fictício)',
      'Embarcador B (fictício)',
      'Embarcador C (fictício)',
    ],

    // hospitality
    'hospitality.propertyName': [
      'Refúgio Pinhalto (fictício)',
      'Hotel de descanso Ribazul (fictício)',
      'Pequena pousada Jacarandal (fictício)',
    ],
    'hospitality.siteName': [
      'Unidade Brisa do Pinhal A (fictício)',
      'Unidade Aroma do Pinhal B (fictício)',
      'Unidade Cone do Pinhal C (fictício)',
    ],
    'hospitality.amenity': [
      'Área de churrasqueira privativa',
      'Chuveiros compartilhados',
      'Wi-Fi',
    ],
    'hospitality.stayOption': [
      'Kit de churrasqueira (exemplo)',
      'Feixe de lenha (exemplo)',
      'Check-in antecipado (exemplo)',
    ],
    'hospitality.seasonName': [
      'Temporada regular',
      'Alta temporada de feriados (exemplo)',
      'Temporada promocional de dias de semana (exemplo)',
    ],
    'hospitality.ratePlan': [
      'Tarifa padrão de exemplo',
      'Tarifa de exemplo com café da manhã',
      'Tarifa de exemplo para dias de semana',
    ],
    'hospitality.houseRule': [
      'Por favor, mantenha silêncio nos espaços comuns à noite.',
      'Por favor, confira a lista de verificação de saída de exemplo.',
    ],
    'hospitality.bbqRule': [
      'A churrasqueira está disponível das 17h às 21h.',
      'Por favor, reserve a churrasqueira na recepção ao chegar.',
      'Carvão e grelha são fornecidos para cada área de camping.',
      'Por favor, apague o fogo completamente antes de sair.',
      'É proibido fazer churrasco na varanda dos quartos.',
    ],
    'hospitality.wifiHint': [
      'O nome da rede e a senha estão no cartão ao lado da porta.',
      'Por favor, peça a senha da rede de hóspedes na recepção.',
      'A rede de hóspedes alcança os quartos e a sala de estar.',
      'Se o sinal cair depois das 22h, conecte-se novamente.',
      'A senha muda toda segunda-feira.',
    ],
    'hospitality.reviewSnippet': [
      'As instruções de exemplo do quarto eram fáceis de ler.',
      'As instruções da hospedagem fictícia estão organizadas.',
    ],
    'hospitality.hkCheckItem': [
      'Trocar a roupa de cama',
      'Limpar o banheiro',
      'Conferir os itens de cortesia',
      'Conferir o frigobar',
    ],
    'hospitality.maintenanceIssue': [
      'Verificação de vazamento no banheiro (exemplo)',
      'Pedido de inspeção da iluminação (exemplo)',
      'Verificação do painel de climatização (exemplo)',
      'Verificação de dano em móvel (exemplo)',
    ],
    'hospitality.lostItemName': [
      'Guarda-chuva azul',
      'Cachecol cinza',
      'Um livro',
      'Garrafa de água',
    ],
    'hospitality.specialRequest': [
      'Andar alto, quarto para não fumantes (exemplo)',
      'Pedido de travesseiro extra (exemplo)',
      'Pedido de quarto silencioso (exemplo)',
    ],
    'hospitality.menuItem': [
      'Refeição com sopa de algas',
      'Massa com legumes',
      'Iogurte com frutas',
      'Chá quente',
    ],
    'hospitality.menuOption': [
      'Menos arroz',
      'Arroz normal',
      'Acompanhamento extra (exemplo)',
      'Sem gelo',
    ],
    'hospitality.amenityName': [
      'Toalha',
      'Água',
      'Escova de dentes',
      'Travesseiro',
    ],
    'hospitality.localSpot': [
      'Casa de caldos da manhã (fictício)',
      'Café da Viela (fictício)',
      'Trilha de caminhada Luzvale (fictício)',
    ],
    'hospitality.conciergeReply': [
      'As instruções da hospedagem fictícia aparecem nos detalhes da estadia.',
      'O pedido foi anotado no registro de exemplo.',
      'Os locais próximos são todos locais de demonstração fictícios.',
    ],
    'hospitality.folioItem': [
      'Diária (exemplo)',
      'Serviço de quarto (exemplo)',
      'Opção extra (exemplo)',
    ],
  },
  // The texts of Portuguese that read like the English ones on purpose: the
  // names of currencies, countries, and cities that are spelled alike, acronyms
  // and file formats, loanwords that Brazilian teams and studios keep in
  // English (`Backlog`, `Sprint`, `Reformer`), a dog breed (`Poodle`), a word
  // that both languages spell alike (`Tricolor`, `Monitor`), and the Wi-Fi of an
  // amenity. The language coverage gate reads this list.
  allowSameAsEnglish: <String, List<String>>{
    'fx.currencyName.EUR': ['Euro'],
    'fx.tierName': ['Bronze'],
    // The name of the country is spelled the same.
    'remit.countryName.NP': ['Nepal'],
    'remit.countryName.CN': ['China'],
    'vet.breed.dog': ['Poodle'],
    'vet.breed.small_mammal': ['Hamster'],
    'vet.coatColor': ['Tricolor'],
    'travel_wallet.cityName': ['Osaka'],
    // The name of a Pilates apparatus.
    'fitness.classCategoryLabel': ['Reformer'],
    'fitness.equipment': ['Reformer'],
    'space_rental.amenity': ['Wi-Fi'],
    'hospitality.amenity': ['Wi-Fi'],
    // Acronyms and file formats of the exam questions, and the word `monitor`,
    // which is the same in both languages.
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'HTTP'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF', 'Monitor'],
    'content.audioTaxonomy': ['Podcast'],
    // The name of a programming language.
    'brokerage.skillTag': ['Dart'],
    // Agile vocabulary that Brazilian teams keep in English.
    'workplace.labelName': ['Backlog'],
    'workplace.sprintName': ['Sprint {n}'],
    // The clinic data. Words that Portuguese shares with English: a kind of
    // procedure (`Laser`, `Lifting`), an answer (`Acne`), a unit, the card
    // networks, and the acronyms of devices and tags.
    'clinic.visitPurposes.details': ['Laser', 'Lifting', 'Acne'],
    'clinic.procedures.unit': ['ml'],
    // The units of a strength, which follow a no-break space.
    'clinic.drugForms.unit': ['*'],
    'clinic.questions.options': ['Acne'],
    'clinic.cardIssuers': ['Visa', 'Mastercard', 'Amex'],
    'clinic.texts.labels': ['HIFU', 'RF', 'IPL'],
    'clinic.ops.patientTags.label': ['VIP', 'Lifting'],
    'clinic.ops.labels': ['Tablet'],
    // The SaaS data: the message channels that are named by their acronym.
    'saas.labels': ['SMS', 'LMS'],
  },
);
