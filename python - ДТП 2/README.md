Работа с данными «Карты ДТП» — некоммерческого проекта, посвящённого проблеме дорожно-транспортных происшествий в России. Цель проекта — повысить безопасность на дорогах.
«Карта ДТП» помогает выявлять реальные причины ДТП, оценивать уровень развития инфраструктуры, а также разрабатывать качественные решения и программы по повышению безопасности на улицах и дорогах. Заказчик хочет собирать данные более высокого качества и ожидает от вас рекомендаций: на какие проблемы или особенности обратить внимание.<br>

**Задачи проекта**<br>
В проекте проведена проверка, встречаются ли в данных дубликаты и пропуски. Это поможет заказчикам собирать более качественные данные.<br>
Также решены следующие вопросы:<br>
1. как менялось число ДТП по временным промежуткам;
2. различается ли число ДТП для групп водителей с разным стажем.<br>

**Описание данных**<br>
Датасеты https://code.s3.yandex.net/datasets/Kirovskaya_oblast.csv, https://code.s3.yandex.net/datasets/Moscowskaya_oblast.csv содержат информацию о ДТП:<br>
geometry.coordinates — координаты ДТП;<br>
id — идентификатор ДТП;<br>
properties.tags — тег происшествия;<br>
properties.light — освещённость;<br>
properties.point.lat — широта;<br>
properties.point.long — долгота;<br>
properties.nearby — ближайшие объекты;<br>
properties.region — регион;<br>
properties.scheme — схема ДТП;<br>
properties.address — ближайший адрес;<br>
properties.weather — погода;<br>
properties.category — категория ДТП;<br>
properties.datetime — дата и время ДТП;<br>
properties.injured_count — число пострадавших;<br>
properties.parent_region — область;<br>
properties.road_conditions — состояние покрытия;<br>
properties.participants_count — число участников;<br>
properties.participant_categories — категории участников.<br>

Датасеты https://code.s3.yandex.net/datasets/Moscowskaya_oblast_participiants.csv, https://code.s3.yandex.net/datasets/Kirovskaya_oblast_participiants.csv хранят сведения об участниках ДТП:<br>
role — роль;<br>
gender — пол;<br>
violations — какие правила дорожного движения были нарушены конкретным участником;<br>
health_status — состояние здоровья после ДТП;<br>
years_of_driving_experience — число лет опыта;<br>
id — идентификатор ДТП.<br>

Датасеты https://code.s3.yandex.net/datasets/Kirovskaya_oblast_vehicles.csv, https://code.s3.yandex.net/datasets/Moscowskaya_oblast_vehicles.csv хранят сведения о транспортных средствах:<br>
year — год выпуска;<br>
brand — марка транспортного средства;<br>
color — цвет;<br>
model — модель;<br>
category — категория;<br>
id — идентификатор ДТП.
