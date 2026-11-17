<?php
// Resumen diario por correo (cron del hosting, p. ej. 20:00 Lima): php ~/propuestas-tracking/resumen.php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
$dir = __DIR__; $cfg = require "$dir/config.php";
if (!is_file("$dir/visitas.sqlite")) exit;
$db = new PDO("sqlite:$dir/visitas.sqlite");
$desde = gmdate('Y-m-d\TH:i:s\Z', time() - 86400);
$q = $db->prepare('SELECT * FROM sesiones WHERE inicio > ? ORDER BY host, inicio'); $q->execute([$desde]);
$filas = $q->fetchAll(PDO::FETCH_ASSOC);
$tot = $db->query('SELECT host, COUNT(*) c, COUNT(DISTINCT v) p, MAX(inicio) u FROM sesiones GROUP BY host')->fetchAll(PDO::FETCH_ASSOC);
$tz = new DateTimeZone('America/Lima'); $h = fn($i) => (new DateTime($i))->setTimezone($tz)->format('d/m H:i');
$txt = "Resumen de lecturas de tus propuestas (últimas 24 horas)\n\n";
if (!$filas) $txt .= "Nadie abrió una propuesta en las últimas 24 horas.\n";
foreach ($filas as $f) {
  $nom = $cfg['propuestas'][$f['host']] ?? $f['host'];
  $quien = $f['codigo'] ? ($cfg['codigos'][$f['codigo']] ?? $f['codigo']) : 'sin código';
  $txt .= "- {$h($f['inicio'])} · $nom · $quien · paso {$f['max']} de {$f['n']} · " . intdiv((int)$f['seg'], 60) . " min " . ((int)$f['seg'] % 60) . " s · audios: {$f['audios']}\n";
}
$hoy = (new DateTime('now', $tz))->format('Y-m-d');
try { $tp = $db->prepare('SELECT tipo FROM topes WHERE dia = ?'); $tp->execute([$hoy]); $tp = $tp->fetchAll(PDO::FETCH_COLUMN); } catch (Throwable $e) { $tp = []; }
foreach ($tp as $t) $txt .= "\nAviso: hoy se alcanzó el tope de " . ($t === 'correos_dia' ? 'correos por día' : 'visitas nuevas por hora') . "; lo que pasó después no se registró ni se avisó.\n";
$txt .= "\nTotales desde el inicio:\n";
foreach ($tot as $t) $txt .= "- " . ($cfg['propuestas'][$t['host']] ?? $t['host']) . ": {$t['c']} visitas de {$t['p']} navegadores; la última el {$h($t['u'])}\n";
$de = $cfg['de'] ?? 'propuestas@innodite.com';
mail($cfg['para'], '=?UTF-8?B?' . base64_encode('📊 Lecturas de tus propuestas: ' . count($filas) . ' en 24 h') . '?=', $txt,
  "From: Propuestas Innodite <$de>\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Language: es", "-f$de");
