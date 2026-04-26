-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — LOCALES (TR)                     ║
-- ╚══════════════════════════════════════════════════════════════╝

Locales = Locales or {}

Locales.tr = {
    -- Genel
    cooking_title          = 'Gladius Cooking',
    back                   = 'Geri',
    start_prep             = 'HAZIRLIKLARA BAŞLA',
    cancel                 = 'İPTAL ETMEK',
    step_prep              = 'ADIM 1: HAZIRLIK',
    step_cook              = 'ADIM 2: PİŞİRME',
    mini_game              = 'MINI-GAME',
    skill_check            = 'BECERİ KONTROLÜ',
    perfect_timing         = '%90ın üzerinde kalite için [E] tuşuna tam zamanında basın.',
    skill_perfect          = 'Mükemmel!',
    skill_press_e          = 'Beyaz çizgi yeşil bölgedeyken E tuşuna basın.',
    use_appliance          = 'KULLANMAK:',
    cooking_time           = 'PİŞİRME SÜRESİ:',
    final_item             = 'SON MADDE:',
    expected_quality       = 'BEKLENEN KALİTE:',
    estimated_expiration   = 'TAHMİNİ SON KULLANMA TARİHİ:',
    effects                = 'ETKİLER:',
    location               = 'KONUM:',

    -- Bildirimler
    notify_no_job          = 'Bu menüye erişim yetkin yok.',
    notify_wrong_location  = 'Bu menüyü açmak için mutfakta olman gerekiyor.',
    notify_no_ingredients  = 'Yeterli malzemen yok.',
    notify_prep_success    = 'Hazırlık tamamlandı! Şimdi pişiriliyor...',
    notify_prep_failed     = 'Hazırlık başarısız oldu, kalite düştü.',
    notify_cook_success    = 'Yemek hazır! Afiyet olsun.',
    notify_cook_failed     = 'Pişirme sırasında bir hata oluştu.',
    notify_already_cooking = 'Zaten bir yemek hazırlıyorsun.',
    notify_inventory_full  = 'Envanterin dolu.',
    notify_cancelled       = 'İşlem iptal edildi.',

    -- Target / interact
    target_open_menu       = 'Mutfağı Aç',

    -- Prep / cook states
    state_preparing        = 'Hazırlanıyor...',
    state_cooking          = 'Pişiriliyor...',
    state_done             = 'Tamamlandı',
}

-- Aktif dil (şu an sadece TR var, EN eklenebilir)
Locale = Locales.tr

---@param key string
---@return string
function _(key)
    return Locale[key] or key
end
