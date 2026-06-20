const urlYahooGold = 'https://query1.finance.yahoo.com/v8/finance/chart/GC=F';
const urlYahooSilver = 'https://query1.finance.yahoo.com/v8/finance/chart/SI=F';

async function testYahoo() {
  console.log('\n=== Test 4: Yahoo Finance Gold ===');
  try {
    const r = await fetch(urlYahooGold);
    console.log('Status:', r.status);
    const data = await r.json();
    const price = data.chart.result[0].meta.regularMarketPrice;
    console.log('Yahoo Gold Price (USD/oz):', price);
  } catch(e) { console.log('Error:', e.message); }
}

testYahoo();
