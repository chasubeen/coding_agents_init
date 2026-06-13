# 성능 체크리스트

성능을 측정 우선으로 점검하기 위한 참조 체크리스트. 웹(Core Web Vitals)·백엔드뿐 아니라 일반/ML 학습 성능까지 다룬다.

관련 스킬: performance-optimization, /cross-check

## 측정 우선 원칙

추측하지 말고 측정한다. 프로파일링으로 병목을 특정한 뒤에만 최적화한다. 측정 없는 최적화는 복잡성만 늘리고 실제 핫패스를 놓친다.

## 목차

- [Core Web Vitals 목표](#core-web-vitals-목표)
- [프론트엔드 체크리스트](#프론트엔드-체크리스트)
- [백엔드 체크리스트](#백엔드-체크리스트)
- [일반 / ML 학습 성능](#일반--ml-학습-성능)
- [측정 명령](#측정-명령)
- [흔한 안티패턴](#흔한-안티패턴)

## Core Web Vitals 목표

| 지표 | Good | 개선 필요 | Poor |
|------|------|-----------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |

## 프론트엔드 체크리스트

### 이미지
- [ ] 최신 포맷 사용 (WebP, AVIF)
- [ ] 반응형 크기 (`srcset`, `sizes`)
- [ ] `width`/`height` 명시 (CLS 방지)
- [ ] 폴드 아래 이미지는 `loading="lazy"`, `decoding="async"`
- [ ] Hero/LCP 이미지는 `fetchpriority="high"`, lazy 미사용

### JavaScript
- [ ] 초기 번들 200KB(gzip) 이하
- [ ] 라우트·무거운 기능에 동적 `import()` 코드 스플리팅
- [ ] 트리 셰이킹 활성화
- [ ] `<head>`에 블로킹 JS 없음 (`defer`/`async`)
- [ ] 50ms 초과 long task를 쪼개 메인 스레드를 비움 (INP 핵심 레버)
- [ ] 긴 루프에 `scheduler.yield()`/`yieldToMain`으로 입력 이벤트 양보
- [ ] 비핵심 작업(analytics, 로깅)을 이벤트 핸들러 밖으로 지연

### CSS / 폰트
- [ ] 크리티컬 CSS 인라인/프리로드, 비핵심 CSS 비블로킹
- [ ] 폰트 2~3 패밀리·2~3 weight로 제한, WOFF2만 사용
- [ ] LCP 핵심 폰트 프리로드, `font-display: swap`

### 네트워크 / 렌더링
- [ ] 정적 자산 long `max-age` + 콘텐츠 해싱 캐시
- [ ] HTTP/2 또는 HTTP/3 사용, 알려진 origin `preconnect`
- [ ] 레이아웃 스래싱 없음 (DOM 읽기 일괄 → 쓰기 일괄)
- [ ] 애니메이션은 `transform`/`opacity` (GPU 가속)
- [ ] 긴 리스트는 가상화 (예: `react-window`)

## 백엔드 체크리스트

### 데이터베이스
- [ ] N+1 쿼리 패턴 없음 (eager loading / join)
- [ ] 쿼리에 적절한 인덱스
- [ ] 리스트 엔드포인트 페이지네이션 (`SELECT *` 금지)
- [ ] 커넥션 풀링 설정
- [ ] 느린 쿼리 로깅 활성화

### API
- [ ] 응답 시간 < 200ms (p95)
- [ ] 요청 핸들러 내 동기 무거운 연산 없음
- [ ] 개별 호출 루프 대신 벌크 연산
- [ ] 응답 압축 (gzip/brotli)
- [ ] 적절한 캐싱 (인메모리, Redis, CDN)

### 인프라
- [ ] 정적 자산 CDN
- [ ] 사용자 근접 서버 (또는 엣지 배포)
- [ ] 필요 시 수평 확장
- [ ] 로드밸런서용 헬스체크 엔드포인트

## 일반 / ML 학습 성능

Python ML/DL 학습·추론에서 측정 우선으로 점검할 항목:

### 측정·프로파일링 먼저
- [ ] `cProfile`/`py-spy`로 CPU 핫스팟 특정
- [ ] `torch.profiler` 또는 `nvidia-smi`/`nvitop`으로 GPU 활용률·메모리 확인
- [ ] 학습 스텝을 데이터로딩 vs 연산으로 분해해 병목 위치 파악

### 데이터로더 병목
- [ ] `DataLoader`의 `num_workers`를 늘려 CPU 전처리를 병렬화
- [ ] `pin_memory=True`로 host→device 전송 가속
- [ ] `prefetch_factor`로 다음 배치를 미리 준비
- [ ] 무거운 전처리를 사전 계산·캐시 (매 epoch 재계산 금지)

### GPU 활용률
- [ ] GPU 활용률이 낮으면 데이터로딩 병목을 먼저 의심
- [ ] 배치 크기를 메모리가 허용하는 선에서 키워 처리량 향상
- [ ] 혼합정밀도(AMP, `torch.cuda.amp`)로 메모리·속도 개선
- [ ] 불필요한 `.item()`/`.cpu()` 동기화 호출로 GPU를 멈추지 않기

### 벡터화
- [ ] Python 루프를 NumPy/PyTorch 벡터 연산으로 대체
- [ ] 배치 차원에서 한 번에 연산 (샘플별 루프 금지)
- [ ] 핫패스에서 거대 텐서·배열을 반복 할당하지 않기 (사전 할당·재사용)

## 측정 명령

```bash
# Python CPU 프로파일링
python -m cProfile -o prof.out train.py
python -c "import pstats; pstats.Stats('prof.out').sort_stats('cumtime').print_stats(20)"

# 샘플링 프로파일러 (운영/장기 실행)
py-spy top -- python train.py

# GPU 활용률·메모리 모니터링
nvidia-smi dmon          # 또는: nvitop

# 웹 — Lighthouse / 번들 분석
npx lighthouse https://localhost:3000 --output json --output-path ./report.json
npx vite-bundle-visualizer
```

```python
# PyTorch 프로파일링
from torch.profiler import profile, ProfilerActivity

with profile(activities=[ProfilerActivity.CPU, ProfilerActivity.CUDA]) as prof:
    model(batch)
print(prof.key_averages().table(sort_by="cuda_time_total", row_limit=15))
```

## 흔한 안티패턴

| 안티패턴 | 영향 | 해결 |
|---|---|---|
| N+1 쿼리 | DB 부하 선형 증가 | join, include, 배치 로딩 |
| 무제한 쿼리 | 메모리 고갈, 타임아웃 | 항상 페이지네이션, LIMIT |
| 인덱스 누락 | 데이터 증가 시 느린 읽기 | 필터/정렬 컬럼에 인덱스 |
| 레이아웃 스래싱 | 끊김, 프레임 드롭 | DOM 읽기/쓰기 일괄화 |
| 큰 번들 | 느린 TTI | 코드 스플릿, 트리 셰이크 |
| 메인 스레드 블로킹 | 나쁜 INP | long task 쪼개기, Web Worker |
| **Python 루프 연산** | 느린 학습/추론 | NumPy/PyTorch로 벡터화 |
| **데이터로더 병목** | GPU 유휴 | `num_workers`↑, `pin_memory`, 프리페치 |
| **추측 기반 최적화** | 복잡성↑, 병목은 그대로 | 먼저 프로파일링 |

---

원본 참고: addyosmani/agent-skills (`references/performance-checklist.md`)
