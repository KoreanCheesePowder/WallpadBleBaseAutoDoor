C.P BLE Door Presence v1.3.1

ESP32-S3 BLE 제어 서비스와 TCP로 연동해 최대 4대 휴대폰의 RSSI, 근접 상태와 전체 재실 상태를 SmartThings에 제공하는 LAN Edge 드라이버입니다.

주요 기능
- 192.168.1.101:8900의 ESP BLE 제어 서비스 검색 및 자동 기기 생성
- 최대 4대 BLE Bond 등록
- 휴대폰별 RSSI/EMA, 가까움, 멀어짐, 못찾음, 미등록 상태 표시
- 전체 휴대폰 중 하나라도 가까우면 presenceSensor를 present로 표시
- PHONE1_RSSI~PHONE4_RSSI, EMA, LOST, NEAR 실시간 이벤트 즉시 반영
- STATUS_BEGIN~STATUS_END 응답을 한 프레임으로 처리해 중간 상태 오표시 방지
- 5초 간격 STATUS 보조 동기화, 4초 응답 제한, 2초 재연결
- LOST=true일 때 오래된 RSSI/EMA를 폐기하고 -127 dBm / 못찾음으로 표시
- 실제 RSSI가 다시 수신되면 LOST 상태를 즉시 해제
- 핸드폰 등록 시작, 등록 수와 패스키 표시
- 설정에서 선택한 슬롯을 momentary 버튼으로 삭제하고 ESP에 UNPAIR n 전송
- refresh로 상태 즉시 요청

표시 규칙
- 미등록: 0 dBm / 미등록
- 등록 후 신호 없음: -127 dBm / 못찾음
- 신호 수신: 실제 RSSI 또는 EMA / 가까움 또는 멀어짐

설치
1. SETUP-AND-INSTALL.cmd를 실행합니다.
2. 기존 custom capability를 업데이트하고 같은 packageKey로 드라이버를 패키징·설치합니다.
3. SmartThings 앱에서 기기 추가 -> 주변 검색을 실행합니다.
4. 중복 기기가 있으면 CLEANUP-DUPLICATE.cmd를 사용합니다.

휴대폰 삭제
SmartThings 기기 설정에서 삭제할 핸드폰 1~4를 선택한 뒤 상세 화면의 momentary 버튼을 누릅니다. 선택한 슬롯이 등록되어 있으면 ESP에 UNPAIR n을 전송하고 상태를 다시 조회합니다.

드라이버 정보
- 제작자: 치즈가루
- 버전: v1.3.1
- packageKey: cp-ble-door-presence-discovery
