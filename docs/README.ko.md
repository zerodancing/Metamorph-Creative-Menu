# Metamorph: Creative Menu — 한국어

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## 소개

**Metamorph: Creative Menu (MCM)** 는 **Noita**용 크리에이티브/개발자 메뉴입니다. 싱글플레이에서는 독립적으로 동작하며, 선택적으로 **Entangled Worlds / Noita Proxy**와의 실험적 호환 기능을 제공합니다.

완드 편집, 아이템 생성/획득, 퍽과 효과 적용/제거, 생물 변신, 커서 아래의 기존 생물 점유, 날씨와 월드 규칙 변경, 플레이어와 비슷한 동료 생성 등을 지원합니다.

## 요구 사항 및 설치

- Noita.
- `Noita/mods/` 안의 `metamorph_creative_menu` 폴더.
- Noita 모드 메뉴에서 **Unsafe mods / unrestricted API**를 켜야 합니다. 포함된 네이티브 **NoitaPatcher**가 이 권한을 사용합니다.
- Entangled Worlds는 **선택 사항**입니다.

1. [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)에서 빌드를 받거나 저장소를 다운로드/clone합니다.
2. `metamorph_creative_menu` 전체를 `Noita/mods/`에 복사합니다.
3. `Noita/mods/metamorph_creative_menu/mod.xml`이 있는지 확인합니다.
4. Unsafe mods를 켠 뒤 Metamorph: Creative Menu를 활성화합니다.

내부 모드 폴더 이름은 바꾸지 마세요.

## 조작

- **TAB** — 메뉴 열기/닫기.
- **변신 중 TAB** — 인간 형태로 복귀.
- 기본 **G** — 커서 아래의 호환 생물을 점유/변신. 설정에서 변경 가능.
- 각 탭의 좌/우 클릭 기능은 UI에 표시됩니다.

## 기능

### 주문/완드 편집
완드를 들고 슬롯을 선택한 뒤 검색/카테고리 목록에서 주문을 고릅니다. 교체, 삭제, 월드에 드롭할 수 있습니다. 교체 시 새 주문이 정상적으로 부착되었는지 확인한 뒤 기존 주문을 제거합니다.

### 아이템
용기, 액체, 돌, 알, 완드, 책, 보너스, 오브, 퀘스트 아이템 등.
- **좌클릭:** 근처 생성.
- **우클릭:** 적절한 인벤토리 슬롯에 직접 넣기 시도.
- 공간 부족/픽업 실패 시 아이템을 월드에 남깁니다.
- 액체가 채워진 플라스크/용기도 지원합니다.

### 퍽
- **ADD:** 좌클릭은 일반 pickup 생성, 우클릭은 직접 적용.
- **REMOVE:** 좌클릭은 1스택 제거, 우클릭은 전체 제거 시도.
MCM은 퍽이 만든 여러 변경을 추적해 다른 시스템의 상태를 의도적으로 덮어쓰지 않으면서 엔티티/컴포넌트/값을 되돌리려 합니다. 안전한 역연산이 없으면 위험한 제거를 거부할 수 있습니다.

### 검색
큰 카탈로그는 번역된 이름, ID 및/또는 설명으로 검색할 수 있습니다.

### 생물, 오브젝트, 형태
- **좌클릭:** 생성.
- **우클릭:** 변신.
- **TAB:** 인간.

호환성은 정확한 XML 경로 기준으로 관리됩니다. 일부 알려진 위험 placement wrapper는 변신할 때만 안전한 canonical target으로 라우팅됩니다. 플레이어 형태는 가능한 한 유용한 네이티브 공격, 이동, 외형, 물리를 유지하고 플레이어 조작과 충돌하는 AI를 끕니다. 복잡한 엔티티는 근사 adapter를 사용할 수 있습니다.

### 인간 복귀와 형태 사망
일반 TAB 복귀는 먼저 Noita의 네이티브 polymorph lifecycle을 사용합니다. 또한 MCM은 NoitaPatcher를 통해 인간의 직렬화 백업을 유지합니다.

치명적 피해 시 **death handoff**를 시도하여 현재 생물 몸은 죽게 두고 플레이어 권한은 복원된 인간에게 넘깁니다. 따라서 변신 몸의 죽음이 자동으로 run 전체 종료로 이어지지 않도록 합니다.

### 점유(Possession)
호환 생물을 가리키고 **G**를 누릅니다. MCM은 해당 대상의 호환 형태를 사용하고 원래 대상을 retire/제거하여 단순 복제 생성을 피합니다.

### PLAYER 동료
`PLAYER` 항목에서 플레이어와 비슷한 아군을 만들 수 있습니다. 필요한 NoitaPatcher 기능이 있으면 복사한 완드를 실제 플레이어에 더 가깝게 사용할 수 있습니다.

### 효과
상태/시간제 효과를 적용하고 지원되는 경우 지속시간을 고르며, 에디터 소유가 아닌 내부/퍽 상태를 가능한 한 보존하면서 제거합니다.

### 날씨
시간 프리셋: 아침, 낮, 저녁, 밤. 날씨: 맑음, 흐림, 안개, 폭풍. Advanced 모드는 시간, 구름, 안개, 바람, 풍속, 비, 번개 관련 지원 값을 조절합니다. **RELEASE**는 MCM이 override를 계속 유지하는 것을 중단합니다.

### 월드 규칙
규칙은 **되돌릴 수 있는 override**입니다. `NATIVE`/RESET은 MCM이 기록한 baseline을 복구하며, 중요한 규칙은 영구 recovery 데이터를 사용합니다.

현재 규칙:

- 생물 관계
- 금이 사라지지 않음
- 주문 사용 횟수 무제한
- 전장의 안개 해제
- 트릭 킬 피의 돈
- 회복 드롭 확률
- 우호적인 쥐
- 유혈량
- 트릭 킬 골드
- 피해 플래시
- 얼룩 제거
- 세계 중력
- 물리 감쇠
- 피의 양
- 발차기 힘
- 관절 강도
- 낮밤 주기 속도

물리 규칙은 로드되었거나 가까운 엔티티/물리 바디에 적용되며, 무한 월드의 모든 비로드 대상을 즉시 수정하지는 않습니다.

## 싱글플레이와 Entangled Worlds

**싱글플레이에는 EW가 필요하지 않습니다.** MCM은 자체 NoitaPatcher와 로컬 Base64 codec을 포함합니다.

`quant.ew` 활성 시 월드 아이템, 퍽, 날씨, 규칙, 형태/점유, 동료, 호환 patch의 실험적 통합이 켜집니다. EW가 이미 호환 NoitaPatcher API를 제공하면 MCM이 재사용할 수 있습니다.

멀티플레이 지원은 **실험적/부분적**입니다. host와 client가 같은 MCM 사용자 권한을 갖는 것이 목표지만 모든 Noita/EW edge case를 보장하지 않습니다. 모든 peer는 같은 MCM 버전을 사용하세요.

## 문제 해결 및 버그 제보

- 메뉴가 안 열림: 경로와 모드 활성화를 확인.
- 확장 기능이 없음: Unsafe mods 및 `NoitaPatcher/noitapatcher.dll` 확인.
- 특정 형태 문제: 정확한 이름/XML과 TAB 복귀/사망 복귀 중 무엇이 실패했는지 기록.
- EW 문제: MCM/EW 버전을 함께 기록.

[GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)에 재현 단계와 로그를 올려 주세요.

## 외부 구성 요소 및 크레딧

MCM은 **NoitaPatcher**(dextercd), **lbase64**(Ilya Kolbin)을 포함하며 선택적으로 **Noita Entangled Worlds**(IntQuant 및 기여자)와 연동합니다. 자세한 경로/용도/라이선스 상태는 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)를 참조하세요.

## 링크

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## 개발

플레이 가능한 모드는 `metamorph_creative_menu/`, 테스트/contract는 `metamorph_creative_menu/tests/`에 있습니다. MCM 자체 코드에 대한 저장소 전체 라이선스는 아직 선택되지 않았습니다.
