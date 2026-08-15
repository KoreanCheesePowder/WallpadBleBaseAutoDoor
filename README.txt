C.P BLE Door Presence v1.1.5

변경사항
- 기존 buildbook37604.doorProximity capability 재사용 (새 capability 생성 안 함)
- 내부 offline 키는 SmartThings 화면에서 "못찾음"으로 표시
- 못찾음: 거리 0 dBm 고정
- 가까움/멀어짐: 실제 EMA/RSSI 표시
- LOST=0 뒤 실제 RSSI 수신 즉시 거리값 복구
- STATUS_BEGIN~STATUS_END를 일괄 처리하여 순간적인 0/멀어짐 오표시 방지
- 값이 변할 때만 SmartThings 이벤트를 발행하여 화면 갱신 지연/이벤트 폭주 감소
- STATUS polling 5초 (보조 동기화)
- 최대 4대 BLE Bond 지원

설치
1. SETUP-AND-INSTALL.cmd 실행
2. 기존 custom capability를 업데이트하고 동일 packageKey 드라이버를 패키징/설치합니다.
3. 새 custom capability는 생성하지 않습니다.

표시 규칙
- 가까움: 실제 거리값 + 가까움
- 멀어짐: 실제 거리값 + 멀어짐
- 못찾음: 0 dBm + 못찾음


v1.1.3 fixes:
- 거리값과 상태를 항상 동기화된 쌍으로 갱신
- 유효 RSSI가 있으면 못찾음 상태 금지
- STATUS 요청 중첩 방지
- 1초 UI 재동기화로 SmartThings 앱의 stale 상태 방지

v1.1.3 fixes:
- Fixes fatal Lua error when an unset Edge device field returns no values to tonumber().
- Uses field_number() for UI sync/status timeout timestamps, so missing fields safely fall back to 0.
- Keeps v1.1.2 paired distance/state update behavior and STATUS frame staging.


v1.1.5 fixes:
- ESP 실시간 PHONE*_RSSI / EMA / LOST / NEAR 이벤트를 즉시 UI에 반영
- STATUS polling을 0.5초에서 5초로 낮춰 STATUS_BEGIN 중첩과 TCP 부하 방지
- STATUS 응답 완료 전 재요청 금지 + 4초 timeout
- LOST=true 프레임에서 stale RSSI를 폐기하여 거리값/못찾음 모순 방지
- 유효 RSSI가 다시 들어오면 LOST=false로 즉시 복구
- 거리와 상태는 항상 같은 emit cycle에서 함께 갱신

v1.1.6 stabilization
- Full Edge Driver installation package based on v1.1.5.
- Keeps immediate LOST -> 0 dBm / 못찾음 behavior.
- Keeps immediate RSSI push -> live dBm / 가까움 or 멀어짐 behavior.
- Keeps 5-second STATUS as backup synchronization only.
- Driver Information version updated to v1.1.6.
- Intended to pair with ESP32-S3 BLE STABLE v3 firmware.
