#!/usr/bin/env bash
# Ejecutar en el hosting después del git pull, desde la carpeta de la propuesta:  bash instalar.sh
# Deja listo el seguimiento de lectura de ESTA propuesta. Se puede repetir sin problema.
set -euo pipefail
cd "$(dirname "$0")"
D="$HOME/propuestas-tracking"
command -v php >/dev/null || { echo "ERROR: no encuentro php"; exit 1; }
[ -f seguimiento.json ] || { echo "ERROR: falta seguimiento.json en esta carpeta"; exit 1; }
mkdir -p "$D" && chmod 700 "$D"

# 1) Configuración común (solo la primera vez)
if [ ! -f "$D/config.php" ]; then
  SAL=$(php -r 'echo bin2hex(random_bytes(16));')
  cat > "$D/config.php" <<PHP
<?php
return [
  'para' => 'afilgueira200@gmail.com',
  'de' => 'propuestas@innodite.com',
  'sal' => '$SAL',
  'max_correos_dia' => 20,
  'max_sesiones_hora' => 30,
  'minimo' => [],
  'propuestas' => [],
  'codigos' => [],
];
PHP
  echo "· config.php creado"
fi
chmod 600 "$D/config.php"

# 2) Registrar esta propuesta (nombre, códigos y modo mínimo) en la configuración
TMP=$(mktemp); cat > "$TMP" <<'PHP'
<?php
$f = getenv("HOME")."/propuestas-tracking/config.php"; $c = require $f;
$s = json_decode(file_get_contents("seguimiento.json"), true) or exit("ERROR: seguimiento.json inválido\n");
$c["propuestas"][$s["host"]] = $s["nombre"];
foreach ($s["codigos"] ?? [] as $k => $v) $c["codigos"][$k] = $v;
$c["minimo"] = array_values(array_unique(array_merge(array_diff($c["minimo"] ?? [], [$s["host"]]), !empty($s["minimo"]) ? [$s["host"]] : [])));
file_put_contents($f, "<?php\nreturn " . var_export($c, true) . ";\n", LOCK_EX);
echo "· registrada: {$s["nombre"]} ({$s["host"]})" . (!empty($s["minimo"]) ? ", modo mínimo" : "") . "\n";
PHP
php "$TMP"; rm -f "$TMP"

# 3) Resumen diario
cp resumen.php "$D/resumen.php" && chmod 600 "$D/resumen.php"
if ! command -v crontab >/dev/null; then
  echo "· AVISO: sin crontab; agrega en cPanel → Cron Jobs: 0 1 * * * php $D/resumen.php (01:00 UTC = 20:00 Lima)"
elif ! crontab -l 2>/dev/null | grep -q 'propuestas-tracking/resumen.php'; then
  OFF=$(date +%z); SIGNO=${OFF:0:1}; HH=$((10#${OFF:1:2}))
  [ "$SIGNO" = "-" ] && HH=$((-HH))
  HORA=$(( (20 + 5 + HH + 24) % 24 ))   # 20:00 en Lima (UTC-5) expresado en la hora del servidor
  (crontab -l 2>/dev/null; echo "0 $HORA * * * php $D/resumen.php") | crontab -
  echo "· cron del resumen agregado: todos los días a las $HORA:00 del servidor (20:00 Lima)"
else
  echo "· cron del resumen ya existía: $(crontab -l | grep 'propuestas-tracking/resumen.php' | head -1)"
fi

# 4) Comprobaciones
php -l t.php >/dev/null && echo "· t.php sin errores"
php -r 'new PDO("sqlite::memory:");' && echo "· pdo_sqlite disponible"
HOST=$(php -r '$s=json_decode(file_get_contents("seguimiento.json"),true);echo $s["host"];')
for p in t.php seguimiento.json instalar.sh resumen.php; do
  printf "· https://%s/%s → %s\n" "$HOST" "$p" "$(curl -s -o /dev/null -w '%{http_code}' "https://$HOST/$p")"
done
echo "Esperado: t.php 405 y los otros 403 o 404. Listo."
