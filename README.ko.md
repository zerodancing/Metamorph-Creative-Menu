<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Noita용 크리에이티브 도구 모음: 주문, 완드, 아이템, 재료, 퍽, 생물, 효과, 순간이동, 날씨, 세계 규칙.
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [**한국어**](README.ko.md)

## 다운로드

현재 버전: **2.0.0**

| 패키지 | 다운로드 |
|---|---|
| **최신 설치용 빌드** | **[⬇️ Metamorph-Creative-Menu.zip 다운로드](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| 빌드 페이지 | [최신 설치용 빌드](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> ZIP에는 NoitaPatcher를 포함한 전체 `metamorph_creative_menu` 폴더가 이미 들어 있습니다. 해당 폴더를 `Noita/mods/`에 바로 압축 해제하세요.

올바른 최종 경로:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

`metamorph_creative_menu/metamorph_creative_menu/mod.xml` 경로가 만들어졌다면 압축을 한 단계 더 깊게 푼 것입니다.

---

## 한국어

### 설치

1. [최신 설치용 ZIP을 다운로드](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)합니다.
2. 모드를 설치하거나 업데이트하기 전에 Noita를 완전히 종료합니다.
3. Steam에서 **라이브러리 → Noita 우클릭 → 관리 → 로컬 파일 찾아보기**를 엽니다.
4. 게임의 `mods` 폴더를 열고 **`metamorph_creative_menu`** 폴더 전체를 복사합니다.
5. `Noita/mods/metamorph_creative_menu/mod.xml`이 존재하는지 확인합니다. 모드 폴더 이름을 바꾸지 마세요.
6. Noita를 실행하고 **Metamorph: Creative Menu**를 활성화한 뒤, 필요한 경우 **Unsafe mods / unrestricted API**를 허용하고 모드 활성화 후 Noita를 다시 시작합니다.
7. 게임을 시작하고 **TAB**을 누릅니다. 메뉴가 열리면 설치가 완료된 것입니다.

**업데이트:** Noita를 종료하고 기존 `metamorph_creative_menu` 폴더를 삭제한 다음 새 폴더를 `mods`에 복사하세요. 폴더 전체를 교체하면 이전 버전의 오래된 파일이 남는 것을 방지할 수 있습니다.

### 조작

- **F4 또는 TAB**: Creative Menu 열기 또는 닫기.
- **변신 중 TAB**: 인간 형태로 돌아가기.
- **G**(기본값): 커서 아래의 지원되는 생물에 빙의하기.
- **마우스 가운데 버튼**: 선택한 재료로 그리기.
- 키 지정은 조작 페이지 또는 모드 설정에서 변경할 수 있습니다. 왼쪽/오른쪽 클릭으로 가능한 동작은 인터페이스에 표시됩니다.

### MCM에서 할 수 있는 일

- 주문을 가져오고 배치하며 완드, 항상 시전 슬롯, 인벤토리, 월드 사이에서 옮길 수 있습니다.
- 완드 능력치, 외형, 잠금을 편집하고 완드 프리셋을 저장하거나 복사본을 만들 수 있습니다.
- 플레이어 근처 또는 지정한 월드 위치에 아이템을 생성하고 지원되는 아이템을 인벤토리에 직접 넣을 수 있습니다.
- 선택한 액체가 들어 있는 플라스크를 만들 수 있습니다.
- 재료를 선택해 월드에 그릴 수 있습니다.
- 퍽을 생성하고 획득하거나 제거할 수 있습니다.
- 플레이어 근처 또는 지정한 월드 위치에 생물을 생성할 수 있습니다.
- 생물로 변신하고 월드의 기존 생물에 빙의하며 인간 형태로 돌아갈 수 있습니다.
- 별도의 PLAYER 엔티티를 생성할 수 있습니다.
- 게임 효과를 적용하고 제거할 수 있습니다.
- 날씨, 시간대, 중력, 기타 세계 규칙을 변경할 수 있습니다.
- 게임 내 위치로 순간이동할 수 있습니다.
- Entangled Worlds 사용 시 다른 플레이어에게 순간이동하거나 다른 플레이어를 자신의 위치로 데려올 수 있습니다.
- 키 지정을 변경하고 주문, 아이템, 재료, 퍽, 생물 카탈로그를 검색할 수 있습니다.
- 메뉴 창을 이동하고 크기를 조절할 수 있으며 위치와 크기는 게임을 다시 실행해도 유지됩니다.

<details>
<summary><strong>변신, 호환성, 복구</strong></summary>

MCM은 정확한 XML 경로를 기준으로 호환성 정보를 관리하며, 직접적인 기본 변신 방식이 위험하거나 적합하지 않은 것으로 알려진 엔티티에만 제한적인 안전 경로 예외를 사용합니다. 플레이어가 조종하는 형태는 유용한 기본 이동, 공격, 시각 표현, 물리 동작을 가능한 한 유지하면서 플레이어 입력과 충돌하는 인공지능을 비활성화합니다. 복잡한 보스, 강하게 스크립트로 제어되는 엔티티, 물리 오브젝트는 전용 어댑터가 필요할 수 있으며 원래 인공지능의 모든 행동을 완전히 재현하지 못할 수 있습니다.

NoitaPatcher는 엔티티 직렬화/역직렬화, 플레이어 엔티티 제어권 인계, 기타 고급 실행 기능처럼 강력한 복구 처리에 사용됩니다. 이 때문에 전체 독립 버전은 제한 없는 모드 접근 권한을 요청합니다.

</details>

<details>
<summary><strong>Entangled Worlds 멀티플레이 통합</strong></summary>

**Entangled Worlds는 선택 사항입니다.** MCM은 EW 없이도 완전한 싱글플레이 모드로 동작하도록 설계되어 있습니다.

`quant.ew`가 활성화되면 공유 아이템, 퍽, 날씨, 세계 규칙, 형태와 빙의, 동료 요청, 그리고 관련 제어권 및 동기화 동작에 대한 실험적 멀티플레이 통합이 활성화됩니다. 모든 참가자는 같은 MCM 버전을 사용해야 합니다. Noita와 EW의 모든 특수 상황에서 완벽한 동기화를 보장할 수는 없으므로 멀티플레이 지원은 의도적으로 실험적 기능으로 취급됩니다.

</details>

### 요구 사항 및 외부 구성 요소

- **Noita** — Nolla Games의 필수 게임.
- **NoitaPatcher**(dextercd) — MCM에 포함되어 있으며 고급 실행 기능과 복구에 사용됩니다.
- **lbase64**(Ilya Kolbin) — 함께 제공되는 로컬 Base64 구현.
- **Entangled Worlds / Noita Proxy**(IntQuant 및 기여자) — 선택적 멀티플레이 통합이며 싱글플레이에는 필요하지 않습니다.

원본 프로젝트의 정확한 링크, 포함된 구성 요소 경로, 라이선스 및 상태 정보는 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참고하세요.

### 문제 해결

- **TAB을 눌러도 아무 반응이 없음:** `mod.xml`의 정확한 경로와 MCM 활성화 여부를 확인하고 Unsafe mods/unrestricted API를 허용한 뒤 Noita를 다시 시작하세요.
- **고급 복구 또는 일부 세계 규칙 기능이 없음:** `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll`이 존재하고 unrestricted API 권한이 허용되어 있는지 확인하세요.
- **형태에서 정상적으로 돌아오지 못함:** 정확한 생물 이름 또는 XML을 알려 주고 일반 TAB 복귀가 실패했는지, 치명적 피해 후 복구가 실패했는지 함께 알려 주세요.
- **EW 동기화 문제:** 모든 참가자가 같은 MCM 빌드와 호환되는 EW 빌드를 사용하는지 확인하세요.

### 링크

- [최신 빌드](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [문제 신고](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [외부 구성 요소 안내](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [NoitaPatcher 문서](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ 언어 선택으로 돌아가기](#languages)

---

## 개발자 정보

실행 가능한 모드는 `metamorph_creative_menu/`에 있습니다.

- 아키텍처 및 개발자 메모: `metamorph_creative_menu/README.txt`
- 회귀 테스트 모음: `metamorph_creative_menu/tests/`
- 테스트 안내: `metamorph_creative_menu/tests/TESTING.txt`
- 외부 구성 요소 안내: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

저장소의 자동 `latest-build` 워크플로는 실행 가능한 `metamorph_creative_menu` 폴더를 설치용 ZIP으로 묶고 위의 고정 다운로드 주소를 업데이트합니다.