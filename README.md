Bastion - офисный фильтр сайтов
--
Зависимости: `iptables squid ipset bind-utils apache squidanalyzer polkit sakura`

Трёхуровневая фильтрация HTTP/HTTPS:
+ Squid + Чёрные/Белые списки сайтов + VIP-пользователи
+ IPTables + IPSet (блокировка хост=несколько IP) + словарная фильтрация
+ SquidAnalyzer - анализатор логов интренет-соединений

Физически состоит из двух частей:
+ GUI (rpm-пакет, подтягивает все нужные зависимости)
+ архив файлов конфигураций (распаковывается вручную etc->etc)

Настройте WAN/LAN на компьютере, выполняющем роль шлюза и запустите Bastion. Укажите имена интерфейсов, локальную сеть и нажмите кнопку `Новый сертификат`. После того, как сертификат будет создан, установите его в браузерах клиентов. Для моментального применения правил блокировки из списков или первого старта нажмите кнопку `Рестарт`.

Примечание: Bastion может быть настроен/запущен и без GUI (только скрипты). Сделано и протестировано в Mageia-8.
