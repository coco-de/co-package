import '../co_l10n_bundle.dart';

/// Korean domain text: the Korean counterpart of every English key, with the
/// same number of texts in the same order.
///
/// The texts are what the domain packs and the dedicated generators have always
/// shown for `ko` and for regional codes such as `ko_KR`. See [CoL10nBundle].
const CoL10nBundle koBundle = CoL10nBundle(
  language: 'ko',
  texts: <String, List<String>>{
    // common
    // A masked name. {lastName} is a family name, {firstName} a given name, and
    // {initial} the first letter of a given name; only the placeholders a
    // template contains are drawn, so a language chooses which name it masks.
    'common.maskedName': ['{lastName}○○'],
    // The name of a child under a taxonomy root: {root} is the root name and {n}
    // the child number.
    'common.taxonomyChild': ['{root} · 세부 {n}'],

    // fx
    'fx.currencyName.USD': ['미국 달러'],
    'fx.currencyName.JPY': ['일본 엔'],
    'fx.currencyName.EUR': ['유로'],
    'fx.currencyName.CNY': ['중국 위안'],
    'fx.currencyName.THB': ['태국 바트'],
    'fx.currencyName.VND': ['베트남 동'],
    'fx.currencyName.PHP': ['필리핀 페소'],
    'fx.currencyName.NPR': ['네팔 루피'],
    // Same order as the branch kinds in CoFxDomain: airport, downtown, airport,
    // downtown, downtown.
    'fx.branchName': [
      '가람환전 공항 T1(가상)',
      '가람환전 솔빛점(가상)',
      '가람환전 공항 T2(가상)',
      '가람환전 가람점(가상)',
      '가람환전 물푸레점(가상)',
    ],
    'fx.couponName': ['USD 80% 우대(예시)', 'JPY 70% 우대(예시)', '첫 환전 우대(예시)'],
    'fx.tierName': ['브론즈', '실버', '골드'],

    // remit
    'remit.countryName.VN': ['베트남'],
    'remit.countryName.PH': ['필리핀'],
    'remit.countryName.NP': ['네팔'],
    'remit.countryName.US': ['미국'],
    'remit.countryName.CN': ['중국'],
    'remit.bankName': ['누리파트너은행(가상)'],
    'remit.flagRule': ['1건 고액(데모 기준)', '추가 서류 확인(데모 기준)', '반복 요청 확인(데모 기준)'],

    // vet
    'vet.petName': ['보리', '나비', '두부', '콩이', '구름'],
    // Same order as the weight ranges of CoFakerVet.
    'vet.breed.dog': ['말티즈', '푸들', '믹스견'],
    'vet.breed.cat': ['코리안숏헤어', '믹스묘'],
    'vet.breed.small_mammal': ['토끼', '햄스터'],
    'vet.breed.bird': ['소형 앵무'],
    'vet.breed.reptile': ['육지거북'],
    'vet.coatColor': ['흰색', '갈색', '검정', '삼색', '회색'],
    'vet.vaccineName': ['종합백신(예시)', '광견병 예방접종(예시)', '고양이 종합백신(예시)'],
    'vet.preventiveProduct': ['심장사상충 예방용 예시제(가상)', '외부 기생충 예방용 예시제(가상)'],
    'vet.vetDiagnosis': ['피부 상태 관찰(예시)', '소화 상태 확인(예시)', '정기 건강 확인(예시)'],
    'vet.vetDrug': ['피부 관리 예시제(가상)', '소화 관리 예시제(가상)', '눈 관리 예시제(가상)'],
    'vet.clinicRoom': ['동물 진료실 1', '동물 진료실 2', '예방접종실'],

    // grocery
    'grocery.originRegion': ['솔빛 재배권역(가상)', '가람 생산권역(가상)', '들녘 재배권역(가상)'],
    'grocery.harvestNote': ['수확일과 포장일은 예시입니다.', '신선도 표시는 가상 상품 설명입니다.'],
    'grocery.deliveryZone': ['솔빛 A권역(가상)', '가람 B권역(가상)', '들녘 C권역(가상)'],
    'grocery.slotLabel': ['새벽 06:00~07:00', '저녁 18:00~20:00'],
    'grocery.substitutionNote': [
      '비슷한 중량의 품목으로 대체한 예시입니다.',
      '대체 없이 해당 줄을 환불한 예시입니다.',
    ],
    'grocery.doorNote': ['공동현관은 호출해 주세요.', '문 앞 보관 대신 직접 수령합니다.'],
    'grocery.categoryName': ['과일', '채소', '간편식', '곡물', '육류', '수산', '유제품'],

    // catalog
    // Same order as the grocery catalog: category, storage, and price stay in
    // code.
    'catalog.groceryName': ['딸기', '시금치', '손만두', '현미', '닭 안심', '냉동 고등어', '우유'],
    // Korean and English output have always shown the same unit labels.
    'catalog.groceryUnit': ['500g', '200g', '1kg', '2kg', '500g', '600g', '1L'],
    'catalog.commerceName': ['무선 이어폰', '접이식 수납함', '면 수건 세트', '도자기 컵', '곡물 간식'],
    // Korean and English output have always shown the same unit labels.
    'catalog.commerceUnit': ['1 pair', '1 box', '3 pieces', '1 piece', '200g'],

    // booking
    'booking.cancelReason': ['일정 변경(예시)', '다른 시간 선택(예시)', '개인 사정(예시)'],

    // dental
    'dental.dentalProcedure': ['스케일링', '근관 치료(예시)', '레진 수복(예시)', '크라운 계획(예시)'],
    'dental.dentalMaterial': ['복합 레진(예시)', '지르코니아(예시)', '세라믹(예시)'],
    'dental.chairName': ['치과 체어 1', '치과 체어 2', '치과 체어 3'],
    'dental.hygieneNote': ['양치 방법 설명을 기록한 예시입니다.', '구강 위생 확인 내용을 기록한 예시입니다.'],

    // homecare
    'homecare.careGrade': [
      '장기요양 1등급',
      '장기요양 2등급',
      '장기요양 3등급',
      '장기요양 4등급',
      '장기요양 5등급',
      '인지지원등급',
    ],
    'homecare.careTaskLabel': [
      '식사 돕기',
      '복약 확인',
      '위생 돕기',
      '이동 돕기',
      '배변 돕기',
      '말벗',
    ],

    // travel_wallet
    'travel_wallet.merchantNameFictional': [
      '골목 우동집(가상)',
      '역 앞 편의점(가상)',
      '여행자 숙소(가상)',
    ],
    'travel_wallet.cityName': ['오사카', '도쿄', '방콕', '하노이'],
    'travel_wallet.cardAlias': ['나들이 트래블(가상)', '여행 예산 카드(가상)'],
    'travel_wallet.tripName': ['오사카 3박 4일', '방콕 주말 여행', '하노이 산책 여행'],

    // b2b_trade
    'b2b_trade.buyerCompany': ['카페 온새(가상)', '제과점 밀담(가상)', '식자재점 솔내(가상)'],
    // Same order as the wholesale items in CoB2bTradeDomain: CUP, FRZ, PKG, HYG.
    'b2b_trade.itemSpec': [
      '12oz 종이컵 1,000입',
      '냉동 감자 10kg',
      '종이 포장 봉투 100입',
      '무향 위생 수건 20입',
    ],
    'b2b_trade.quoteTitle': [
      '월간 포장재 견적(가상)',
      '주간 식자재 견적(가상)',
      '위생용품 추가 견적(가상)',
    ],
    'b2b_trade.holdReason': [
      '가용 한도 확인 대기(예시)',
      '납품일 확인 대기(예시)',
      '품목 규격 확인 대기(예시)',
    ],

    // group_deal
    'group_deal.dealTitle': ['겨울 감귤 공동구매', '무선 이어폰 공동구매', '면 수건 세트 공동구매'],
    'group_deal.optionLabel': ['일반 크기', '선물 포장', '기본 색상'],
    'group_deal.rewardLabel': ['참여 스탬프', '모의 적립 포인트', '배송 혜택'],
    'group_deal.benefitTitle': ['무료배송 예시 쿠폰', '다음 참여 예시 쿠폰'],
    'group_deal.settleNote': [
      '성사한 참여 건을 집계한 예시입니다.',
      '취소한 참여 건은 집계에서 뺀 예시입니다.',
    ],

    // fitness
    // A class name from the category label and the level label of the same
    // record.
    'fitness.className': ['{category} {level}'],
    'fitness.classCategoryLabel': ['매트', '리포머', '체어', '요가'],
    'fitness.classLevelLabel': ['기초', '중급', '상급'],
    'fitness.equipment': ['매트', '리포머', '체어', '요가 블록'],
    'fitness.studioRoom': ['매트룸', '리포머룸', '체어룸', '요가룸'],
    'fitness.instructorSpecialty': ['매트 수업', '리포머 수업', '요가 수업'],
    'fitness.instructorCareer': [
      '매트 수업 경력 5년',
      '리포머 수업 경력 3년',
      '그룹 요가 경력 8년',
      '소그룹 트레이닝 경력 2년',
      '재활 중심 수업 경력 6년',
    ],
    'fitness.passName': ['매트 10회권(예시)', '리포머 20회권(예시)', '1개월 이용권(예시)'],
    'fitness.cancelReason': ['일정 변경', '수업 시간 변경'],
    'fitness.noShowNote': ['출석 확인이 없는 예시 기록입니다.', '시작 시각 이후 미출석으로 표시한 예시입니다.'],

    // space_rental
    'space_rental.spaceName': ['오후네시 파티룸(가상)', '솔빛 스터디룸(가상)', '가람 연습실(가상)'],
    'space_rental.districtName': ['가상시 솔빛동', '가상시 가람동', '가상시 물푸레동'],
    'space_rental.amenity': ['무선 인터넷', '화이트보드', '정수기'],
    'space_rental.equipmentOption': ['빔프로젝터(예시)', '음향 장비(예시)', '주차 1대(예시)'],
    'space_rental.houseRule': ['이용 후 물품을 제자리에 놓아 주세요.', '예약한 이용 시간을 지켜 주세요.'],
    'space_rental.bookingPurpose': ['스터디 모임', '친구 모임', '합주 연습'],
    'space_rental.guestMessage': ['장비 이용 방법을 확인하고 싶어요.', '입실 안내를 부탁드립니다.'],
    'space_rental.hostReply': [
      '예약 화면의 장비 안내를 확인해 주세요.',
      '입실 안내는 예약 상세에 표시됩니다.',
    ],

    // dining
    'dining.restaurantName': ['들기름 국숫집(가상)', '골목 파스타집(가상)', '솔빛 찻집(가상)'],
    'dining.menuName': ['들기름 국수', '토마토 파스타', '채소 덮밥', '따뜻한 차'],
    'dining.partyLabel': ['{n}인 일행'],
    'dining.noShowNote': ['도착 확인이 없는 예시 대기 기록입니다.', '안내 시각 이후 미방문으로 표시했습니다.'],
    'dining.loyaltyBenefit': ['다섯 번째 방문 음료(예시)', '단골 디저트 쿠폰(예시)'],
    'dining.districtName': ['가상시 솔빛동', '가상시 가람동'],

    // daycare
    'daycare.childName': ['지우', '하늘', '다온', '나래', '소담'],
    'daycare.className': ['해님반', '달님반', '별님반'],
    'daycare.ageLabel': ['만 1세', '만 2세', '만 3세', '만 4세', '만 5세'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.guardianLabel': ['{name1} 보호자'],
    // {name1} is the first given name drawn and {name2} the second. Both are
    // drawn in every language, and English has always shown the second one.
    'daycare.teacherName': ['{name1} 선생님'],
    'daycare.toiletNote': ['배변 기록 1회(예시)', '배변 기록 2회(예시)', '기록 없음(예시)'],
    'daycare.mealMenu': ['현미밥 · 채소 스튜', '두부 국 · 밥', '채소 볶음밥'],
    'daycare.snackMenu': ['배 조각', '찐 고구마', '플레인 요거트'],
    'daycare.allergenLabel': ['우유', '달걀', '대두', '밀', '해당 없음(예시)'],
    'daycare.activityTitle': ['겨울 눈놀이', '종이 집 만들기', '색깔 블록 놀이'],
    'daycare.albumCaption': ['친구와 블록을 쌓는 가상 일러스트', '겨울 놀이를 그린 가상 일러스트'],
    'daycare.drugLabel': ['해열용 시럽(가상)', '기침용 시럽(가상)', '보습용 외용제(가상)'],
    'daycare.medicationStorage': ['실온 보관', '냉장 보관', '직사광선을 피해 보관'],
    'daycare.symptom': ['콧물', '가벼운 기침', '미열', '피부 발진', '배탈'],
    'daycare.dosageLabel': [
      '보호자 작성 예시: 2mL',
      '보호자 작성 예시: 3mL',
      '보호자 작성 예시: 소량',
    ],
    'daycare.noticeTitle': ['겨울 놀이 안내(예시)', '식단 변경 안내(예시)', '안전 확인 안내(예시)'],

    // exam_prep
    'exam_prep.subjectName': [
      '데이터베이스',
      '데이터베이스',
      '네트워크',
      '네트워크',
      '네트워크',
      '프로그래밍 기초',
      '프로그래밍 기초',
      '정보보안',
      '정보보안',
    ],
    'exam_prep.unitName': [
      '데이터 모델',
      'SQL 기초',
      '전송 계층',
      '경로 선택',
      '응용 계층',
      '변수',
      '자료 구조',
      '암호 기초',
      '접근 제어',
    ],
    'exam_prep.questionStem': [
      '표의 각 행을 구분하는 키는 무엇인가요?',
      '조건에 맞는 행을 조회할 때 쓰는 SQL 절은 무엇인가요?',
      '순서와 재전송을 제공하는 전송 프로토콜은 무엇인가요?',
      '목적지에 따라 패킷의 다음 경로를 고르는 장비는 무엇인가요?',
      '웹 요청과 응답을 주고받는 프로토콜은 무엇인가요?',
      '프로그램에서 값을 이름으로 보관하는 요소는 무엇인가요?',
      '나중에 넣은 값부터 꺼내는 자료 구조는 무엇인가요?',
      '고정 길이 요약 값을 만드는 함수는 무엇인가요?',
      '업무에 필요한 권한만 부여하는 원칙은 무엇인가요?',
    ],
    // Every question has four choices, and the first one is the correct answer:
    // the generator shuffles them.
    'exam_prep.correctChoice': [
      '기본 키',
      'WHERE',
      'TCP',
      '라우터',
      'HTTP',
      '변수',
      '스택',
      '해시 함수',
      '최소 권한',
    ],
    'exam_prep.wrongChoice1': [
      '글꼴',
      '글꼴',
      'JPEG',
      '스피커',
      'PNG',
      '테두리',
      '선입선출 큐',
      '글꼴 선택',
      '전체 공개',
    ],
    'exam_prep.wrongChoice2': [
      '배경색',
      '여백',
      'CSS',
      '키보드',
      'MP3',
      '페이지 여백',
      '이미지',
      '화면 확대',
      '공유 비밀번호',
    ],
    'exam_prep.wrongChoice3': [
      '화면 너비',
      '아이콘',
      'SVG',
      '모니터',
      'TTF',
      '배경 이미지',
      '음성 파일',
      '배경 채우기',
      '검사 생략',
    ],
    // Each explanation contains the text of its correct choice, and the four
    // choices of a question are different from one another: tests check both.
    'exam_prep.explanation': [
      '기본 키는 표의 각 행을 구분하는 식별자입니다.',
      'WHERE 절은 조회할 행의 조건을 표현합니다.',
      'TCP는 바이트 스트림의 순서와 재전송을 처리합니다.',
      '라우터는 목적지 주소를 바탕으로 다음 경로를 선택합니다.',
      'HTTP는 웹 요청과 응답을 표현하는 응용 프로토콜입니다.',
      '변수는 프로그램에서 값을 이름으로 참조하도록 합니다.',
      '스택은 나중에 넣은 값을 먼저 꺼내는 구조입니다.',
      '해시 함수는 입력으로부터 고정 길이 요약 값을 계산합니다.',
      '최소 권한은 업무에 필요한 권한만 부여하는 원칙입니다.',
    ],
    'exam_prep.examPaperTitle': ['1회 실전(가상)', '2회 실전(가상)', '단원 확인 시험(가상)'],
    'exam_prep.studyTaskTitle': ['전송 계층 10문항 풀기', '접근 제어 오답 복습', 'SQL 기초 확인'],
    'exam_prep.taxonomyName': ['데이터베이스', '네트워크', '프로그래밍 기초', '정보보안'],

    // hrd
    'hrd.departmentName': ['영업', '생산', '연구개발', '고객지원', '경영지원', '물류'],
    'hrd.jobTitle': ['사원', '매니저', '팀장'],
    'hrd.courseTitle': [
      '개인정보 바르게 다루기 2026(가상)',
      '함께 일하는 안전 수칙(가상)',
      '업무 기록 정리 기초(가상)',
    ],
    'hrd.courseKind': ['법정의무', '직무', '리더십'],
    'hrd.lessonTitle': ['기본 원칙 알아보기', '업무 사례 살펴보기', '기록 확인하기'],
    'hrd.chapterTitle': ['시작 안내', '사례 확인', '요약 정리'],
    'hrd.nudgeTitle': ['기한이 가까운 교육 확인(예시)', '미완료 차시 안내(예시)'],
    'hrd.exemptionReason': ['외부 이수 증빙 제출(예시)', '휴직 기간 확인(예시)', '대체 교육 확인(예시)'],
    'hrd.classroomPlace': ['솔빛 교육실(가상)', '가람 세미나실(가상)'],

    // neighborhood
    'neighborhood.neighborhoodName': ['솔빛동(가상)', '은행나무동(가상)', '물푸레동(가상)'],
    'neighborhood.districtName': ['가상시 가람구', '가상시 솔내구'],
    'neighborhood.nickname': ['솔빛콩(가상)', '물푸레별(가상)', '골목구름(가상)'],
    'neighborhood.postTitle': [
      '놀이터에서 파란 장갑을 찾았어요(예시)',
      '동네 산책길을 함께 알아봐요(예시)',
      '작은 화분을 나눠요(예시)',
    ],
    'neighborhood.postBody': [
      '가상의 동네 소식입니다. 자세한 내용은 글 안에서 확인해 주세요.',
      '이웃과 나누기 위한 예시 글입니다. 연락처나 실제 주소는 없습니다.',
    ],
    'neighborhood.commentBody': [
      '소식 알려 주셔서 고마워요.',
      '확인하고 글에 답글을 남길게요.',
      '저녁 시간에 확인할 수 있어요.',
    ],
    'neighborhood.placeName': ['솔빛제과(가상)', '가람공원 쉼터(가상)', '물푸레 작은도서관(가상)'],
    'neighborhood.openHours': ['08:00~21:00', '09:00~18:00', '10:00~20:00'],
    'neighborhood.bannedWord': ['광고예시', '욕설예시', '금칙어예시'],
    'neighborhood.keyword': ['장갑', '산책', '나눔', '동네 소식'],

    // meetup
    'meetup.clubName': ['솔빛 아침 러닝(가상)', '가람 책 모임(가상)', '물푸레 보드게임(가상)'],
    'meetup.interestTag': ['러닝', '독서', '보드게임', '사진', '요리', '등산'],
    'meetup.availableDays': ['평일 저녁', '주말', '화요일과 목요일', '토요일 오전', '요일 무관'],
    'meetup.clubIntro': [
      '처음 참여하는 이웃도 함께하는 가상 모임입니다.',
      '작은 활동을 함께 나누는 예시 모임입니다.',
    ],
    'meetup.gatheringTitle': ['1월 셋째 주 정모(가상)', '주말 책 이야기(가상)', '겨울 산책 모임(가상)'],
    'meetup.venueName': ['가람 산책길 입구(가상)', '솔빛 작은모임방(가상)', '물푸레 쉼터(가상)'],
    'meetup.nickname': ['새벽콩(가상)', '책구름(가상)', '작은별(가상)'],
    'meetup.duesItem': ['정모 참가비(예시)', '음료 분담(예시)', '장비 대여 분담(예시)'],
    'meetup.joinAnswer': ['이번 달부터 함께 활동해 보고 싶어요.', '주말 오전에 참여할 수 있어요.'],
    'meetup.ruleText': [
      '서로의 시간을 존중해 주세요.',
      '연락처 공개 없이 모임 안에서 이야기해 주세요.',
      '취소할 때 모임에 알려 주세요.',
    ],
    'meetup.cadenceLabel': ['매주 토 07:00', '격주 일 10:00', '매월 첫째 토 14:00'],

    // fandom
    // The two approved fictional creators of the fandom pack.
    'fandom.creatorName': ['모래시계 정원', '하늘결'],
    'fandom.fanNickname': ['별님', '새싹', '달콩', '빛방울'],
    'fandom.benefitTitle': ['멤버 전용 예시 사진', '모의 이벤트 응모', '가상 클립 먼저 보기'],
    'fandom.postCaption': ['겨울 작업실을 그린 가상 일러스트', '연습 시간을 기록한 예시 게시물'],
    'fandom.clipTitle': ['리허설 30초(가상)', '작업실 인사(가상)', '겨울 소리 메모(가상)'],
    'fandom.letterBody': [
      '오늘의 예시 게시물을 즐겁게 봤어요. 다음 소식도 기다릴게요.',
      '겨울 작업실 일러스트가 따뜻하게 느껴졌어요. 응원의 마음을 남깁니다.',
    ],
    'fandom.eventTitle': ['겨울 팬 모임 응모(가상)', '작업실 이야기 이벤트(가상)'],
    'fandom.agendaTitle': ['겨울 소극장 일정(가상)', '가상 방송 이야기', '새 게시물 공개 일정'],
    'fandom.venueLabel': ['겨울 소극장(가상)', '솔빛 작업실(가상)', '온라인 예시 공간'],

    // content
    'content.seriesTitle': [
      '종이등대의 우편 섬(가상)',
      '구름연못의 작은 지도(가상)',
      '느린 시계의 화원(가상)',
    ],
    'content.penName': ['글콩(가상)', '종이별(가상)', '구름펜(가상)'],
    'content.synopsisLine': [
      '작은 섬에서 편지를 정리하는 가상 인물들의 이야기입니다.',
      '지도에 없는 연못을 함께 그려 보는 가상의 이야기입니다.',
    ],
    'content.genreName': ['판타지', '일상', '모험', '과학 이야기', '에세이'],
    'content.seriesSection': ['주간 연재', '신작', '완결', '매일 연재', '단편'],
    'content.episodeTitle': ['첫 번째 종이 배(가상)', '연못의 작은 점(가상)', '시계 없는 오후(가상)'],
    'content.cutAltText': ['가상 인물이 종이 배를 접는 일러스트', '연못 옆 가상 인물 둘의 일러스트'],
    'content.commentLine': ['종이 배 장면이 기억에 남아요.', '다음 예시 회차도 읽어 보고 싶어요.'],
    'content.chapterParagraph': [
      '섬의 우편함에는 빈 종이 한 장이 놓여 있었다. 아이는 종이를 반으로 접고, 연못을 닮은 작은 배를 만들었다. 이 단락은 데모를 위해 직접 쓴 가상 문장이다.',
      '느린 시계 옆에는 작은 화분이 있었다. 두 친구는 화분 이름을 정하는 대신 오늘 본 구름을 그림으로 남겼다. 이 단락은 직접 작성한 가상 예시다.',
    ],
    'content.publisherName': ['종이등대 출판소(가상)', '구름연못 출판소(가상)'],
    'content.audioTitle': ['종이 배를 접는 오후(가상)', '작은 연못의 소리 메모(가상)'],
    'content.newsletterName': ['종이등대 주간 메모(가상)', '구름연못 작은 편지(가상)'],
    'content.articleHeadline': [
      '일상 기록을 작은 묶음으로 정리하기(가상)',
      '겨울 산책의 색을 남기는 방법(가상)',
    ],
    'content.topicName': ['일상 기록', '겨울 산책', '작은 과학', '읽기 습관'],
    'content.genreTaxonomy': ['판타지', '일상', '모험', '과학 이야기', '에세이'],
    'content.audioTaxonomy': ['오디오북', '팟캐스트'],
    'content.topicTaxonomy': ['일상 기록', '겨울 산책', '작은 과학', '읽기 습관', '생활 관찰'],

    // helpdesk
    // Same order as the ticket categories in CoHelpdeskDomain.
    'helpdesk.ticketSubject': [
      '팀 초대 상태를 확인하고 싶어요',
      '예시 청구서 항목 문의',
      'CSV 내보내기 예시 오류',
      '연동 상태 표시 문의',
      '예시 화면 버튼 동작 문의',
      '도움말 위치 문의',
    ],
    'helpdesk.ticketDescription': [
      '응답데스크 예시 계정의 초대 상태가 대기 중으로 보여요.',
      '가상 청구서의 항목과 기간을 확인하고 싶어요.',
      '예시 데이터를 CSV로 내보낼 때 오류 상태가 보여요.',
      '가상 연동 상태 화면의 문구를 확인하고 싶어요.',
      '예시 화면에서 버튼을 누른 뒤 같은 화면이 보여요.',
      '응답데스크 예시 도움말을 어디서 볼 수 있나요?',
    ],
    'helpdesk.macroName': ['예시 접수 확인', '추가 정보 확인', '처리 상태 안내'],
    'helpdesk.helpArticleTitle': ['예시 계정 초대 안내', '가상 청구서 읽기', '예시 CSV 내보내기'],
    'helpdesk.csatComment': [
      '설명 내용을 확인했습니다.',
      '예시 안내가 이해하기 쉬웠어요.',
      '추가로 확인할 내용이 있어요.',
    ],
    // Same order as the draft categories in CoFakerHelpdesk.
    'helpdesk.draftBody': [
      '계정 설정 화면에서 초대 상태를 확인해 주세요. 이 문장은 모의 AI 초안이며 상담원 검토가 필요합니다.',
      '로그인 방법과 표시된 예시 오류를 함께 기록해 주세요. 모의 AI 초안이므로 실제 계정 변경은 하지 않습니다.',
      '예시 청구서의 기간과 항목을 확인해 주세요. 금액은 가상 요금표를 설명하는 모의 AI 초안입니다.',
      '청구 알림의 예시 번호를 상담 기록에 남겨 주세요. 실제 결제 안내가 아닌 모의 AI 초안입니다.',
      '내보내기 화면에서 선택한 기간과 형식을 확인해 주세요. 개인정보를 제외한 예시 오류 내용을 남기는 모의 AI 초안입니다.',
      '예시 CSV의 열 이름과 파일 상태를 확인해 주세요. 상담원이 내용을 검토하는 모의 AI 초안입니다.',
      '연동 설정에 표시된 예시 상태와 확인 시각을 기록해 주세요. 외부 호출을 하지 않는 모의 AI 초안입니다.',
      '문제가 보인 화면과 재현 순서를 기록해 주세요. 결과를 약속하지 않는 모의 AI 초안입니다.',
    ],
    'helpdesk.topicName': ['계정', '청구', '데이터', '연동'],

    // campaign
    'campaign.brandName': ['봄빛베이커리(가상)', '달빛책방(가상)', '초록정원카페(가상)'],
    'campaign.campaignTitle': ['겨울 예시 혜택 안내', '첫 방문 예시 소식', '주말 예시 소식'],
    'campaign.offerCopy': [
      '(광고) 가상 겨울 메뉴의 예시 쿠폰입니다. 수신 거부는 데모 설정에서 확인해 주세요.',
      '(광고) 가상 상품의 예시 혜택을 안내합니다. 수신 거부는 데모 설정에 있습니다.',
    ],
    'campaign.couponTitle': ['겨울 20% 예시 쿠폰', '첫 방문 10% 예시 쿠폰'],
    'campaign.segmentName': ['최근 30일 예시 구매자', '광고 동의 예시 그룹', '주말 소식 예시 그룹'],
    'campaign.failReason': ['수신 번호 없음(예시)', '광고 동의 없음(예시)', '야간 동의 없음(예시)'],

    // workplace
    'workplace.department': ['프런트엔드팀', '백엔드팀', '디자인팀', '고객지원팀', '인사팀'],
    'workplace.approverRole': ['팀장', '부서장', '인사 담당자', '재무 검토자', '임원'],
    'workplace.closeSection': ['급여', '경비', '근태', '복리후생', '미지급 비용'],
    'workplace.position': ['사원', '매니저', '팀장'],
    'workplace.workPlace': ['솔빛 사무실(가상)', '가람 업무센터(가상)', '재택'],
    'workplace.shiftName': ['주간 근무', '오전 근무', '주말 당직'],
    'workplace.approvalComment': ['첨부한 예시 기록을 확인했습니다.', '예시 사유에 추가 확인이 필요합니다.'],
    'workplace.projectName': ['고객 포털 정비(가상)', '사내 위키 정리(가상)', '접근성 개선 예시'],
    'workplace.workItemTitle': ['로그인 오류 문구 개선', '예시 표 정렬 확인', '알림 상태 표시 정리'],
    'workplace.labelName': ['문구', '접근성', '백로그', '확인 필요'],
    'workplace.milestoneTitle': ['첫 검토 마일스톤', '예시 화면 완료', '회귀 확인'],
    'workplace.sprintName': ['스프린트 {n}'],
    'workplace.commentBody': [
      '예시 화면을 확인한 뒤 의견을 남깁니다.',
      '다음 작업 전에 문구를 함께 확인해 주세요.',
    ],
    'workplace.merchantName': ['한식당 들꽃(가상)', '골목 다과점(가상)', '솔빛 사무용품점(가상)'],
    'workplace.accountName': [
      '식대(예시)',
      '교통비(예시)',
      '회의비(예시)',
      '소모품비(예시)',
      '출장비(예시)',
      '기타비(예시)',
    ],
    'workplace.rejectReasonText': [
      '예시 영수증 누락',
      '항목 분류 확인 필요',
      '예시 정책 한도 확인 필요',
    ],

    // brokerage
    'brokerage.projectTitle': ['예시 고객 포털 제작', '가상 서비스 화면 정비', '예시 예약 화면 제작'],
    'brokerage.serviceCategory': ['웹 화면 제작', '앱 화면 제작', '업무 디자인', '생활 서비스'],
    'brokerage.providerName': ['코드다락 스튜디오(가상)', '솔빛 화면공방(가상)', '가람 생활공방(가상)'],
    'brokerage.providerHeadline': [
      '예시 화면과 작업 기록을 소개하는 가상 파트너',
      '가상 프로젝트의 범위를 함께 확인하는 예시 프로필',
    ],
    'brokerage.skillTag': ['Dart', '화면 설계', '데이터 정리', '문구 작성'],
    'brokerage.proposalMessage': [
      '예시 작업 범위와 일정 확인 항목을 정리했습니다.',
      '가상 프로젝트의 단계별 확인 항목을 제안합니다.',
    ],
    'brokerage.portfolioTitle': ['가상 고객 포털 예시', '예시 예약 화면 기록', '가상 업무 표 개선'],
    'brokerage.milestoneLabel': ['범위 확인', '화면 초안 확인', '예시 기능 확인', '인계 기록'],
    'brokerage.homeServiceName': [
      '에어컨 청소(예시)',
      '작은 이사(예시)',
      '수전 확인(예시)',
      '기초 악기 레슨(예시)',
    ],
    'brokerage.requestAnswer': ['방문 전 작업 범위를 확인하고 싶어요.', '예시 일정은 주말 오전입니다.'],
    'brokerage.regionDong': ['가상시 솔빛동', '가상시 가람동', '가상시 물푸레동'],
    'brokerage.reviewText': ['예시 작업 기록과 안내를 확인했습니다.', '예시 일정 안내가 이해하기 쉬웠어요.'],
    'brokerage.creditLabel': ['견적 제출 크레딧(예시)', '미열람 환급 크레딧(예시)', '충전 크레딧(예시)'],
    'brokerage.advisorTitle': ['가상 세무 전문가', '가상 법률 전문가', '가상 노무 전문가'],
    'brokerage.consultTopic': ['제도 용어 안내 예시', '상담 전 확인 항목 예시', '서류 목록 설명 예시'],
    'brokerage.qnaQuestion': [
      '제도 용어는 어떤 뜻인가요?(가상 질문)',
      '상담 기록에는 어떤 항목이 있나요?(가상 질문)',
    ],
    'brokerage.qnaAnswerGeneric': [
      '일반 정보 예시입니다. 제도 안내에는 용어, 대상 범위, 확인 자료 등의 항목이 있습니다. 개별 사안에 대한 판단은 포함하지 않습니다.',
      '일반 정보 예시입니다. 상담 기록은 질문과 확인 자료를 구분해 적는 형식으로 구성됩니다. 특정 결과나 처리 방법을 제시하지 않습니다.',
    ],
    'brokerage.consultNoteGeneric': [
      '일반 정보 예시 기록: 질문 주제와 제도 용어를 소개했습니다. 자료 목록은 설명을 위한 가상 항목입니다.',
      '일반 정보 예시 기록: 상담 화면의 기록 형식을 살펴봤습니다. 개별 사건의 결론이나 조언은 없습니다.',
    ],
    'brokerage.officeName': ['솔빛 상담사무소(가상)', '가람 기록사무소(가상)'],
    'brokerage.serviceTypeName': ['청소', '이사', '수리', '레슨'],

    // logistics
    'logistics.zoneName': ['솔내동 1권역(가상)', '솔내동 2권역(가상)', '가람동 권역(가상)'],
    'logistics.hubName': ['솔빛 허브(가상)', '가람 허브(가상)'],
    // A masked plate: {n} is a two-digit number and {m} the last two digits.
    // Korean and English output have always shown this Korean plate format.
    'logistics.vehiclePlate': ['{n}가●●{m}'],
    'logistics.deliveryNote': [
      '문 앞 보관 금지 · 직접 수령',
      '공동현관에서 호출해 주세요.',
      '경비실 확인 후 전달해 주세요.',
    ],
    'logistics.exceptionDetail': [
      '문 앞에서 응답이 없어 안내문을 남겼습니다.',
      '공동현관 출입 번호가 맞지 않았습니다.',
      '도착 시 상자가 찌그러져 있어 사진을 남겼습니다.',
      '받는 분이 내일 배송을 요청했습니다.',
      '주소에 동·호수가 없습니다.',
    ],
    'logistics.entranceHint': ['공동현관 #●●●● · 경비실 호출', '입구 호출 버튼 이용 · 비밀번호 없음'],
    'logistics.scanEvent': ['허브 입고', '간선 상차', '배송 출발', '배송 완료', '미배송'],
    'logistics.carrierLabel': ['예시 배송사 A(가상)', '예시 배송사 B(가상)', '예시 운송사 C(가상)'],
    'logistics.freightType': ['포장재', '식자재', '건자재', '전자부품', '생활용품'],
    'logistics.routeSummary': ['가상시 솔빛권역 → 가람권역', '가상시 물푸레권역 → 솔내권역'],
    'logistics.fareItem': [
      '기본 운임(예시)',
      '리프트 추가(예시)',
      '수작업 추가(예시)',
      '대기 시간(예시)',
    ],
    // Same order as the items in CoLogisticsDomain: BOX-S-200, TAPE-OPP-48,
    // TOWEL-COT-03, RICE-BRN-02.
    'logistics.itemName': ['종이 박스 소', '포장 테이프 48mm', '면 수건 3입', '현미 2kg'],
    'logistics.ownerLabel': ['화주사 A(가상)', '화주사 B(가상)', '화주사 C(가상)'],

    // hospitality
    'hospitality.propertyName': ['솔숲 머묾터(가상)', '가람 쉼터호텔(가상)', '물푸레 작은숙소(가상)'],
    'hospitality.siteName': ['솔바람 A동(가상)', '솔향 B동(가상)', '솔방울 C동(가상)'],
    'hospitality.amenity': ['개별 바비큐 공간', '공용 샤워실', '무선 인터넷'],
    'hospitality.stayOption': ['바비큐 그릴 세트(예시)', '장작 묶음(예시)', '조기 체크인(예시)'],
    'hospitality.seasonName': ['기본 기간', '명절 성수기(예시)', '주중 특가 기간(예시)'],
    'hospitality.ratePlan': ['기본 예시 요금', '조식 포함 예시 요금', '주중 예시 요금'],
    'hospitality.houseRule': [
      '밤에는 공용 공간에서 조용히 이용해 주세요.',
      '퇴실할 때 예시 체크리스트를 확인해 주세요.',
    ],
    'hospitality.bbqRule': [
      '바비큐 그릴은 17:00부터 21:00까지 이용할 수 있습니다.',
      '체크인 때 그릴 이용을 예약해 주세요.',
      '사이트마다 숯과 석쇠를 드립니다.',
      '자리를 뜨기 전에 불을 완전히 꺼 주세요.',
      '객실 데크에서는 바비큐를 할 수 없습니다.',
    ],
    'hospitality.wifiHint': [
      '와이파이 이름과 비밀번호는 출입문 옆 안내 카드에 있습니다.',
      '손님용 와이파이 비밀번호는 프런트에 문의해 주세요.',
      '손님용 와이파이는 객실과 라운지에서 됩니다.',
      '22:00 이후 신호가 끊기면 다시 연결해 주세요.',
      '비밀번호는 매주 월요일에 바뀝니다.',
    ],
    'hospitality.reviewSnippet': [
      '예시 객실 안내를 편하게 확인했어요.',
      '가상 숙소의 이용 안내가 정리되어 있어요.',
    ],
    'hospitality.hkCheckItem': ['침구 교체', '욕실 정리', '어메니티 확인', '미니바 확인'],
    'hospitality.maintenanceIssue': [
      '욕실 누수 확인(예시)',
      '전등 점검 요청(예시)',
      '냉난방 표시 확인(예시)',
      '가구 파손 확인(예시)',
    ],
    'hospitality.lostItemName': ['파란 우산', '회색 목도리', '책 한 권', '물병'],
    'hospitality.specialRequest': [
      '고층 · 금연(예시)',
      '추가 베개 요청(예시)',
      '조용한 객실 요청(예시)',
    ],
    'hospitality.menuItem': ['미역국 정식', '채소 파스타', '과일 요거트', '따뜻한 차'],
    'hospitality.menuOption': ['밥 적게', '밥 보통', '반찬 추가(예시)', '얼음 없음'],
    'hospitality.amenityName': ['수건', '생수', '칫솔', '베개'],
    'hospitality.localSpot': ['아침 국밥집(가상)', '골목 카페(가상)', '솔빛 산책길(가상)'],
    'hospitality.conciergeReply': [
      '가상 숙소의 이용 안내는 투숙 상세에서 확인할 수 있습니다.',
      '요청 내용을 예시 대장에 기록했습니다.',
      '주변 장소는 모두 데모용 가상 장소입니다.',
    ],
    'hospitality.folioItem': ['객실료(예시)', '룸서비스(예시)', '추가 옵션(예시)'],
  },
  // The texts that Korean writes as English does: units, acronyms, the name of
  // a programming language, and the Korean plate pattern that the English
  // bundle keeps. The language coverage gate reads this list.
  allowSameAsEnglish: <String, List<String>>{
    // The weight and the volume of a grocery item are written alike.
    'catalog.groceryUnit': ['*'],
    // These unit labels have read in English since 0.10.0, and the output of
    // Korean is kept byte for byte.
    'catalog.commerceUnit': ['*'],
    // Acronyms and file formats of the exam questions.
    'exam_prep.correctChoice': ['WHERE', 'TCP', 'HTTP'],
    'exam_prep.wrongChoice1': ['JPEG', 'PNG'],
    'exam_prep.wrongChoice2': ['CSS', 'MP3'],
    'exam_prep.wrongChoice3': ['SVG', 'TTF'],
    // The name of a programming language.
    'brokerage.skillTag': ['Dart'],
    // The two approved fictional creators: English writes their Korean names.
    'fandom.creatorName': ['*'],
    // English keeps the Korean plate pattern, and Korean is where it belongs.
    'logistics.vehiclePlate': ['*'],
    // Units, acronyms, and names of the Korean clinic and SaaS data.
    'clinic.procedures.unit': ['cc'],
    'clinic.drugForms.unit': ['mg', 'g'],
    'clinic.questions.options': ['SNS'],
    'clinic.cardIssuers': ['BC'],
    'clinic.texts.labels': ['HIFU', 'IPL'],
    'clinic.ops.patientTags.label': ['VIP'],
    'saas.labels': ['SMS', 'LMS', 'DUR'],
    // The detail of a failed claim master check has always read `5 rows`.
    'saas.ops.masterCheckDetail': ['{n} rows'],
  },
);
