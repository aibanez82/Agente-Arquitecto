// Prueba de solo lectura: api.php m=fareceipt (mismo endpoint/credencial que ya usa
// generar_link_pasarela en qualitas/services.py de HYL-WAI) para 4 pólizas con
// estado conocido en conciliacion_pagos. Objetivo: validar si sirve de cruce
// para el Agente Conciliación.
const { execSync } = require('child_process');
const https = require('https');

const wptoken = execSync('heroku config:get QUALITAS_WPTOKEN -a hyl-wai-production').toString().trim();

const casos = [
  ['PAGADO', '7620099601'],
  ['PENDIENTE', '7620099716'],
  ['VENCIDO', '7620098627'],
  ['CANCELADO', '7620098974'],
];

function post(body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = https.request('https://pagos.qualitas.com.mx/api.php', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0',
        'Content-Length': Buffer.byteLength(data),
      },
      rejectUnauthorized: false,
      timeout: 20000,
    }, res => {
      let out = '';
      res.on('data', d => out += d);
      res.on('end', () => resolve({ status: res.statusCode, body: out }));
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
    req.write(data);
    req.end();
  });
}

(async () => {
  for (const [estado, poliza] of casos) {
    console.log(`===== ${estado} — ${poliza} =====`);
    try {
      const r = await post({ wptoken, m: 'fareceipt', poliza });
      console.log(`HTTP ${r.status}:`, r.body.slice(0, 2000));
    } catch (e) {
      console.log('ERROR:', e.message);
    }
    console.log();
  }
})();
