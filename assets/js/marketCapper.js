// Let's go data whaling....

const API_URL      = 'https://api.coingecko.com/api/v3/';
const API_CMD      = 'coins/markets';
let   DENOMINATION = 'usd'
const API_QUERY    = '?vs_currency=';
let   PERIOD       = '24h';
const API_PARAMS   = ['&order=market_cap_desc',
                    '&per_page=100', 
                    '&page=1',
                    '&sparkline=false',
                    '&price_change_percentage='];

let coinsDB = [];       // singleton front-end database
let lastSortedBy = '';  // state machine: reverse if repeated clicks.
let totalMarketCap = 0; // Global to allow market dominance calculation.
let totalBasket = 0;
let totalVolume = 0

function url() {
    // assemble the URL
    console.log('assmbling url:')
    const gogetem = [API_URL, API_CMD, API_QUERY, DENOMINATION,
        API_PARAMS.join(''),PERIOD].join('');
    console.log(gogetem);
    return gogetem;
};

class Coin{ // adapter
    constructor(dataObj){
        // console.log('Minting coin data:' + dataObj.name);
        this.id                                     = dataObj.id;
        this.symbol                                 = dataObj.symbol;
        this.name                                   = dataObj.name;
        this.image                                  = dataObj.image;
        this.current_price                          = dataObj.current_price;
        this.market_cap                             = dataObj.market_cap;
        this.market_cap_rank                        = dataObj.market_cap_rank;
        this.total_volume                           = dataObj.total_volume;
        this.high_24h                               = dataObj.high_24h;
        this.low_24h                                = dataObj.low_24h;
        this.price_change_24h                       = dataObj.price_change_24h; 
        this.price_change_percentage_24h            = dataObj.price_change_percentage_24h;
        this.market_cap_change_24h                  = dataObj.market_cap_change_24h;
        this.market_cap_change_percentage_24h       = dataObj.market_cap_change_percentage_24h;
        this.circulating_supply                     = dataObj.circulating_supply;
        this.total_supply                           = dataObj.total_supply;
        this.ath                                    = dataObj.ath;
        this.ath_change_percentage                  = dataObj.ath_change_percentage;
        this.ath_date                               = dataObj.ath_date;
        this.atl                                    = dataObj.atl;
        this.atl_change_percentage                  = dataObj.atl_change_percentage; 
        this.atl_date                               = dataObj.atl_date;
        this.roi                                    = dataObj.roi;
        this.last_updated                           = dataObj.last_updated;
        this['price_change_percentage_' + PERIOD + '_in_currency'] = 
            dataObj['price_change_percentage_' + PERIOD + '_in_currency']; // periods vary
    } // default constructor
    toString(){
        // convert to an html/bootstrap <tr>
        // console.log('Creating table row for: ' + this.name);
        let dirTag = 'sidewaysclass';
        let htmlstr = '';
            htmlstr += '<tr>\n';
            htmlstr += '    <td><b>' + this.market_cap_rank + '</b></td>\n';
            htmlstr += '    <td class="text-left"><img src="' + this.image + 
                '" class="coinicon">    <b>' + this.name + '</b></td>\n';
            htmlstr += '    <td><b>' + this.market_cap.toLocaleString() + 
                '</b> <i>{' + (100*this.market_cap/totalMarketCap).toPrecision(3) + '%}</i></td>\n';
            if ((DENOMINATION == 'usd') | (DENOMINATION =='eur')) { // display in currency to nearest penny.
                htmlstr += '    <td><b>' + this.current_price.toFixed(2) + '</b></td>\n';
            } else { // display in tokens to 3 significant figures.
                htmlstr += '    <td><b>' + this.current_price.toPrecision(3) + '</b></td>\n';
            };
            htmlstr += '    <td><b>' + this.total_volume.toLocaleString() + 
                '</b> <i>{' + (100*this.total_volume/totalVolume).toPrecision(3) + '%}</i></td>\n';
            htmlstr += '    <td><b>' + this.circulating_supply.toLocaleString() + '</b> ' +
                this.symbol +'</td>\n';
            if (this['price_change_percentage_' + PERIOD + '_in_currency'] > 0){
                dirTag = 'upperclass';
            } else if (this['price_change_percentage_' + PERIOD + '_in_currency'] < 0) {
                dirTag = 'lowerclass';
            }; // label direction
            if (this['price_change_percentage_' + PERIOD + '_in_currency']){
                htmlstr += "    <td class='" + dirTag + "'><b>" + 
                    this['price_change_percentage_' + PERIOD + '_in_currency'].toPrecision(3) + '%</b></td>\n';
            } else {
                htmlstr += "    <td class='sidewaysclass'>0.00%</td>\n"; // null from API.
            };
            
            //htmlstr += '    <td>' + '[Purdy Picture]' + '</td>\n';
            htmlstr += '</tr>\n';
        return htmlstr;
    } // totr()
} // class Coin

async function importMarketData() {
    // import data
    console.log('Loading table data...');
    try {
        const response = await fetch(url());
        let coins = await response.json();
        while(coinsDB.length > 0){
            coinsDB.pop();
        } // Destroy previous data.
        totalMarketCap = 0; // Recalculate
        totalBasket = 0; // Recalculate
        totalVolume = 0;
        while(coins.length > 0) {
            coinsDB.push(new Coin(coins.pop()));
            totalMarketCap += coinsDB[coinsDB.length -1].market_cap;
            totalBasket +=    coinsDB[coinsDB.length -1].current_price;
            totalVolume +=    coinsDB[coinsDB.length -1].total_volume;
        }; // cast array to Coin class.
        coinsDB = coinsDB.reverse(); // Undo FILO
        lastSortedBy = 'market_cap_rank'; 
    } catch(error) {
        console.log('importMarketData() failure: ' + error);
    }; // try-catch
}; // importMarketData()

async function displayMarketCapData(){
    // Sum total market cap and index value.
    $('#totalMarketCapText').text('Top 100 Market cap: ' +
         totalMarketCap.toLocaleString() + ' (' + DENOMINATION + ')');
    $('#top100Index').text('Crypto100 Index: ' + 
        totalBasket.toLocaleString() + ' (' + DENOMINATION + ')');
    $('#totalTradingVolume').text('Total 24-hour "volume" traded: ' + 
        totalVolume.toLocaleString() + ' (' + DENOMINATION + ')');
};

async function displayMarketData(){
    // Push market data to table
    console.log('Displaying table data.');
    try {
        await importMarketData();
        displayMarketCapData(); 
        $('.tabletag').html(coinsDB.toString());
    } catch (error) {
        console.log('displayMarketData() failure: ' + error);
    } // try-catch

}; // displayMarketData()

async function updateDenomination(denomString){
    console.log('Updating denomination to ' + denomString);
    DENOMINATION = denomString;
    displayMarketData();
    $('#priceButton').text('Price (' + DENOMINATION + ')');
    $('#marketCapButton').text('Market Cap (' + DENOMINATION +') {dom}');
    $('#volumeButton').text('Volume (' + DENOMINATION + '/24h) {dom}');
} // updateDenomination()

async function updatePeriod(periodString){
    console.log('Updating period to ' + periodString);
    PERIOD = periodString;
    displayMarketData();
    $('#volumeButton').text('Volume (' + DENOMINATION + '/24h) {dom}');
    $('#periodButton').text('Change (' + PERIOD + ')');
} // updateDenomination()

async function sortby(field){
    // Sort coinsDB array by given Coin class field name
    console.log('Sorting list by: ' + field + '...');
    try {
        switch(field){
            case 'name': // sort by alpha
                coinsDB = coinsDB.sort(function(a,b){
                    if (b.name.toLowerCase() > a.name.toLowerCase()) {
                        return -1;
                    }
                    if (a.name.toLowerCase() > b.name.toLowerCase()) {
                        return 1;
                    }
                    return 0;
                }); // compare function, sort()
                break;
            default: // sort by number
                coinsDB = coinsDB.sort(function(a,b){
                    return b[field] - a[field];
                }); // compare function, sort()
        } // switch()
        if (lastSortedBy == field){
            // console.log('Toggling click detected.  Reversing order.')
            coinsDB = coinsDB.reverse();
            lastSortedBy = ''; // un-toggle state
        } else {
            // console.log('Sorting complete.  Last sorted by: ' + lastSortedBy);
            lastSortedBy = field;  // update state.
        } // Sorting order check
        // console.log('Redrawing table...');
        $('.tabletag').html(coinsDB.toString());
        // console.log('Redraw complete.')
    } catch (error) {
        console.log('sortby() failure: ' + error); 
    } // try-catch
    // console.log('End sortby().');
}; // sortby()

window.onload = displayMarketData();