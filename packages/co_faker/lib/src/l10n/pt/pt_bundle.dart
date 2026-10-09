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
    'fitness.passName': [
      'Pacote de 10 aulas de solo (exemplo)',
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
    'daycare.dosageLabel': [
      'Exemplo preenchido pelo responsável: 2 mL',
      'Exemplo preenchido pelo responsável: 3 mL',
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
    'exam_prep.explanation': [
      'A chave primária identifica cada linha de uma tabela.',
      'A cláusula WHERE expressa uma condição para selecionar linhas.',
      'O TCP cuida da ordenação e da retransmissão de um fluxo de bytes.',
      'O roteador escolhe a próxima rota usando o endereço de destino.',
      'O HTTP expressa requisições e respostas da web.',
      'A variável permite que um programa se refira a um valor pelo nome.',
      'A pilha remove primeiro o último valor inserido.',
      'A função de hash calcula um resumo de tamanho fixo a partir de uma entrada.',
      'O privilégio mínimo concede apenas as permissões necessárias para uma tarefa.',
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
      'Vamos conhecer um caminho de passeio pelo bairro (exemplo)',
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
  },
);
