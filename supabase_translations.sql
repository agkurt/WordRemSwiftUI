-- ============================================================
-- WordRem — Word Translations (Multi-language JSONB)
-- Run AFTER supabase_multilang_seed.sql
-- Adds "translations" JSONB column so quiz shows words in phone language
-- ============================================================

ALTER TABLE words ADD COLUMN IF NOT EXISTS translations JSONB DEFAULT '{}';

-- ══════════════════════════════════════════════════════════
-- 🇫🇷 FRENCH COURSE — Level 1: Greetings
-- ══════════════════════════════════════════════════════════
UPDATE words SET translations='{"TR":"merhaba","EN":"hello","DE":"Hallo","ES":"hola","IT":"ciao","RU":"Привет","ZH":"你好"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"teşekkürler","EN":"thank you","DE":"danke","ES":"gracias","IT":"grazie","RU":"спасибо","ZH":"谢谢"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"lütfen","EN":"please","DE":"bitte","ES":"por favor","IT":"per favore","RU":"пожалуйста","ZH":"请"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"evet","EN":"yes","DE":"ja","ES":"sí","IT":"sì","RU":"да","ZH":"是"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"hayır","EN":"no","DE":"nein","ES":"no","IT":"no","RU":"нет","ZH":"不"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"iyi akşamlar","EN":"good evening","DE":"Guten Abend","ES":"buenas noches","IT":"buona sera","RU":"добрый вечер","ZH":"晚上好"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"hoşçakal","EN":"goodbye","DE":"auf Wiedersehen","ES":"adiós","IT":"arrivederci","RU":"до свидания","ZH":"再见"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"affedersiniz","EN":"excuse me","DE":"Entschuldigung","ES":"disculpe","IT":"scusi","RU":"извините","ZH":"对不起"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"benim adım","EN":"my name is","DE":"mein Name ist","ES":"me llamo","IT":"mi chiamo","RU":"меня зовут","ZH":"我叫"}'::jsonb WHERE id='f0000001-0001-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"nasılsınız","EN":"how are you","DE":"wie geht es Ihnen","ES":"cómo está usted","IT":"come sta","RU":"как дела","ZH":"你好吗"}'::jsonb WHERE id='f0000001-0001-0001-0000-00000000000a';

-- FR Level 2: Numbers
UPDATE words SET translations='{"TR":"bir","EN":"one","DE":"eins","ES":"uno","IT":"uno","RU":"один","ZH":"一"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"iki","EN":"two","DE":"zwei","ES":"dos","IT":"due","RU":"два","ZH":"二"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"üç","EN":"three","DE":"drei","ES":"tres","IT":"tre","RU":"три","ZH":"三"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"dört","EN":"four","DE":"vier","ES":"cuatro","IT":"quattro","RU":"четыре","ZH":"四"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beş","EN":"five","DE":"fünf","ES":"cinco","IT":"cinque","RU":"пять","ZH":"五"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"altı","EN":"six","DE":"sechs","ES":"seis","IT":"sei","RU":"шесть","ZH":"六"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"yedi","EN":"seven","DE":"sieben","ES":"siete","IT":"sette","RU":"семь","ZH":"七"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sekiz","EN":"eight","DE":"acht","ES":"ocho","IT":"otto","RU":"восемь","ZH":"八"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"dokuz","EN":"nine","DE":"neun","ES":"nueve","IT":"nove","RU":"девять","ZH":"九"}'::jsonb WHERE id='f0000001-0002-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"on","EN":"ten","DE":"zehn","ES":"diez","IT":"dieci","RU":"десять","ZH":"十"}'::jsonb WHERE id='f0000001-0002-0001-0000-00000000000a';

-- FR Level 3: Colors
UPDATE words SET translations='{"TR":"kırmızı","EN":"red","DE":"rot","ES":"rojo","IT":"rosso","RU":"красный","ZH":"红色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"mavi","EN":"blue","DE":"blau","ES":"azul","IT":"blu","RU":"синий","ZH":"蓝色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"yeşil","EN":"green","DE":"grün","ES":"verde","IT":"verde","RU":"зелёный","ZH":"绿色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"sarı","EN":"yellow","DE":"gelb","ES":"amarillo","IT":"giallo","RU":"жёлтый","ZH":"黄色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beyaz","EN":"white","DE":"weiß","ES":"blanco","IT":"bianco","RU":"белый","ZH":"白色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"siyah","EN":"black","DE":"schwarz","ES":"negro","IT":"nero","RU":"чёрный","ZH":"黑色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"turuncu","EN":"orange","DE":"orange","ES":"naranja","IT":"arancione","RU":"оранжевый","ZH":"橙色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"pembe","EN":"pink","DE":"rosa","ES":"rosa","IT":"rosa","RU":"розовый","ZH":"粉色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"gri","EN":"grey","DE":"grau","ES":"gris","IT":"grigio","RU":"серый","ZH":"灰色"}'::jsonb WHERE id='f0000001-0003-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"mor","EN":"purple","DE":"violett","ES":"violeta","IT":"viola","RU":"фиолетовый","ZH":"紫色"}'::jsonb WHERE id='f0000001-0003-0001-0000-00000000000a';

-- FR Level 4: Family
UPDATE words SET translations='{"TR":"baba","EN":"father","DE":"Vater","ES":"padre","IT":"padre","RU":"отец","ZH":"父亲"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"anne","EN":"mother","DE":"Mutter","ES":"madre","IT":"madre","RU":"мать","ZH":"母亲"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"erkek kardeş","EN":"brother","DE":"Bruder","ES":"hermano","IT":"fratello","RU":"брат","ZH":"兄弟"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"kız kardeş","EN":"sister","DE":"Schwester","ES":"hermana","IT":"sorella","RU":"сестра","ZH":"姐妹"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"oğul","EN":"son","DE":"Sohn","ES":"hijo","IT":"figlio","RU":"сын","ZH":"儿子"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"kız","EN":"daughter","DE":"Tochter","ES":"hija","IT":"figlia","RU":"дочь","ZH":"女儿"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"büyükbaba","EN":"grandfather","DE":"Großvater","ES":"abuelo","IT":"nonno","RU":"дедушка","ZH":"爷爷"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"büyükanneye","EN":"grandmother","DE":"Großmutter","ES":"abuela","IT":"nonna","RU":"бабушка","ZH":"奶奶"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"koca","EN":"husband","DE":"Mann","ES":"marido","IT":"marito","RU":"муж","ZH":"丈夫"}'::jsonb WHERE id='f0000001-0004-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"eş","EN":"wife","DE":"Frau","ES":"esposa","IT":"moglie","RU":"жена","ZH":"妻子"}'::jsonb WHERE id='f0000001-0004-0001-0000-00000000000a';

-- FR Level 5: Food
UPDATE words SET translations='{"TR":"ekmek","EN":"bread","DE":"Brot","ES":"pan","IT":"pane","RU":"хлеб","ZH":"面包"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"su","EN":"water","DE":"Wasser","ES":"agua","IT":"acqua","RU":"вода","ZH":"水"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"kahve","EN":"coffee","DE":"Kaffee","ES":"café","IT":"caffè","RU":"кофе","ZH":"咖啡"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"şarap","EN":"wine","DE":"Wein","ES":"vino","IT":"vino","RU":"вино","ZH":"葡萄酒"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"elma","EN":"apple","DE":"Apfel","ES":"manzana","IT":"mela","RU":"яблоко","ZH":"苹果"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"peynir","EN":"cheese","DE":"Käse","ES":"queso","IT":"formaggio","RU":"сыр","ZH":"奶酪"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"et","EN":"meat","DE":"Fleisch","ES":"carne","IT":"carne","RU":"мясо","ZH":"肉"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sebze","EN":"vegetable","DE":"Gemüse","ES":"verdura","IT":"verdura","RU":"овощи","ZH":"蔬菜"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"meyve","EN":"fruit","DE":"Obst","ES":"fruta","IT":"frutto","RU":"фрукт","ZH":"水果"}'::jsonb WHERE id='f0000001-0005-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"süt","EN":"milk","DE":"Milch","ES":"leche","IT":"latte","RU":"молоко","ZH":"牛奶"}'::jsonb WHERE id='f0000001-0005-0001-0000-00000000000a';

-- FR Level 6: Animals
UPDATE words SET translations='{"TR":"köpek","EN":"dog","DE":"Hund","ES":"perro","IT":"cane","RU":"собака","ZH":"狗"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"kedi","EN":"cat","DE":"Katze","ES":"gato","IT":"gatto","RU":"кошка","ZH":"猫"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"kuş","EN":"bird","DE":"Vogel","ES":"pájaro","IT":"uccello","RU":"птица","ZH":"鸟"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"balık","EN":"fish","DE":"Fisch","ES":"pez","IT":"pesce","RU":"рыба","ZH":"鱼"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"at","EN":"horse","DE":"Pferd","ES":"caballo","IT":"cavallo","RU":"лошадь","ZH":"马"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"inek","EN":"cow","DE":"Kuh","ES":"vaca","IT":"mucca","RU":"корова","ZH":"牛"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"domuz","EN":"pig","DE":"Schwein","ES":"cerdo","IT":"maiale","RU":"свинья","ZH":"猪"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"koyun","EN":"sheep","DE":"Schaf","ES":"oveja","IT":"pecora","RU":"овца","ZH":"羊"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"tavşan","EN":"rabbit","DE":"Hase","ES":"conejo","IT":"coniglio","RU":"кролик","ZH":"兔子"}'::jsonb WHERE id='f0000001-0006-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"aslan","EN":"lion","DE":"Löwe","ES":"león","IT":"leone","RU":"лев","ZH":"狮子"}'::jsonb WHERE id='f0000001-0006-0001-0000-00000000000a';

-- FR Level 7: Days & Time
UPDATE words SET translations='{"TR":"pazartesi","EN":"Monday","DE":"Montag","ES":"lunes","IT":"lunedì","RU":"понедельник","ZH":"星期一"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"salı","EN":"Tuesday","DE":"Dienstag","ES":"martes","IT":"martedì","RU":"вторник","ZH":"星期二"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"çarşamba","EN":"Wednesday","DE":"Mittwoch","ES":"miércoles","IT":"mercoledì","RU":"среда","ZH":"星期三"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"perşembe","EN":"Thursday","DE":"Donnerstag","ES":"jueves","IT":"giovedì","RU":"четверг","ZH":"星期四"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"cuma","EN":"Friday","DE":"Freitag","ES":"viernes","IT":"venerdì","RU":"пятница","ZH":"星期五"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"cumartesi","EN":"Saturday","DE":"Samstag","ES":"sábado","IT":"sabato","RU":"суббота","ZH":"星期六"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"pazar","EN":"Sunday","DE":"Sonntag","ES":"domingo","IT":"domenica","RU":"воскресенье","ZH":"星期日"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sabah","EN":"morning","DE":"Morgen","ES":"mañana","IT":"mattina","RU":"утро","ZH":"早上"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"akşam","EN":"evening","DE":"Abend","ES":"tarde","IT":"sera","RU":"вечер","ZH":"晚上"}'::jsonb WHERE id='f0000001-0007-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"gece","EN":"night","DE":"Nacht","ES":"noche","IT":"notte","RU":"ночь","ZH":"夜晚"}'::jsonb WHERE id='f0000001-0007-0001-0000-00000000000a';

-- FR Level 8: Body
UPDATE words SET translations='{"TR":"baş","EN":"head","DE":"Kopf","ES":"cabeza","IT":"testa","RU":"голова","ZH":"头"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"el","EN":"hand","DE":"Hand","ES":"mano","IT":"mano","RU":"рука","ZH":"手"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"ayak","EN":"foot","DE":"Fuß","ES":"pie","IT":"piede","RU":"нога","ZH":"脚"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"göz","EN":"eye","DE":"Auge","ES":"ojo","IT":"occhio","RU":"глаз","ZH":"眼睛"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"kulak","EN":"ear","DE":"Ohr","ES":"oreja","IT":"orecchio","RU":"ухо","ZH":"耳朵"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"burun","EN":"nose","DE":"Nase","ES":"nariz","IT":"naso","RU":"нос","ZH":"鼻子"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"ağız","EN":"mouth","DE":"Mund","ES":"boca","IT":"bocca","RU":"рот","ZH":"嘴巴"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"kol","EN":"arm","DE":"Arm","ES":"brazo","IT":"braccio","RU":"рука","ZH":"手臂"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"bacak","EN":"leg","DE":"Bein","ES":"pierna","IT":"gamba","RU":"нога","ZH":"腿"}'::jsonb WHERE id='f0000001-0008-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"kalp","EN":"heart","DE":"Herz","ES":"corazón","IT":"cuore","RU":"сердце","ZH":"心脏"}'::jsonb WHERE id='f0000001-0008-0001-0000-00000000000a';

-- FR Level 9: Travel
UPDATE words SET translations='{"TR":"tren","EN":"train","DE":"Zug","ES":"tren","IT":"treno","RU":"поезд","ZH":"火车"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"uçak","EN":"plane","DE":"Flugzeug","ES":"avión","IT":"aereo","RU":"самолёт","ZH":"飞机"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"otel","EN":"hotel","DE":"Hotel","ES":"hotel","IT":"hotel","RU":"отель","ZH":"酒店"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"pasaport","EN":"passport","DE":"Pass","ES":"pasaporte","IT":"passaporto","RU":"паспорт","ZH":"护照"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"bilet","EN":"ticket","DE":"Ticket","ES":"billete","IT":"biglietto","RU":"билет","ZH":"票"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"istasyon","EN":"station","DE":"Bahnhof","ES":"estación","IT":"stazione","RU":"вокзал","ZH":"车站"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"havalimanı","EN":"airport","DE":"Flughafen","ES":"aeropuerto","IT":"aeroporto","RU":"аэропорт","ZH":"机场"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"harita","EN":"map","DE":"Karte","ES":"mapa","IT":"mappa","RU":"карта","ZH":"地图"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"bavul","EN":"suitcase","DE":"Koffer","ES":"maleta","IT":"valigia","RU":"чемодан","ZH":"行李箱"}'::jsonb WHERE id='f0000001-0009-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"taksi","EN":"taxi","DE":"Taxi","ES":"taxi","IT":"taxi","RU":"такси","ZH":"出租车"}'::jsonb WHERE id='f0000001-0009-0001-0000-00000000000a';

-- FR Level 10: Verbs
UPDATE words SET translations='{"TR":"olmak","EN":"to be","DE":"sein","ES":"ser","IT":"essere","RU":"быть","ZH":"是"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"sahip olmak","EN":"to have","DE":"haben","ES":"tener","IT":"avere","RU":"иметь","ZH":"有"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"gitmek","EN":"to go","DE":"gehen","ES":"ir","IT":"andare","RU":"идти","ZH":"去"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"gelmek","EN":"to come","DE":"kommen","ES":"venir","IT":"venire","RU":"приходить","ZH":"来"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"yemek","EN":"to eat","DE":"essen","ES":"comer","IT":"mangiare","RU":"есть","ZH":"吃"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"içmek","EN":"to drink","DE":"trinken","ES":"beber","IT":"bere","RU":"пить","ZH":"喝"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"uyumak","EN":"to sleep","DE":"schlafen","ES":"dormir","IT":"dormire","RU":"спать","ZH":"睡觉"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"çalışmak","EN":"to work","DE":"arbeiten","ES":"trabajar","IT":"lavorare","RU":"работать","ZH":"工作"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"konuşmak","EN":"to speak","DE":"sprechen","ES":"hablar","IT":"parlare","RU":"говорить","ZH":"说话"}'::jsonb WHERE id='f0000001-000a-0001-0000-000000000009';
UPDATE words SET translations='{"TR":"sevmek","EN":"to love","DE":"lieben","ES":"amar","IT":"amare","RU":"любить","ZH":"爱"}'::jsonb WHERE id='f0000001-000a-0001-0000-00000000000a';

-- ══════════════════════════════════════════════════════════
-- 🇩🇪 GERMAN COURSE — Level 1: Greetings
-- ══════════════════════════════════════════════════════════
UPDATE words SET translations='{"TR":"merhaba","EN":"hello","FR":"bonjour","ES":"hola","IT":"ciao","RU":"Привет","ZH":"你好"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"teşekkürler","EN":"thank you","FR":"merci","ES":"gracias","IT":"grazie","RU":"спасибо","ZH":"谢谢"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"lütfen","EN":"please","FR":"s il vous plaît","ES":"por favor","IT":"per favore","RU":"пожалуйста","ZH":"请"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"evet","EN":"yes","FR":"oui","ES":"sí","IT":"sì","RU":"да","ZH":"是"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"hayır","EN":"no","FR":"non","ES":"no","IT":"no","RU":"нет","ZH":"不"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"günaydın","EN":"good morning","FR":"bonjour","ES":"buenos días","IT":"buongiorno","RU":"доброе утро","ZH":"早上好"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"iyi akşamlar","EN":"good evening","FR":"bonsoir","ES":"buenas noches","IT":"buona sera","RU":"добрый вечер","ZH":"晚上好"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"hoşçakal","EN":"goodbye","FR":"au revoir","ES":"adiós","IT":"arrivederci","RU":"до свидания","ZH":"再见"}'::jsonb WHERE id='de000001-0001-0001-0000-000000000008';

-- DE Level 2: Numbers
UPDATE words SET translations='{"TR":"bir","EN":"one","FR":"un","ES":"uno","IT":"uno","RU":"один","ZH":"一"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"iki","EN":"two","FR":"deux","ES":"dos","IT":"due","RU":"два","ZH":"二"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"üç","EN":"three","FR":"trois","ES":"tres","IT":"tre","RU":"три","ZH":"三"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"dört","EN":"four","FR":"quatre","ES":"cuatro","IT":"quattro","RU":"четыре","ZH":"四"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beş","EN":"five","FR":"cinq","ES":"cinco","IT":"cinque","RU":"пять","ZH":"五"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"altı","EN":"six","FR":"six","ES":"seis","IT":"sei","RU":"шесть","ZH":"六"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"yedi","EN":"seven","FR":"sept","ES":"siete","IT":"sette","RU":"семь","ZH":"七"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sekiz","EN":"eight","FR":"huit","ES":"ocho","IT":"otto","RU":"восемь","ZH":"八"}'::jsonb WHERE id='de000001-0002-0001-0000-000000000008';

-- DE Level 3: Colors
UPDATE words SET translations='{"TR":"kırmızı","EN":"red","FR":"rouge","ES":"rojo","IT":"rosso","RU":"красный","ZH":"红色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"mavi","EN":"blue","FR":"bleu","ES":"azul","IT":"blu","RU":"синий","ZH":"蓝色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"yeşil","EN":"green","FR":"vert","ES":"verde","IT":"verde","RU":"зелёный","ZH":"绿色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"sarı","EN":"yellow","FR":"jaune","ES":"amarillo","IT":"giallo","RU":"жёлтый","ZH":"黄色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beyaz","EN":"white","FR":"blanc","ES":"blanco","IT":"bianco","RU":"белый","ZH":"白色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"siyah","EN":"black","FR":"noir","ES":"negro","IT":"nero","RU":"чёрный","ZH":"黑色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"turuncu","EN":"orange","FR":"orange","ES":"naranja","IT":"arancione","RU":"оранжевый","ZH":"橙色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"pembe","EN":"pink","FR":"rose","ES":"rosa","IT":"rosa","RU":"розовый","ZH":"粉色"}'::jsonb WHERE id='de000001-0003-0001-0000-000000000008';

-- DE Level 4: Food
UPDATE words SET translations='{"TR":"ekmek","EN":"bread","FR":"pain","ES":"pan","IT":"pane","RU":"хлеб","ZH":"面包"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"su","EN":"water","FR":"eau","ES":"agua","IT":"acqua","RU":"вода","ZH":"水"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"kahve","EN":"coffee","FR":"café","ES":"café","IT":"caffè","RU":"кофе","ZH":"咖啡"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"süt","EN":"milk","FR":"lait","ES":"leche","IT":"latte","RU":"молоко","ZH":"牛奶"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"elma","EN":"apple","FR":"pomme","ES":"manzana","IT":"mela","RU":"яблоко","ZH":"苹果"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"peynir","EN":"cheese","FR":"fromage","ES":"queso","IT":"formaggio","RU":"сыр","ZH":"奶酪"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"et","EN":"meat","FR":"viande","ES":"carne","IT":"carne","RU":"мясо","ZH":"肉"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sebze","EN":"vegetable","FR":"légume","ES":"verdura","IT":"verdura","RU":"овощи","ZH":"蔬菜"}'::jsonb WHERE id='de000001-0004-0001-0000-000000000008';

-- DE Level 5: Verbs
UPDATE words SET translations='{"TR":"olmak","EN":"to be","FR":"être","ES":"ser","IT":"essere","RU":"быть","ZH":"是"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"sahip olmak","EN":"to have","FR":"avoir","ES":"tener","IT":"avere","RU":"иметь","ZH":"有"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"gitmek","EN":"to go","FR":"aller","ES":"ir","IT":"andare","RU":"идти","ZH":"去"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"gelmek","EN":"to come","FR":"venir","ES":"venir","IT":"venire","RU":"приходить","ZH":"来"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"yemek","EN":"to eat","FR":"manger","ES":"comer","IT":"mangiare","RU":"есть","ZH":"吃"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"içmek","EN":"to drink","FR":"boire","ES":"beber","IT":"bere","RU":"пить","ZH":"喝"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"uyumak","EN":"to sleep","FR":"dormir","ES":"dormir","IT":"dormire","RU":"спать","ZH":"睡觉"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"çalışmak","EN":"to work","FR":"travailler","ES":"trabajar","IT":"lavorare","RU":"работать","ZH":"工作"}'::jsonb WHERE id='de000001-0005-0001-0000-000000000008';

-- ══════════════════════════════════════════════════════════
-- 🇪🇸 SPANISH COURSE
-- ══════════════════════════════════════════════════════════
UPDATE words SET translations='{"TR":"merhaba","EN":"hello","FR":"bonjour","DE":"Hallo","IT":"ciao","RU":"Привет","ZH":"你好"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"teşekkürler","EN":"thank you","FR":"merci","DE":"danke","IT":"grazie","RU":"спасибо","ZH":"谢谢"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"lütfen","EN":"please","FR":"s il vous plaît","DE":"bitte","IT":"per favore","RU":"пожалуйста","ZH":"请"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"evet","EN":"yes","FR":"oui","DE":"ja","IT":"sì","RU":"да","ZH":"是"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"hayır","EN":"no","FR":"non","DE":"nein","IT":"no","RU":"нет","ZH":"不"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"günaydın","EN":"good morning","FR":"bonjour","DE":"Guten Morgen","IT":"buongiorno","RU":"доброе утро","ZH":"早上好"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"iyi geceler","EN":"good night","FR":"bonne nuit","DE":"Gute Nacht","IT":"buona notte","RU":"спокойной ночи","ZH":"晚安"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"hoşçakal","EN":"goodbye","FR":"au revoir","DE":"auf Wiedersehen","IT":"arrivederci","RU":"до свидания","ZH":"再见"}'::jsonb WHERE id='e5000001-0001-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"bir","EN":"one","FR":"un","DE":"eins","IT":"uno","RU":"один","ZH":"一"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"iki","EN":"two","FR":"deux","DE":"zwei","IT":"due","RU":"два","ZH":"二"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"üç","EN":"three","FR":"trois","DE":"drei","IT":"tre","RU":"три","ZH":"三"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"dört","EN":"four","FR":"quatre","DE":"vier","IT":"quattro","RU":"четыре","ZH":"四"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beş","EN":"five","FR":"cinq","DE":"fünf","IT":"cinque","RU":"пять","ZH":"五"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"altı","EN":"six","FR":"six","DE":"sechs","IT":"sei","RU":"шесть","ZH":"六"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"yedi","EN":"seven","FR":"sept","DE":"sieben","IT":"sette","RU":"семь","ZH":"七"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sekiz","EN":"eight","FR":"huit","DE":"acht","IT":"otto","RU":"восемь","ZH":"八"}'::jsonb WHERE id='e5000001-0002-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"kırmızı","EN":"red","FR":"rouge","DE":"rot","IT":"rosso","RU":"красный","ZH":"红色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"mavi","EN":"blue","FR":"bleu","DE":"blau","IT":"blu","RU":"синий","ZH":"蓝色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"yeşil","EN":"green","FR":"vert","DE":"grün","IT":"verde","RU":"зелёный","ZH":"绿色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"sarı","EN":"yellow","FR":"jaune","DE":"gelb","IT":"giallo","RU":"жёлтый","ZH":"黄色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beyaz","EN":"white","FR":"blanc","DE":"weiß","IT":"bianco","RU":"белый","ZH":"白色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"siyah","EN":"black","FR":"noir","DE":"schwarz","IT":"nero","RU":"чёрный","ZH":"黑色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"turuncu","EN":"orange","FR":"orange","DE":"orange","IT":"arancione","RU":"оранжевый","ZH":"橙色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"pembe","EN":"pink","FR":"rose","DE":"rosa","IT":"rosa","RU":"розовый","ZH":"粉色"}'::jsonb WHERE id='e5000001-0003-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"ekmek","EN":"bread","FR":"pain","DE":"Brot","IT":"pane","RU":"хлеб","ZH":"面包"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"su","EN":"water","FR":"eau","DE":"Wasser","IT":"acqua","RU":"вода","ZH":"水"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"kahve","EN":"coffee","FR":"café","DE":"Kaffee","IT":"caffè","RU":"кофе","ZH":"咖啡"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"süt","EN":"milk","FR":"lait","DE":"Milch","IT":"latte","RU":"молоко","ZH":"牛奶"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"elma","EN":"apple","FR":"pomme","DE":"Apfel","IT":"mela","RU":"яблоко","ZH":"苹果"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"peynir","EN":"cheese","FR":"fromage","DE":"Käse","IT":"formaggio","RU":"сыр","ZH":"奶酪"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"et","EN":"meat","FR":"viande","DE":"Fleisch","IT":"carne","RU":"мясо","ZH":"肉"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sebze","EN":"vegetable","FR":"légume","DE":"Gemüse","IT":"verdura","RU":"овощи","ZH":"蔬菜"}'::jsonb WHERE id='e5000001-0004-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"olmak","EN":"to be","FR":"être","DE":"sein","IT":"essere","RU":"быть","ZH":"是"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"sahip olmak","EN":"to have","FR":"avoir","DE":"haben","IT":"avere","RU":"иметь","ZH":"有"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"gitmek","EN":"to go","FR":"aller","DE":"gehen","IT":"andare","RU":"идти","ZH":"去"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"gelmek","EN":"to come","FR":"venir","DE":"kommen","IT":"venire","RU":"приходить","ZH":"来"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"yemek","EN":"to eat","FR":"manger","DE":"essen","IT":"mangiare","RU":"есть","ZH":"吃"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"içmek","EN":"to drink","FR":"boire","DE":"trinken","IT":"bere","RU":"пить","ZH":"喝"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"uyumak","EN":"to sleep","FR":"dormir","DE":"schlafen","IT":"dormire","RU":"спать","ZH":"睡觉"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"çalışmak","EN":"to work","FR":"travailler","DE":"arbeiten","IT":"lavorare","RU":"работать","ZH":"工作"}'::jsonb WHERE id='e5000001-0005-0001-0000-000000000008';

-- ══════════════════════════════════════════════════════════
-- 🇮🇹 ITALIAN COURSE
-- ══════════════════════════════════════════════════════════
UPDATE words SET translations='{"TR":"merhaba","EN":"hello","FR":"bonjour","DE":"Hallo","ES":"hola","RU":"Привет","ZH":"你好"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"teşekkürler","EN":"thank you","FR":"merci","DE":"danke","ES":"gracias","RU":"спасибо","ZH":"谢谢"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"lütfen","EN":"please","FR":"s il vous plaît","DE":"bitte","ES":"por favor","RU":"пожалуйста","ZH":"请"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"evet","EN":"yes","FR":"oui","DE":"ja","ES":"sí","RU":"да","ZH":"是"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"hayır","EN":"no","FR":"non","DE":"nein","ES":"no","RU":"нет","ZH":"不"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"günaydın","EN":"good morning","FR":"bonjour","DE":"Guten Morgen","ES":"buenos días","RU":"доброе утро","ZH":"早上好"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"iyi akşamlar","EN":"good evening","FR":"bonsoir","DE":"Guten Abend","ES":"buenas noches","RU":"добрый вечер","ZH":"晚上好"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"hoşçakal","EN":"goodbye","FR":"au revoir","DE":"auf Wiedersehen","ES":"adiós","RU":"до свидания","ZH":"再见"}'::jsonb WHERE id='17000001-0001-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"bir","EN":"one","FR":"un","DE":"eins","ES":"uno","RU":"один","ZH":"一"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"iki","EN":"two","FR":"deux","DE":"zwei","ES":"dos","RU":"два","ZH":"二"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"üç","EN":"three","FR":"trois","DE":"drei","ES":"tres","RU":"три","ZH":"三"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"dört","EN":"four","FR":"quatre","DE":"vier","ES":"cuatro","RU":"четыре","ZH":"四"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beş","EN":"five","FR":"cinq","DE":"fünf","ES":"cinco","RU":"пять","ZH":"五"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"altı","EN":"six","FR":"six","DE":"sechs","ES":"seis","RU":"шесть","ZH":"六"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"yedi","EN":"seven","FR":"sept","DE":"sieben","ES":"siete","RU":"семь","ZH":"七"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sekiz","EN":"eight","FR":"huit","DE":"acht","ES":"ocho","RU":"восемь","ZH":"八"}'::jsonb WHERE id='17000001-0002-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"kırmızı","EN":"red","FR":"rouge","DE":"rot","ES":"rojo","RU":"красный","ZH":"红色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"mavi","EN":"blue","FR":"bleu","DE":"blau","ES":"azul","RU":"синий","ZH":"蓝色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"yeşil","EN":"green","FR":"vert","DE":"grün","ES":"verde","RU":"зелёный","ZH":"绿色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"sarı","EN":"yellow","FR":"jaune","DE":"gelb","ES":"amarillo","RU":"жёлтый","ZH":"黄色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beyaz","EN":"white","FR":"blanc","DE":"weiß","ES":"blanco","RU":"белый","ZH":"白色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"siyah","EN":"black","FR":"noir","DE":"schwarz","ES":"negro","RU":"чёрный","ZH":"黑色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"turuncu","EN":"orange","FR":"orange","DE":"orange","ES":"naranja","RU":"оранжевый","ZH":"橙色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"pembe","EN":"pink","FR":"rose","DE":"rosa","ES":"rosa","RU":"розовый","ZH":"粉色"}'::jsonb WHERE id='17000001-0003-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"ekmek","EN":"bread","FR":"pain","DE":"Brot","ES":"pan","RU":"хлеб","ZH":"面包"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"su","EN":"water","FR":"eau","DE":"Wasser","ES":"agua","RU":"вода","ZH":"水"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"kahve","EN":"coffee","FR":"café","DE":"Kaffee","ES":"café","RU":"кофе","ZH":"咖啡"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"süt","EN":"milk","FR":"lait","DE":"Milch","ES":"leche","RU":"молоко","ZH":"牛奶"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"elma","EN":"apple","FR":"pomme","DE":"Apfel","ES":"manzana","RU":"яблоко","ZH":"苹果"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"peynir","EN":"cheese","FR":"fromage","DE":"Käse","ES":"queso","RU":"сыр","ZH":"奶酪"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"et","EN":"meat","FR":"viande","DE":"Fleisch","ES":"carne","RU":"мясо","ZH":"肉"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sebze","EN":"vegetable","FR":"légume","DE":"Gemüse","ES":"verdura","RU":"овощи","ZH":"蔬菜"}'::jsonb WHERE id='17000001-0004-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"olmak","EN":"to be","FR":"être","DE":"sein","ES":"ser","RU":"быть","ZH":"是"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"sahip olmak","EN":"to have","FR":"avoir","DE":"haben","ES":"tener","RU":"иметь","ZH":"有"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"gitmek","EN":"to go","FR":"aller","DE":"gehen","ES":"ir","RU":"идти","ZH":"去"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"gelmek","EN":"to come","FR":"venir","DE":"kommen","ES":"venir","RU":"приходить","ZH":"来"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"yemek","EN":"to eat","FR":"manger","DE":"essen","ES":"comer","RU":"есть","ZH":"吃"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"içmek","EN":"to drink","FR":"boire","DE":"trinken","ES":"beber","RU":"пить","ZH":"喝"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"uyumak","EN":"to sleep","FR":"dormir","DE":"schlafen","ES":"dormir","RU":"спать","ZH":"睡觉"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"çalışmak","EN":"to work","FR":"travailler","DE":"arbeiten","ES":"trabajar","RU":"работать","ZH":"工作"}'::jsonb WHERE id='17000001-0005-0001-0000-000000000008';

-- ══════════════════════════════════════════════════════════
-- 🇷🇺 RUSSIAN COURSE
-- ══════════════════════════════════════════════════════════
UPDATE words SET translations='{"TR":"merhaba","EN":"hello","FR":"bonjour","DE":"Hallo","ES":"hola","IT":"ciao","ZH":"你好"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"teşekkürler","EN":"thank you","FR":"merci","DE":"danke","ES":"gracias","IT":"grazie","ZH":"谢谢"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"lütfen","EN":"please","FR":"s il vous plaît","DE":"bitte","ES":"por favor","IT":"per favore","ZH":"请"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"evet","EN":"yes","FR":"oui","DE":"ja","ES":"sí","IT":"sì","ZH":"是"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"hayır","EN":"no","FR":"non","DE":"nein","ES":"no","IT":"no","ZH":"不"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"günaydın","EN":"good morning","FR":"bonjour","DE":"Guten Morgen","ES":"buenos días","IT":"buongiorno","ZH":"早上好"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"iyi akşamlar","EN":"good evening","FR":"bonsoir","DE":"Guten Abend","ES":"buenas noches","IT":"buona sera","ZH":"晚上好"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"hoşçakal","EN":"goodbye","FR":"au revoir","DE":"auf Wiedersehen","ES":"adiós","IT":"arrivederci","ZH":"再见"}'::jsonb WHERE id='04000001-0001-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"bir","EN":"one","FR":"un","DE":"eins","ES":"uno","IT":"uno","ZH":"一"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"iki","EN":"two","FR":"deux","DE":"zwei","ES":"dos","IT":"due","ZH":"二"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"üç","EN":"three","FR":"trois","DE":"drei","ES":"tres","IT":"tre","ZH":"三"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"dört","EN":"four","FR":"quatre","DE":"vier","ES":"cuatro","IT":"quattro","ZH":"四"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beş","EN":"five","FR":"cinq","DE":"fünf","ES":"cinco","IT":"cinque","ZH":"五"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"altı","EN":"six","FR":"six","DE":"sechs","ES":"seis","IT":"sei","ZH":"六"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"yedi","EN":"seven","FR":"sept","DE":"sieben","ES":"siete","IT":"sette","ZH":"七"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sekiz","EN":"eight","FR":"huit","DE":"acht","ES":"ocho","IT":"otto","ZH":"八"}'::jsonb WHERE id='04000001-0002-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"kırmızı","EN":"red","FR":"rouge","DE":"rot","ES":"rojo","IT":"rosso","ZH":"红色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"mavi","EN":"blue","FR":"bleu","DE":"blau","ES":"azul","IT":"blu","ZH":"蓝色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"yeşil","EN":"green","FR":"vert","DE":"grün","ES":"verde","IT":"verde","ZH":"绿色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"sarı","EN":"yellow","FR":"jaune","DE":"gelb","ES":"amarillo","IT":"giallo","ZH":"黄色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beyaz","EN":"white","FR":"blanc","DE":"weiß","ES":"blanco","IT":"bianco","ZH":"白色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"siyah","EN":"black","FR":"noir","DE":"schwarz","ES":"negro","IT":"nero","ZH":"黑色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"turuncu","EN":"orange","FR":"orange","DE":"orange","ES":"naranja","IT":"arancione","ZH":"橙色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"pembe","EN":"pink","FR":"rose","DE":"rosa","ES":"rosa","IT":"rosa","ZH":"粉色"}'::jsonb WHERE id='04000001-0003-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"ekmek","EN":"bread","FR":"pain","DE":"Brot","ES":"pan","IT":"pane","ZH":"面包"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"su","EN":"water","FR":"eau","DE":"Wasser","ES":"agua","IT":"acqua","ZH":"水"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"kahve","EN":"coffee","FR":"café","DE":"Kaffee","ES":"café","IT":"caffè","ZH":"咖啡"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"süt","EN":"milk","FR":"lait","DE":"Milch","ES":"leche","IT":"latte","ZH":"牛奶"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"elma","EN":"apple","FR":"pomme","DE":"Apfel","ES":"manzana","IT":"mela","ZH":"苹果"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"peynir","EN":"cheese","FR":"fromage","DE":"Käse","ES":"queso","IT":"formaggio","ZH":"奶酪"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"et","EN":"meat","FR":"viande","DE":"Fleisch","ES":"carne","IT":"carne","ZH":"肉"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sebze","EN":"vegetable","FR":"légume","DE":"Gemüse","ES":"verdura","IT":"verdura","ZH":"蔬菜"}'::jsonb WHERE id='04000001-0004-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"olmak","EN":"to be","FR":"être","DE":"sein","ES":"ser","IT":"essere","ZH":"是"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"sahip olmak","EN":"to have","FR":"avoir","DE":"haben","ES":"tener","IT":"avere","ZH":"有"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"gitmek","EN":"to go","FR":"aller","DE":"gehen","ES":"ir","IT":"andare","ZH":"去"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"gelmek","EN":"to come","FR":"venir","DE":"kommen","ES":"venir","IT":"venire","ZH":"来"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"yemek","EN":"to eat","FR":"manger","DE":"essen","ES":"comer","IT":"mangiare","ZH":"吃"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"içmek","EN":"to drink","FR":"boire","DE":"trinken","ES":"beber","IT":"bere","ZH":"喝"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"uyumak","EN":"to sleep","FR":"dormir","DE":"schlafen","ES":"dormir","IT":"dormire","ZH":"睡觉"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"çalışmak","EN":"to work","FR":"travailler","DE":"arbeiten","ES":"trabajar","IT":"lavorare","ZH":"工作"}'::jsonb WHERE id='04000001-0005-0001-0000-000000000008';

-- ══════════════════════════════════════════════════════════
-- 🇨🇳 CHINESE COURSE
-- ══════════════════════════════════════════════════════════
UPDATE words SET translations='{"TR":"merhaba","EN":"hello","FR":"bonjour","DE":"Hallo","ES":"hola","IT":"ciao","RU":"Привет"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"teşekkürler","EN":"thank you","FR":"merci","DE":"danke","ES":"gracias","IT":"grazie","RU":"спасибо"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"lütfen","EN":"please","FR":"s il vous plaît","DE":"bitte","ES":"por favor","IT":"per favore","RU":"пожалуйста"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"evet","EN":"yes","FR":"oui","DE":"ja","ES":"sí","IT":"sì","RU":"да"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"hayır","EN":"no","FR":"non","DE":"nein","ES":"no","IT":"no","RU":"нет"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"günaydın","EN":"good morning","FR":"bonjour","DE":"Guten Morgen","ES":"buenos días","IT":"buongiorno","RU":"доброе утро"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"iyi akşamlar","EN":"good evening","FR":"bonsoir","DE":"Guten Abend","ES":"buenas noches","IT":"buona sera","RU":"добрый вечер"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"hoşçakal","EN":"goodbye","FR":"au revoir","DE":"auf Wiedersehen","ES":"adiós","IT":"arrivederci","RU":"до свидания"}'::jsonb WHERE id='24000001-0001-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"bir","EN":"one","FR":"un","DE":"eins","ES":"uno","IT":"uno","RU":"один"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"iki","EN":"two","FR":"deux","DE":"zwei","ES":"dos","IT":"due","RU":"два"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"üç","EN":"three","FR":"trois","DE":"drei","ES":"tres","IT":"tre","RU":"три"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"dört","EN":"four","FR":"quatre","DE":"vier","ES":"cuatro","IT":"quattro","RU":"четыре"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beş","EN":"five","FR":"cinq","DE":"fünf","ES":"cinco","IT":"cinque","RU":"пять"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"altı","EN":"six","FR":"six","DE":"sechs","ES":"seis","IT":"sei","RU":"шесть"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"yedi","EN":"seven","FR":"sept","DE":"sieben","ES":"siete","IT":"sette","RU":"семь"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sekiz","EN":"eight","FR":"huit","DE":"acht","ES":"ocho","IT":"otto","RU":"восемь"}'::jsonb WHERE id='24000001-0002-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"kırmızı","EN":"red","FR":"rouge","DE":"rot","ES":"rojo","IT":"rosso","RU":"красный"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"mavi","EN":"blue","FR":"bleu","DE":"blau","ES":"azul","IT":"blu","RU":"синий"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"yeşil","EN":"green","FR":"vert","DE":"grün","ES":"verde","IT":"verde","RU":"зелёный"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"sarı","EN":"yellow","FR":"jaune","DE":"gelb","ES":"amarillo","IT":"giallo","RU":"жёлтый"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"beyaz","EN":"white","FR":"blanc","DE":"weiß","ES":"blanco","IT":"bianco","RU":"белый"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"siyah","EN":"black","FR":"noir","DE":"schwarz","ES":"negro","IT":"nero","RU":"чёрный"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"turuncu","EN":"orange","FR":"orange","DE":"orange","ES":"naranja","IT":"arancione","RU":"оранжевый"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"pembe","EN":"pink","FR":"rose","DE":"rosa","ES":"rosa","IT":"rosa","RU":"розовый"}'::jsonb WHERE id='24000001-0003-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"ekmek","EN":"bread","FR":"pain","DE":"Brot","ES":"pan","IT":"pane","RU":"хлеб"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"su","EN":"water","FR":"eau","DE":"Wasser","ES":"agua","IT":"acqua","RU":"вода"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"kahve","EN":"coffee","FR":"café","DE":"Kaffee","ES":"café","IT":"caffè","RU":"кофе"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"süt","EN":"milk","FR":"lait","DE":"Milch","ES":"leche","IT":"latte","RU":"молоко"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"elma","EN":"apple","FR":"pomme","DE":"Apfel","ES":"manzana","IT":"mela","RU":"яблоко"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"peynir","EN":"cheese","FR":"fromage","DE":"Käse","ES":"queso","IT":"formaggio","RU":"сыр"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"et","EN":"meat","FR":"viande","DE":"Fleisch","ES":"carne","IT":"carne","RU":"мясо"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"sebze","EN":"vegetable","FR":"légume","DE":"Gemüse","ES":"verdura","IT":"verdura","RU":"овощи"}'::jsonb WHERE id='24000001-0004-0001-0000-000000000008';
UPDATE words SET translations='{"TR":"olmak","EN":"to be","FR":"être","DE":"sein","ES":"ser","IT":"essere","RU":"быть"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000001';
UPDATE words SET translations='{"TR":"sahip olmak","EN":"to have","FR":"avoir","DE":"haben","ES":"tener","IT":"avere","RU":"иметь"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000002';
UPDATE words SET translations='{"TR":"gitmek","EN":"to go","FR":"aller","DE":"gehen","ES":"ir","IT":"andare","RU":"идти"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000003';
UPDATE words SET translations='{"TR":"gelmek","EN":"to come","FR":"venir","DE":"kommen","ES":"venir","IT":"venire","RU":"приходить"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000004';
UPDATE words SET translations='{"TR":"yemek","EN":"to eat","FR":"manger","DE":"essen","ES":"comer","IT":"mangiare","RU":"есть"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000005';
UPDATE words SET translations='{"TR":"içmek","EN":"to drink","FR":"boire","DE":"trinken","ES":"beber","IT":"bere","RU":"пить"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000006';
UPDATE words SET translations='{"TR":"uyumak","EN":"to sleep","FR":"dormir","DE":"schlafen","ES":"dormir","IT":"dormire","RU":"спать"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000007';
UPDATE words SET translations='{"TR":"çalışmak","EN":"to work","FR":"travailler","DE":"arbeiten","ES":"trabajar","IT":"lavorare","RU":"работать"}'::jsonb WHERE id='24000001-0005-0001-0000-000000000008';
