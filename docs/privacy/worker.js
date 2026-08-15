export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // 1. AltStore/apps.json redirect, moved from the site root to /altstore.json
    if (path === '/altstore.json') {
      const user = "aroxu";
      const repo = "truedock";

      const githubUrl = `https://api.github.com/repos/${user}/${repo}/releases/latest`;
      const response = await fetch(githubUrl, {
        headers: {
          "User-Agent": "Cloudflare-Worker"
        }
      });

      if (!response.ok) {
        return new Response("Latest release not found", { status: 404 });
      }

      const data = await response.json();
      const appJsonAsset = data.assets.find(asset => asset.name === "apps.json");

      if (appJsonAsset) {
        return Response.redirect(appJsonAsset.browser_download_url, 302);
      } else {
        return new Response("apps.json not found in the latest release", { status: 404 });
      }
    }

    // 2. Single-page privacy policy. Language is chosen client-side inside the
    // page itself (a pure-CSS radio toggle, no JavaScript required), so one
    // URL serves both languages. Korean is the default.
    if (path === '/privacy-policy' || path === '/privacy-policy.html') {
      return new Response(policyHtml, {
        headers: { "Content-Type": "text/html; charset=utf-8" }
      });
    }

    // Backward-compatible redirects for the old two-URL scheme.
    if (path === '/privacy-policy-en' || path === '/privacy-policy-ko') {
      return Response.redirect(url.origin + '/privacy-policy', 301);
    }

    if (path === '/') {
      return Response.redirect(url.origin + '/privacy-policy', 302);
    }

    return new Response("Not Found", { status: 404 });
  }
};

// ==========================================
// Privacy policy HTML (embedded so the Worker
// has no external dependency at request time).
// ==========================================

const policyHtml = `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>개인정보처리방침 | Privacy Policy | TrueDock</title>
<meta name="description" content="TrueDock 개인정보처리방침. Privacy Policy for the TrueDock mobile administration app for TrueNAS SCALE Community Edition.">
<style>
  :root {
    color-scheme: light dark;
    --seed: #2e999c;
    --on-seed: #ffffff;
    --bg: #fbfdfd;
    --surface: #ffffff;
    --surface-alt: #f0f5f5;
    --outline: #d3dedd;
    --text: #171d1d;
    --muted: #3f4948;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --seed: #80d4d6;
      --on-seed: #003738;
      --bg: #0e1414;
      --surface: #161d1d;
      --surface-alt: #1d2626;
      --outline: #2f3a39;
      --text: #dee4e3;
      --muted: #bec9c8;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 40px 20px 96px;
    background: var(--bg);
    color: var(--text);
    font: 16px/1.7 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
      "Helvetica Neue", Arial, "Apple SD Gothic Neo", "Noto Sans KR", sans-serif;
    word-break: keep-all;
  }
  main { max-width: 760px; margin: 0 auto; }

  /* Language toggle: pure CSS, no JavaScript. Two hidden radio inputs drive
     which <section lang="..."> is visible via the :checked + general
     sibling combinator, so the switch works even with scripting disabled. */
  input.lang-radio { position: absolute; opacity: 0; pointer-events: none; }

  .lang {
    display: inline-flex;
    gap: 2px;
    padding: 3px;
    margin: 0 0 24px;
    background: var(--surface-alt);
    border: 1px solid var(--outline);
    border-radius: 999px;
    font-size: 0.875rem;
  }
  .lang label {
    display: block;
    padding: 6px 16px;
    border-radius: 999px;
    color: var(--muted);
    cursor: pointer;
    user-select: none;
    line-height: 1.3;
  }
  .lang label:hover { color: var(--text); background: var(--surface); }

  section.doc { display: none; }
  #lang-en:checked ~ main section.doc[lang="en"],
  #lang-ko:checked ~ main section.doc[lang="ko"] { display: block; }
  #lang-en:checked ~ main .lang label[for="lang-en"],
  #lang-ko:checked ~ main .lang label[for="lang-ko"] {
    background: var(--seed);
    color: var(--on-seed);
    font-weight: 600;
  }
  /* No scripting / no :has support still needs a sane default: show Korean
     and let the label click still work because the radio is still focusable
     and clickable even while visually hidden. */
  section.doc[lang="ko"] { display: block; }
  #lang-en:checked ~ main section.doc[lang="ko"] { display: none; }

  h1 { font-size: 2rem; line-height: 1.25; margin: 0 0 8px; letter-spacing: -0.02em; }
  h2 {
    font-size: 1.25rem;
    margin: 44px 0 12px;
    padding-top: 20px;
    border-top: 1px solid var(--outline);
    letter-spacing: -0.01em;
  }
  h3 { font-size: 1rem; margin: 24px 0 8px; }
  p, li { color: var(--muted); }
  ul { padding-left: 22px; }
  li { margin: 6px 0; }
  a { color: var(--seed); text-underline-offset: 3px; }
  .meta { color: var(--muted); font-size: 0.9rem; margin: 0 0 28px; }
  .lede {
    background: var(--surface);
    border: 1px solid var(--outline);
    border-radius: 16px;
    padding: 20px 22px;
    margin: 0 0 8px;
  }
  .lede p { margin: 0; color: var(--text); }
  table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 0.95rem; }
  th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid var(--outline); vertical-align: top; }
  th { color: var(--text); font-weight: 600; background: var(--surface-alt); }
  td { color: var(--muted); }
  code {
    background: var(--surface-alt);
    border-radius: 6px;
    padding: 1px 6px;
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    font-size: 0.9em;
    color: var(--text);
  }
  footer {
    margin-top: 56px;
    padding-top: 20px;
    border-top: 1px solid var(--outline);
    font-size: 0.9rem;
    color: var(--muted);
  }
</style>
</head>
<body>
<input type="radio" name="lang" id="lang-ko" class="lang-radio" checked>
<input type="radio" name="lang" id="lang-en" class="lang-radio">
<main>

<nav class="lang" aria-label="Language / 언어">
  <label for="lang-ko">한국어</label>
  <label for="lang-en">English</label>
</nav>

<section class="doc" lang="ko">
<h1>TrueDock 개인정보처리방침</h1>
<p class="meta">애플리케이션: TrueDock (<code>me.aroxu.truedock</code>) &middot; 개발자: aroxu &middot; 시행일: 2026년 8월 16일</p>

<div class="lede">
<p>TrueDock은 이용자가 직접 소유하고 운영하는 TrueNAS SCALE Community Edition 서버를 관리하기 위한 모바일 앱입니다. TrueDock에는 별도의 계정 및 광고 기능이 없고, 신원을 특정할 수 있는 추적 기능이 없습니다. 서버 주소와 인증정보는 이용자의 기기에 보관되며 이용자가 직접 설정한 TrueNAS 서버로만 전송됩니다. 개발자에게 전송될 수 있는 정보는 익명 오류 및 성능 진단 정보뿐이며, 이 기능은 언제든지 끌 수 있습니다.</p>
</div>

<h2>1. 적용 범위</h2>
<p>이 방침은 aroxu가 배포하는 Android 및 iOS용 TrueDock 애플리케이션에 적용됩니다. 이용자가 연결하는 TrueNAS 서버에는 적용되지 않습니다. 해당 서버는 이용자가 직접 운영하며, 서버에 저장된 데이터는 이용자의 설정과 정책을 따릅니다.</p>

<h2>2. 서버 연결을 위해 이용자가 입력하는 정보</h2>
<p>TrueDock을 사용하려면 하나 이상의 TrueNAS 서버를 등록해야 합니다. 이 과정에서 앱은 다음 정보를 처리합니다.</p>
<ul>
  <li>이용자가 입력한 서버 주소와 서버 프로필의 표시 이름</li>
  <li>TrueNAS 사용자 이름과 비밀번호 또는 TrueNAS API 키</li>
  <li>서버가 2단계 인증을 요구하는 경우의 일회용 인증 코드</li>
  <li>이용자가 신뢰하기로 선택한 서버 TLS 인증서의 SHA-256 지문</li>
</ul>
<p>이 정보는 이용자가 지정한 서버와 인증된 연결을 맺고 유지하는 목적으로만 사용됩니다. 해당 정보는 이용자의 기기에서 그 서버로 암호화된 <code>wss://</code> 연결을 통해 직접 전송됩니다. 개발자에게 전송되지 않으며, 진단 정보에도 포함되지 않습니다.</p>

<h3>인증정보 저장 방식</h3>
<p>인증정보 저장은 선택 사항이며 이용자가 &lsquo;로그인 상태 유지&rsquo;를 선택한 경우에만 이루어집니다. 이 경우:</p>
<ul>
  <li>인증정보는 TrueDock PIN에서 Argon2id로 파생한 키로 암호화되며 인증된 암호화 방식으로 보호됩니다.</li>
  <li>암호화된 데이터는 iOS Keychain 또는 Android Keystore 기반 보안 저장소에 오직 이용자 기기에만 저장됩니다.</li>
  <li>TrueDock PIN 자체는 저장, 동기화되지 않으며 복구할 수 없습니다.</li>
  <li>선택 기능인 생체 인증 잠금 해제는 운영체제의 생체 인증 창을 사용합니다. TrueDock은 성공 또는 실패 결과만 전달받으며 지문이나 얼굴 정보를 받거나 저장하지 않습니다.</li>
</ul>
<p>로그인 상태 유지를 선택하지 않으면 인증정보는 해당 세션 동안 메모리에만 유지됩니다.</p>

<h2>3. 기기에 저장되는 정보</h2>
<p>TrueDock은 앱을 다시 실행해도 정상 동작하도록 다음 정보를 기기에 저장합니다. 이 정보는 개발자에게 전송되지 않습니다.</p>
<table>
  <tr><th>저장 항목</th><th>저장 위치</th><th>목적</th></tr>
  <tr><td>서버 프로필: 표시 이름, 주소, 사용자 이름, 인증 방식</td><td>플랫폼 보안 저장소</td><td>등록된 서버 목록 표시 및 재연결</td></tr>
  <tr><td>신뢰한 인증서 지문</td><td>플랫폼 보안 저장소</td><td>서버 인증서 변경 감지</td></tr>
  <tr><td>이용자가 저장을 선택한 암호화된 인증정보</td><td>Keychain / Keystore</td><td>재입력 없이 다시 로그인</td></tr>
  <tr><td>화면 스타일, 테마, 모션 감소 설정</td><td>일반 앱 환경설정</td><td>인터페이스 설정 유지</td></tr>
  <tr><td>진단 정보 수집 사용 여부</td><td>일반 앱 환경설정</td><td>이용자의 선택 유지</td></tr>
</table>
<p>이 정보는 <strong>앱 설정 &rsaquo; 모든 TrueDock 데이터 초기화</strong>에서 언제든지 삭제할 수 있으며, 앱을 삭제해도 제거됩니다. 초기화하면 모든 로컬 서버 프로필, 저장된 인증정보, 신뢰한 인증서 지문, PIN 관련 데이터, 앱 설정이 삭제됩니다. 이 기기의 다른 앱이나 데이터, TrueNAS 서버의 데이터는 변경되지 않습니다.</p>

<h2>4. 익명 진단 정보</h2>
<p>공식 TrueDock 빌드는 결함을 발견하고 수정하기 위해 익명의 비정상 종료, 오류, 표본 추출된 성능 진단 정보를 전송할 수 있습니다. 이 수집 기능은 공식 빌드에서 기본으로 켜져 있고, 앱을 처음 실행할 때 안내되며, <strong>앱 설정 &rsaquo; 개인정보 보호</strong>에서 즉시 또는 나중에 끌 수 있습니다. 기능을 끄면 진단 클라이언트가 즉시 종료되며, TrueDock의 모든 기능은 그대로 사용할 수 있습니다.</p>
<p>진단 전송 대상이 설정되지 않은 빌드, 즉 이용자가 직접 소스에서 빌드한 경우에는 아무것도 전송되지 않습니다.</p>

<h3>진단 정보에 포함되는 항목</h3>
<ul>
  <li>비정상 종료 유형과 스택 위치</li>
  <li>오류 메시지 본문이 고정된 대체 문구로 치환된 Flutter 및 네이티브 오류 발생 위치</li>
  <li>앱 버전, 운영체제 버전, 기기 모델 종류, 시뮬레이터 실행 여부</li>
  <li>표본 추출된 앱 시작, 화면 로드, 느린 프레임, 멈춘 프레임, 프레임 처리 시간 측정값</li>
</ul>
<p>성능 추적은 10% 비율로 표본 추출됩니다. 사용자 상호작용 추적, 로그, 자동 세션 추적, 브레드크럼, 스크린샷, 화면 구조 수집, 사용자 피드백, 첨부 파일, 세션 리플레이는 모두 비활성화되어 있습니다.</p>

<h3>진단 정보에 절대 포함되지 않는 항목</h3>
<ul>
  <li>TrueNAS 주소, 호스트 이름, 서버 이름, 인증서, 계정 이름</li>
  <li>데이터셋, 풀, 디스크, 공유, 애플리케이션, 작업 등 모든 리소스 이름</li>
  <li>API 메서드, 파라미터, 요청 본문, 응답, 헤더</li>
  <li>비밀번호, PIN, API 키, 세션, 일회용 코드 등 모든 인증정보</li>
  <li>스크린샷, 화면 구조, 자유 형식 로그, 개인 식별자, 고정 기기 식별자</li>
</ul>
<p>이벤트가 기기를 떠나기 전에 TrueDock은 사용자, 요청, 서버, 브레드크럼, 태그, 부가 데이터, 응답, 피드백, 기능 플래그 항목을 제거하고, 기기 이름과 고유 기기 식별자를 삭제하며, 오류 및 예외 메시지를 고정된 대체 문구로 바꿉니다. 진단 데이터는 다음 실행 시 네이티브 비정상 종료 보고서를 전달하기 위한 최소한의 임시 저장 외에는 기기에 보관되지 않습니다.</p>

<h3>진단 정보의 전송 대상</h3>
<p>진단 정보는 개발자가 직접 운영하는 자체 호스팅 Sentry 서버로 암호화된 연결을 통해 전송됩니다. Sentry사의 상용 서비스로 전송되지 않으며 제3자에게 제공되지 않습니다.</p>
<p>이 서버는 Cloudflare 프록시 및 보안 네트워크를 거쳐 연결되며, Cloudflare는 연결을 전달하고 보호하기 위해 IP 주소와 라우팅 정보 같은 네트워크 메타데이터를 처리합니다. Cloudflare는 개발자를 대신해 데이터를 처리하는 인프라 제공자로서만 관여하며, 이 메타데이터를 이용자의 국가 밖에서 처리할 수 있습니다. 자세한 내용은 <a href="https://www.cloudflare.com/ko-kr/privacypolicy/" rel="noopener noreferrer">Cloudflare 개인정보처리방침</a>을 참고하세요.</p>
<p>진단 정보는 최대 30일간 보관된 후 자동으로 삭제됩니다.</p>

<h2>5. TrueDock이 하지 않는 일</h2>
<ul>
  <li>어떠한 데이터도 판매하거나 대여하지 않습니다.</li>
  <li>광고를 표시하지 않으며 광고 또는 마케팅 SDK를 포함하지 않습니다.</li>
  <li>앱, 웹사이트, 서비스 간 이용자 추적을 하지 않으며 광고 식별자를 사용하지 않습니다.</li>
  <li>TrueDock 계정을 생성하지 않으며 이용자의 NAS 데이터를 위한 별도 서버를 운영하지 않습니다.</li>
  <li>이용자의 TrueNAS 데이터를 개발자 인프라로 중계하거나 복제하지 않습니다.</li>
  <li>이용자의 파일, 연락처, 사진, 위치, 마이크, 카메라에 접근하지 않습니다.</li>
</ul>

<h2>6. 권한</h2>
<p>TrueDock은 기능에 필요한 권한만 요청합니다. 등록한 TrueNAS 서버에 연결하기 위한 네트워크 접근 권한, 그리고 이용자가 저장한 인증정보를 잠금 해제하기 위한 생체 인증 권한입니다. iOS에서는 같은 네트워크에 있는 NAS에 연결하기 위해 로컬 네트워크 접근 권한을 요청합니다.</p>

<h2>7. 보안</h2>
<p>TrueDock은 HTTPS 및 보안 WebSocket 연결만 사용하며 일반 HTTP 연결은 거부합니다. 시스템이 신뢰하지 않는 인증서는 이용자의 명시적 승인이 필요하고 해당 서버 프로필에만 고정되며, 이후 인증서가 변경되면 저장된 지문을 자동으로 대체하지 않고 다시 승인을 요구합니다. 앱 로그는 비밀번호, 패스프레이즈, 시크릿, 토큰, 키, 솔트, 일회용 코드, 세션 값이 남지 않도록 마스킹 처리됩니다.</p>
<p>완벽하게 안전한 전송이나 저장 방식은 존재하지 않지만, TrueDock은 개발자가 이용자의 인증정보나 NAS 데이터를 애초에 보유하지 않도록 설계되었습니다.</p>

<h2>8. 이용자의 선택과 권리</h2>
<ul>
  <li>앱 설정 &rsaquo; 개인정보 보호에서 익명 진단 정보 수집을 언제든지 끌 수 있습니다.</li>
  <li>서버 관리 화면에서 개별 서버 프로필과 저장된 인증정보를 삭제할 수 있습니다.</li>
  <li>앱 설정의 TrueDock 데이터 초기화 또는 앱 삭제로 TrueDock이 이 기기에 저장한 모든 데이터를 삭제할 수 있습니다.</li>
  <li>개발자에게 연락하여 진단 데이터의 삭제를 요청할 수 있습니다. 진단 정보는 익명이므로 해당 기록을 찾을 수 있도록 대략적인 날짜와 앱 버전을 함께 알려주세요.</li>
</ul>
<p>TrueDock에는 이용자 계정이 없으므로 삭제할 TrueDock 계정도 존재하지 않습니다. 거주 지역에 따라 개인정보에 대한 열람, 정정, 삭제, 처리 정지 등의 권리를 추가로 행사할 수 있습니다. 권리 행사를 원하시면 개발자에게 연락해 주세요.</p>

<h2>9. 방침의 변경</h2>
<p>TrueDock의 데이터 처리 방식이 변경되는 경우, 이 방침과 Google Play 데이터 보안 신고 내용을 같은 릴리스에서 함께 갱신합니다. 문서 상단의 시행일이 가장 최근 개정일을 나타냅니다.</p>

<h2>10. 문의</h2>
<p>TrueDock의 개인정보 처리에 관한 문의나 요청은 aroxu(<a href="mailto:aroxu@aroxu.me">aroxu@aroxu.me</a>)로 연락해 주세요.</p>

<footer>
<p>TrueDock은 GNU General Public License v3.0에 따라 배포되는 자유 소프트웨어입니다. 이 방침은 개발자가 배포하는 공식 빌드에 적용되며, 수정되었거나 직접 빌드한 버전은 이를 배포하는 주체가 책임집니다.</p>
</footer>
</section>

<section class="doc" lang="en">
<h1>TrueDock Privacy Policy</h1>
<p class="meta">Application: TrueDock (<code>me.aroxu.truedock</code>) &middot; Developer: aroxu &middot; Effective date: 16 August 2026</p>

<div class="lede">
<p>TrueDock is a mobile administration client for TrueNAS SCALE Community Edition servers that you own and operate. TrueDock has no user account, no advertising, and no tracking that can identify you. Your server addresses and credentials stay on your device and are sent only to the TrueNAS server you configured. The only data that can leave your device for the developer is anonymous crash and performance diagnostics, which you can turn off at any time.</p>
</div>

<h2>1. Who this policy covers</h2>
<p>This policy applies to the TrueDock mobile application for Android and iOS, published by aroxu. It does not apply to the TrueNAS servers you connect to. Those servers are operated by you, and the data stored on them is governed by your own configuration and policies.</p>

<h2>2. Data you provide to connect to a server</h2>
<p>To use TrueDock you register one or more TrueNAS servers. To do this the app processes:</p>
<ul>
  <li>the server address you enter, and a display name for the server profile;</li>
  <li>your TrueNAS username and password, or a TrueNAS API key;</li>
  <li>a one-time code when your server requires two-factor authentication;</li>
  <li>the SHA-256 fingerprint of the server TLS certificate you chose to trust.</li>
</ul>
<p>This information is used only to establish and maintain an authenticated connection to the server you specified. It is transmitted directly from your device to that server over an encrypted <code>wss://</code> connection. It is never transmitted to the developer, and it is never included in diagnostics.</p>

<h3>How credentials are stored</h3>
<p>Saving a credential is optional and only happens when you choose &ldquo;Keep me signed in&rdquo;. When you do:</p>
<ul>
  <li>credentials are encrypted with a key derived from your TrueDock PIN using Argon2id, and protected with authenticated encryption;</li>
  <li>the encrypted material is stored in the iOS Keychain or Android Keystore-backed secure storage, on your device only;</li>
  <li>the TrueDock PIN itself is never stored, synced, or recoverable;</li>
  <li>optional Biometric Unlock uses the operating system biometric prompt. TrueDock receives only a success or failure result and never receives or stores your fingerprint or face data.</li>
</ul>
<p>If you do not choose to stay signed in, the credential is held in memory for that session only.</p>

<h2>3. Data stored locally on your device</h2>
<p>TrueDock keeps the following on your device so the app can work across launches. None of it is uploaded to the developer.</p>
<table>
  <tr><th>Stored item</th><th>Where</th><th>Why</th></tr>
  <tr><td>Server profiles: display name, address, username, authentication method</td><td>Platform secure storage</td><td>To list and reopen your servers</td></tr>
  <tr><td>Trusted certificate fingerprints</td><td>Platform secure storage</td><td>To detect a changed server certificate</td></tr>
  <tr><td>Encrypted saved credentials, if you opted in</td><td>Keychain / Keystore</td><td>To sign in again without retyping</td></tr>
  <tr><td>Appearance, theme, and reduced-motion preferences</td><td>Ordinary app preferences</td><td>To keep your interface settings</td></tr>
  <tr><td>Diagnostics on/off preference</td><td>Ordinary app preferences</td><td>To honour your privacy choice</td></tr>
</table>
<p>You can erase all of it at any time from <strong>App Settings &rsaquo; Erase all TrueDock data</strong>, or by uninstalling the app. Resetting removes every local server profile, saved credential, trusted certificate fingerprint, PIN material, and app setting. It does not affect other apps or data on this device, and it does not change any data on your TrueNAS servers.</p>

<h2>4. Anonymous diagnostics</h2>
<p>Official TrueDock builds may send anonymous crash, error, and sampled performance diagnostics so that defects can be found and fixed. Collection is enabled by default in official builds, is disclosed the first time the app runs, and can be switched off immediately or later under <strong>App Settings &rsaquo; Privacy</strong>. Turning it off closes the diagnostics client immediately, and every feature of TrueDock continues to work.</p>
<p>Builds compiled without a diagnostics endpoint, including source builds you compile yourself, send nothing at all.</p>

<h3>What diagnostics contain</h3>
<ul>
  <li>crash type and stack location;</li>
  <li>Flutter and native error locations, with the error text itself replaced by fixed redacted placeholder text;</li>
  <li>application version, operating-system version, device model class, and whether the build runs on a simulator;</li>
  <li>sampled application-start, screen-load, slow-frame, frozen-frame, and frame timing measurements.</li>
</ul>
<p>Performance traces are sampled at 10%. User-interaction tracing, logs, automatic session tracking, breadcrumbs, screenshots, view-hierarchy capture, user feedback, attachments, and Session Replay are all disabled.</p>

<h3>What diagnostics never contain</h3>
<ul>
  <li>TrueNAS addresses, host names, server names, certificates, or account names;</li>
  <li>dataset, pool, disk, share, application, task, or any other resource names;</li>
  <li>API methods, parameters, request bodies, responses, or headers;</li>
  <li>passwords, PINs, API keys, sessions, one-time codes, or any other credential;</li>
  <li>screenshots, screen structure, free-form logs, personal identifiers, or stable device identifiers.</li>
</ul>
<p>Before an event leaves the device, TrueDock strips the user, request, server, breadcrumb, tag, extra-data, response, feedback, and feature-flag fields, clears device names and unique device identifiers, and replaces error and exception messages with fixed redacted text. Diagnostic data is not retained on the device beyond the small buffer needed to deliver a native crash report after the next launch.</p>

<h3>Where diagnostics are sent</h3>
<p>Diagnostics are sent over an encrypted connection to a self-hosted Sentry instance operated by the developer. They are not sent to Sentry&rsquo;s commercial service and are not shared with any third party.</p>
<p>That instance is reached through the Cloudflare proxy and security network, which processes network metadata such as IP addresses and routing information in order to deliver and protect the connection. Cloudflare acts only as an infrastructure provider processing data on the developer&rsquo;s behalf, and may process this metadata outside your country. See the <a href="https://www.cloudflare.com/privacypolicy/" rel="noopener noreferrer">Cloudflare Privacy Policy</a>.</p>
<p>Diagnostic events are retained for no longer than 30 days and are then deleted automatically.</p>

<h2>5. What TrueDock never does</h2>
<ul>
  <li>It does not sell or rent any data.</li>
  <li>It does not show advertising and contains no advertising or marketing SDK.</li>
  <li>It does not track you across apps, sites, or services, and uses no advertising identifier.</li>
  <li>It does not create a TrueDock account and operates no application backend for your NAS data.</li>
  <li>It does not route, relay, proxy, or copy your TrueNAS data through developer infrastructure.</li>
  <li>It does not read your files, contacts, photos, location, microphone, or camera.</li>
</ul>

<h2>6. Permissions</h2>
<p>TrueDock requests only what it needs to function: network access, to reach the TrueNAS servers you registered; and biometric authentication, to unlock a credential you chose to save. On iOS, local network access is requested so the app can reach a NAS on your own network.</p>

<h2>7. Security</h2>
<p>TrueDock connects only over HTTPS and secure WebSocket connections, and refuses plain HTTP. A certificate that is not trusted by the system requires your explicit approval, is pinned to that server profile alone, and a later certificate change requires a fresh decision instead of silently replacing the stored fingerprint. Application logs are redacted so that passwords, passphrases, secrets, tokens, keys, salts, one-time codes, and session values never appear.</p>
<p>No method of transmission or storage is perfectly secure, but TrueDock is designed so that the developer never holds your credentials or NAS data in the first place.</p>

<h2>8. Your choices and rights</h2>
<ul>
  <li>Turn anonymous diagnostics off at any time in App Settings &rsaquo; Privacy.</li>
  <li>Delete an individual server profile and its saved credential from server management.</li>
  <li>Erase all local TrueDock data from App Settings, or by uninstalling the app.</li>
  <li>Request deletion of diagnostic data associated with your reports by contacting the developer. Because diagnostics are anonymous, please include the approximate date and app version so the relevant records can be located.</li>
</ul>
<p>TrueDock has no user accounts, so there is no TrueDock account to delete. Depending on where you live, you may have additional rights over personal data, such as access, correction, deletion, or objection. Contact the developer to exercise them.</p>

<h2>9. Changes to this policy</h2>
<p>If the way TrueDock handles data changes, this policy and the Google Play Data safety declaration are updated in the same release. The effective date at the top of this page shows the most recent revision.</p>

<h2>10. Contact</h2>
<p>For privacy questions or requests about TrueDock, contact aroxu at <a href="mailto:aroxu@aroxu.me">aroxu@aroxu.me</a>.</p>

<footer>
<p>TrueDock is free software released under the GNU General Public License v3.0. This policy describes official builds published by the developer; modified or self-compiled builds are the responsibility of whoever distributes them.</p>
</footer>
</section>

</main>
</body>
</html>
`;
