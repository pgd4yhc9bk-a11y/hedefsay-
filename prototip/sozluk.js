// GEÇİCİ DENEME SÖZLÜĞÜ — yayın sözlüğü değildir.
// Prototipte kuralları denemek için elle yazılmış küçük bir yalın kök / madde başı listesi.
// Yayın öncesi Zemberek-NLP (lisans doğrulanacak) veya kendi listemizle değiştirilecek.
// Normalleştirme: küçük harf, â/î/û -> a/i/u (bkz. Hedef.trLower).
(function (root) {
  var kelimeler = [
    // isimler
    "ada ağaç ahşap akşam alan altın anahtar arkadaş arı armut arzu asker aslan ayak ayna baba bahçe",
    "bakır balık balkon bardak basın bayram bebek bellek benzer beyaz bilgi bilim bina bisiklet bitki",
    "boya böcek bulut bulmaca büyük cadde cevap cümle çanta çarşı çatı çay çelik çiçek çift çocuk",
    "çorba çözüm dağ damla deniz defter deri dere devlet dil diş doğa doktor dolap dost dünya düşman",
    "ekmek elma elbise emek enerji erkek eser fabrika fikir film fırın fidan fırça gazete gece gemi",
    "genç gökyüzü göl gömlek gözlük gün güneş gürültü hafta halı hareket hava hayat hayvan hediye",
    "heyecan hikaye hizmet ilaç ilkbahar insan ışık ihtiyaç kadın kağıt kahve kale kalem kalp kanat",
    "kapı kardeş kasaba kaşık kavun kedi kelime kemer kenar kervan kıyı kısa kitap koltuk komşu konu",
    "koyun köprü köpek köy kutu kuzu lamba lastik liman limon makine masa mavi mektup merdiven meyve",
    "mevsim mısır mutfak müzik nehir nokta okul orman otobüs oyun ödül öğrenci öğretmen pamuk",
    "pantolon para parmak pencere peynir pırasa radyo rakam renk resim rüzgar saat sabah sağlık sakin",
    "salata sanat sandalye savaş sebze ses sıcak sınıf siyah soğan söz spor sürpriz şehir şeker şiir",
    "şarkı şemsiye takvim tarih tarla tavan telefon temiz tepe tiyatro toprak tren uçak umut uyku",
    "vapur yağmur yapı yaprak yarış yastık yemek yıldız yol yön yumurta yüzük zaman zeytin zemin zil",
    "bilgisayar arkadaşlık güzellik çalışkan başarı başkent yarışma yarışmacı kelebek kaplumbağa",
    "karınca papatya kirpi tavşan zürafa fındık badem çilek kiraz şeftali portakal mandalina karpuz",
    "patates domates biber patlıcan fasulye nohut mercimek makarna pirinç bulgur tereyağı yoğurt",
    "tatlı çikolata bisküvi pasta kurabiye kütüphane tarlakuşu sokak mahalle apartman duvar kapak",
    "ayakkabı çorap şapka eldiven atkı kazak ceket kravat cüzdan saç sakal kaş kirpik burun kulak",
    "yüz boyun omuz kol dirsek bilek bacak diz kemik kalça sırt karın göğüs damar kan deri kafa",
    "anne baba abla ağabey amca teyze dayı hala torun yeğen gelin damat bebek çocuk büyükanne",
    "kuzey güney doğu batı yıl ay hafta dakika saniye pazartesi salı çarşamba perşembe cuma cumartesi pazar",
    "ocak şubat mart nisan mayıs haziran temmuz ağustos eylül ekim kasım aralık",
    "kış yaz sonbahar ilkbahar bahar sis kar yağış fırtına şimşek gökkuşağı sağanak deprem yangın",
    "tahta kalemlik silgi cetvel makas yapıştırıcı sınav ders karne tatil zil okul teneffüs",
    "ekran klavye fare yazıcı tablet harita pusula gözcü kule kale saray cami köşk hamam çeşme",
    "tavuk horoz kaz ördek kuş kartal şahin serçe güvercin leylek kumru baykuş yarasa kurt tilki",
    "ayı geyik tavşan sincap fare kaplan aslan fil zürafa maymun yılan kertenkele kurbağa",
    "midye karides ahtapot yengeç levrek hamsi palamut sardalya uskumru çipura somon",
    "taş kaya kum çakıl toprak çamur tuz şeker un yağ süt bal reçel tahin pekmez sirke",
    "yatak yorgan yastık çarşaf perde halı kilim avize abajur tabak çatal bıçak kaşık tencere",
    "tava demlik cezve fincan bardak sürahi kavanoz tepsi sepet fırça süpürge kova ütü",
    "futbol basketbol voleybol tenis yüzme koşu güreş okçuluk jimnastik halter boks eskrim",
    "resim heykel müzik tiyatro sinema roman öykü masal destan türkü ezgi ritim melodi",
    "piyano gitar keman davul flüt kemençe bağlama kanun ney darbuka zurna def",
    // mastarlar
    "gelmek gitmek bakmak yazmak okumak almak vermek bilmek görmek sevmek yapmak etmek olmak durmak",
    "kalmak koşmak yürümek gülmek ağlamak uyumak uyanmak içmek düşmek çalışmak çalmak kapamak açmak",
    "kesmek bulmak aramak anlamak anlatmak dinlemek konuşmak söylemek düşünmek öğrenmek öğretmek",
    "başlamak bitmek bitirmek beklemek bırakmak taşımak tutmak atmak çekmek itmek sürmek satmak",
    "yıkamak boyamak çizmek kurmak bozmak sarmak saymak saklamak savaşmak seçmek sormak soymak",
    "sıkmak sokmak tanımak tatmak toplamak unutmak uçmak varmak vurmak yakmak yaşamak yatmak yenmek",
    "yıkmak yormak yüzmek zorlamak geçmek gezmek girmek gizlemek hatırlamak hazırlamak istemek izlemek",
    "kaçmak kaybetmek kazanmak kırmak kızmak korkmak korumak koymak kullanmak paylaşmak sevinmek",
    "sığmak sıçramak tırmanmak titremek ulaşmak üretmek ürkmek üzmek üzülmek yaklaşmak yanmak",
    "çağırmak çıkmak çözmek dağıtmak değişmek denemek dikmek dokunmak dönmek dövmek duymak düzeltmek",
    "eklemek eğlenmek ekmek göndermek hesaplamak kalkmak kapatmak karşılamak katılmak kavramak",
    "kıskanmak kovalamak kurtarmak mahvetmek memnun merak nefes okşamak",
    "onarmak oturmak oynamak ölçmek özlemek öpmek pişirmek pişmek sabretmek salmak sarılmak sevgi",
    "sınamak sulamak susmak tamamlamak tarafsız tartmak tasarlamak taramak tırnak toparlamak",
    "uzanmak uzaklaşmak uzatmak üflemek ürpermek vazgeçmek yağmak yakalamak yanıt yansıtmak",
    "yapışmak yaymak yazdırmak yemek yetişmek yetmek yönetmek yükselmek yürütmek zayıflamak",
    // sıfatlar
    "güzel çirkin uzun kısa geniş dar yüksek alçak ağır hafif sıcak soğuk sert yumuşak ıslak kuru",
    "temiz kirli yeni eski genç yaşlı hızlı yavaş kolay zor güçlü zayıf mutlu üzgün cesur korkak",
    "akıllı aptal çalışkan tembel cömert cimri sessiz gürültülü karanlık aydınlık tatlı acı ekşi",
    "tuzlu kalın ince derin sığ dolu boş açık kapalı doğru yanlış gerçek sahte pahalı ucuz zengin fakir",
    "kırmızı yeşil sarı turuncu mor pembe kahverengi gri lacivert bordo turkuaz"
  ].join(" ").split(/\s+/).filter(Boolean);
  root.HEDEF_SOZLUK = kelimeler;
})(typeof window !== "undefined" ? window : globalThis);
