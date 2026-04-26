# ugly Cooking

**ugly Cooking**, **QBCore** ve **ox_inventory** kullanan bir **FiveM** kaynağıdır: çok aşamalı pişirme akışı (hazırlık → pişirme), **ox_lib** beceri kontrolleri, **NUI** menü, mutfak koordinatlarında isteğe bağlı **ox_target** / **qb-target** etkileşimi ve eşya silinmeden/verilmeden önce sunucu tarafında doğrulama (meslek, mesafe, malzeme).

**Sürüm:** 1.0.0 (`fxmanifest.lua`)  
**Yazar:** ugly Development

---

## Özellikler

- **Mesleğe bağlı mutfaklar:** `Config.Shops` içindeki her anahtar **QB iş adı** (`PlayerData.job.name`) ile eşleşmelidir. Oyuncu yalnızca kendi işine ait tarifleri görür ve yapılandırılan mutfak yarıçapı içinde olmalıdır.
- **Tarifler:** İşletme başına malzemeler (ox eşya adı + miktar), hazırlık aşaması (zorluk + süre), pişirme aşaması (cihaz: `frying_pan` | `oven` | `grill`, süre, isteğe bağlı animasyon).
- **Kalite:** Beceri kontrolü başarı oranı bir kalite yüzdesine dönüşür (`Config.MinQuality`–`Config.MaxQuality`); son ürün **metadata** ile gelir (kalite etiketi, renk, `created_at`, `expires_at`).
- **ox_lib:** Yakınlık noktaları, progress ve skillcheck API’leri.
- **Arayüz:** `html/` NUI; menü açıkken envanter güncellemesi (`ox_inventory:updateInventory`).
- **Komutlar:** Varsayılan `Config.OpenCommand` **`/cook`** (`config.lua`’dan değiştirilebilir). `Config.OpenKey` gerçek bir tuş adıysa tuş ataması da açılır (`'nil'` metni tuş değil, kapalı bırakmak için `nil` kullanın).
- **Efektler:** İsteğe bağlı **interact-sound** (`chopping.ogg`, `frying.ogg`), duman partikülü, bıçak/tava prop’u, BBQ tarzı pişirme animasyonu (`Config.CookingEffects`).
- **Export’lar (client):** `HasKitchenAccess`, `OpenCookingMenu`, `CloseCookingMenu` (`client/main.lua`).

---

## Bağımlılıklar

`fxmanifest.lua` içinde bildirilenler:

| Kaynak | Görevi |
|----------|------|
| **qb-core** | Oyuncu verisi, callback’ler, bildirimler |
| **ox_inventory** | Eşyalar, ekleme/çıkarma, sayım araması, pişmiş ürün metadata |
| **ox_lib** | Points, progress, skillcheck, ortak init |

**`Config.UseTarget` açıksa zorunlu sayılır:**

- **ox_target** (`Config.TargetResource == 'ox_target'`), veya  
- **qb-target** / **qtarget** (`Config.TargetResource == 'qb-target'` — kod `exports.qtarget` kullanır; sunucunuzdaki hedef kaynağın adıyla eşleştirin).

**İsteğe bağlı:**

- **interact-sound** — doğrama/kızartma sesleri (`Config.CookingEffects.interactSound`).

---

## Kurulum

### 1. Kaynağı kopyalayın

Örnek yapı:

```text
resources/
  [ugly]/
    ugly-cooking/
      fxmanifest.lua
      config.lua
      ITEMS.lua
      ...
```

### 2. ox_inventory’de eşyaları tanımlayın

`ugly-cooking/ITEMS.lua` dosyasını açın. Dönen tabloyu **`ox_inventory/data/items.lua`** dosyanıza (ox’ın beklediği biçimde) ekleyin. Dosya başlığında belirtildiği gibi:

- Tanımları ox_inventory `items` dosyanıza taşıyın.
- Görselleri **`ox_inventory/web/images/`** altına koyun (tarif/config’te kullanılan isimlerle uyumlu, örn. `gourmet_burger.png`).

Pişmiş ürünler metadata farklı olduğu için **`stack = false`** kullanılır.

### 3. Sunucu yapılandırması (`server.cfg`)

Bu kaynaktan önce bağımlılıklar çalışmalıdır, örneğin:

```cfg
ensure qb-core
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure [ugly]
```

Veya doğrudan:

```cfg
ensure ugly-cooking
```

`ensure [ugly]` kullanıyorsanız `ugly-cooking` bu klasörün içinde olmalıdır.

### 4. `config.lua` düzenlemesi

- **`Config.Shops`:** Anahtarlar **QB iş adı** ile birebir aynı olmalı (örnekte `police`, `pizzaria`). Her işletmede `locations` (`vector3` listesi), isteğe bağlı `radius`, isteğe bağlı `blip`, `recipes`.
- **`Config.KitchenProximity`:** İşletmede `radius` yoksa kullanılan varsayılan etkileşim mesafesi (metre).
- **`Config.UseTarget` / `Config.TargetResource`:** Bölge etkileşimi ve hedef script seçimi.
- **`Config.OpenCommand` / `Config.OpenKey`:** Menü komutu ve isteğe bağlı tuş.
- **`Config.Debug`:** Konsolda ayrıntılı log.

**Önemli:** Örnek yapılandırmada **`police`** işi belirli bir koordinata “LSPD mutfağı” olarak bağlanmıştır. Gerçek işlerinize ve interior koordinatlarınıza göre anahtarları, etiketleri ve tarifleri güncelleyin.

### 5. Dil (locale)

`fxmanifest.lua` **`locales/tr.lua`** yükler; dosya `Locale = Locales.tr` atar. İngilizce eklemek için örn. `locales/en.lua` oluşturup `shared_scripts`’e ekleyebilir ve `Locale` atamasını değiştirebilirsiniz.

### 6. İsteğe bağlı sesler (interact-sound)

`Config.CookingEffects.interactSound.enabled` true ise, interact-sound kaynağınızdaki istemci ses yoluna **`chopping.ogg`** ve **`frying.ogg`** ekleyin (`config.lua` içindeki yorum satırına bakın).

### 7. Yeniden başlatma

Sunucuyu yeniden başlatın veya:

```text
ensure ugly-cooking
```

`Config.Shops`’ta tanımlı **iş**e sahip bir karakterle, **mutfak konumunda**, envanterde **malzemeler** varken test edin.

---

## Kısa akış

1. İstemci meslek + mutfak yakınlığını kontrol eder (ox_lib **points** ve/veya **target**).
2. Menü açılınca **`ugly_cooking:server:GetPlayerInventory`** ile envanter özeti alınır.
3. Tarif başlatılınca sunucu **`ugly_cooking:server:ValidateIngredients`** ile iş, tarif, mesafe ve miktarları doğrular.
4. İstemci hazırlık/pişirme progress ve skillcheck çalıştırır; bitişte **`ugly_cooking:server:FinalizeCooking`** tekrar doğrular, malzemeleri düşer, metadata’lı son ürünü verir; oyuncu başına kilit spam’i engeller.

---

## Sorun giderme

| Sorun | Kontrol listesi |
|--------|----------------|
| Erişim yok / yanlış konum | `Config.Shops` anahtarı `job.name` ile aynı mı; oyuncu `locations` + yarıçap içinde mi. |
| Arayüzde malzeme görünmüyor | ox_inventory’de eşya tanımlı mı; `ingredients[].item` isimleri eşleşiyor mu. |
| Target çalışmıyor | `ox_target` (veya qtarget) çalışıyor mu; `Config.TargetResource` doğru mu; bölgedeki `groups` iş adıyla uyumlu mu. |
| Menü açılmıyor | `qb-core` yüklü mü; `/cook` deneyin; tuş için `Config.OpenKey` gerçek tuş adı olmalı, metin `'nil'` tuşu kapatmaz. |
| NUI’de görseller eksik | `html/img/` ve ox_inventory web görselleri (`ITEMS.lua` açıklaması). |

---

## Dosya haritası

| Yol | Amaç |
|------|---------|
| `config.lua` | İşletmeler, tarifler, skillcheck haritası, efektler, cihazlar |
| `ITEMS.lua` | ox_inventory’e birleştirilecek eşya şablonları |
| `client/main.lua` | Yakınlık, target, menü, komutlar |
| `client/cooking.lua` | Animasyonlar, progress, skillcheck, efektler |
| `client/nui.lua` | NUI callback’leri |
| `server/main.lua` | Callback’ler, doğrulama yardımcıları |
| `server/cooking.lua` | Pişirmeyi tamamlama, metadata, cooldown kilidi |
| `shared/utils.lua` | Kalite, mesafe, log |
| `html/` | NUI varlıkları |
| `middleware/v2_settings.js` | Paket middleware (shared) |

---

## Lisans

Paket ayrı bir lisans dosyası içeriyorsa o dosyaya uyun. Bu README yalnızca dokümantasyondur.
