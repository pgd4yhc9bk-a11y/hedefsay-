// Hedef — Supabase istemcisi (kütüphanesiz; yalnızca fetch).
// Anonim oturum açar, oyuncu kartını okur/yazar, günlük turu daily-round fonksiyonuyla oynar,
// sıralamaları okur. Puan ve süre sunucuda hesaplanır; istemci yalnızca cevabı gönderir.
(function (root) {
  "use strict";
  var cfg = root.HEDEF_AYAR || {};
  var OTURUM = "hedef-oturum";
  var bellek = null;

  function hazir() { return !!(cfg.url && cfg.anonKey); }

  function oku() { try { return JSON.parse(localStorage.getItem(OTURUM) || "null"); } catch (e) { return null; } }
  function yaz(o) { try { localStorage.setItem(OTURUM, JSON.stringify(o)); } catch (e) { /* depo yoksa bellekte kalır */ } }

  function istek(yol, ayar) {
    ayar = ayar || {};
    // Yeni tür herkese açık anahtarlar (sb_publishable_…) JWT değildir: yalnızca `apikey` başlığında gider.
    // Authorization yalnızca kullanıcı oturumu (JWT) varken eklenir.
    var h = { apikey: cfg.anonKey, "content-type": "application/json" };
    if (ayar.jwt) h.Authorization = "Bearer " + ayar.jwt;
    for (var k in (ayar.headers || {})) h[k] = ayar.headers[k];
    return fetch(cfg.url + yol, { method: ayar.method || "GET", headers: h, body: ayar.body === undefined ? undefined : JSON.stringify(ayar.body) })
      .then(function (r) {
        return r.text().then(function (t) {
          var j = null;
          try { j = t ? JSON.parse(t) : null; } catch (e) { /* gövde JSON değil */ }
          if (!r.ok) {
            var e = new Error((j && (j.error || j.message || j.msg)) || ("HTTP " + r.status));
            e.status = r.status;
            throw e;
          }
          return j;
        });
      });
  }

  function kaydet(n) {
    var o = {
      access_token: n.access_token, refresh_token: n.refresh_token,
      expires_at: n.expires_at || Math.floor(Date.now() / 1000) + (n.expires_in || 3600),
      user_id: n.user && n.user.id
    };
    bellek = o; yaz(o);
    return o;
  }

  // Geçerli oturumu verir; yoksa yeniler, o da olmazsa anonim yeni oturum açar.
  function oturum() {
    var o = bellek || oku();
    if (o && o.expires_at * 1000 > Date.now() + 30000) { bellek = o; return Promise.resolve(o); }
    var yeni = function () { return istek("/auth/v1/signup", { method: "POST", body: {} }).then(kaydet); };
    if (o && o.refresh_token) {
      return istek("/auth/v1/token?grant_type=refresh_token", { method: "POST", body: { refresh_token: o.refresh_token } })
        .then(kaydet, yeni);
    }
    return yeni();
  }
  function yetkili(f) { return oturum().then(f); }

  var S = {
    hazir: hazir,
    iller: function () {
      return istek("/rest/v1/cities?select=name").then(function (r) {
        return r.map(function (x) { return x.name; }).sort(function (a, b) { return a.localeCompare(b, "tr"); });
      });
    },
    oyuncu: function () {
      return yetkili(function (o) {
        return istek("/rest/v1/players?select=id,nick,city&id=eq." + o.user_id, { jwt: o.access_token })
          .then(function (r) { return (r && r[0]) || null; });
      });
    },
    oyuncuKaydet: function (nick, city) {
      return yetkili(function (o) {
        return istek("/rest/v1/players", { method: "POST", jwt: o.access_token, headers: { Prefer: "return=minimal" },
          body: { id: o.user_id, nick: nick, city: city || null } });
      });
    },
    // Oyuncunun o günkü bitmiş turları: [{round, score}] (tur sırasıyla)
    skorlar: function (tarih) {
      return yetkili(function (o) {
        return istek("/rest/v1/daily_scores?select=round,score&order=round.asc&date=eq." + tarih, { jwt: o.access_token });
      });
    },
    tur: function (action, round, answer) {
      return yetkili(function (o) {
        return istek("/functions/v1/daily-round", { method: "POST", jwt: o.access_token, body: { action: action, round: round, answer: answer } });
      });
    },
    // Canlı düello: action = queue | status | bot | start | submit (bkz. supabase/functions/duel)
    duello: function (action, ek) {
      return yetkili(function (o) {
        var body = { action: action };
        for (var k in (ek || {})) body[k] = ek[k];
        return istek("/functions/v1/duel", { method: "POST", jwt: o.access_token, body: body });
      });
    },
    siralama: function (tarih) {
      return yetkili(function (o) {
        return istek("/rest/v1/daily_leaderboard?select=nick,city,total,rank&order=rank.asc&limit=10&date=eq." + tarih, { jwt: o.access_token });
      });
    },
    ilLigi: function (hafta) {
      return yetkili(function (o) {
        return istek("/rest/v1/city_league?select=city,total,players,average&order=total.desc&limit=10&week=eq." + hafta, { jwt: o.access_token });
      });
    }
  };
  root.Sunucu = S;
})(window);
