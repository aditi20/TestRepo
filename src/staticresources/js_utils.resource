//------ Constants ----------

var SECONDS_PER_HOUR        = 3600;
var MILLISECONDS_PER_SECOND = 1000;

/**
* Decode the text to HTML entities
* <p>
* Get a encoded text and translate it into HTML entities
* (Related to IDALMSA-2272)
*
* @param text String    Encoded Text.
* @retunr text String   Decoded Text.
*/
function htmlDecode( text ){

    return (text) ? jQuery('<div/>').html(text).text() : '';
}

/**
* Encode the HTML text to special characters
* <p>
* Get a html text and translate special characters
* (Related to IDALMSA-2272)
*
* @param text String    Decoded Text.
* @return text String   Encoded Text.
*/
function htmlEncode( text ){
    return (text) ? jQuery('<div/>').text(text).html() : '';
}

/**
* Decode the HTML text special characters
*
* @param text String    Encoded Text.
* @return text String   Decoded Text.
*/
function htmlDecode( text ) {
    return (text) ? jQuery('<div/>').html(text).text() : '';
}

/**
 *  Method to know if an element is not undefined
 *  @param elem Element to check.
 *  @return True if element is not undefined, false otherwise.
 */
function isNotUndefined(elem){
    return typeof elem != 'undefined';
}

/**
*  Algorithm to order fields by label.
*/
function customSortByName(a, b){
     var nameA = a.label.toLowerCase(), nameB = b.label.toLowerCase()
     if (nameA < nameB) //sort string ascending
      return -1
     if (nameA > nameB)
      return 1
     return 0 //default return value (no sorting)
}

/**
 *	Method in charge to clone an object.
 *	@param Object to be cloned
 *  @return Object cloned.
 */
function clone(obj){
    if(obj == null || typeof(obj) != 'object')
        return obj;

    var temp = obj.constructor(); // changed

    for(var key in obj)
        temp[key] = clone(obj[key]);
    return temp;
}

/**
 *  Method in charge to convert milliseconds in a human readable time span.
 *  @param milliseconds Milliseconds to be converted.
 *  @return String with the format {x} days {y} hours {z} minutes {a} seconds.
 */
function millisecondsToString(milliseconds) {

    var seconds         = milliseconds / MILLISECONDS_PER_SECOND;
    var numhours        = Math.floor( seconds / SECONDS_PER_HOUR ) ;
    var numminutes      = Math.floor(( seconds  % SECONDS_PER_HOUR ) / 60) ;
    var numseconds      = ( seconds  % SECONDS_PER_HOUR ) % 60;
    
    var stringHours     = ( numhours > 0 ) ? numhours + ':' : '00:';
    var stringMinutes   = ( numminutes > 0 ) ? numminutes + ':' : '00:';
    var stringSeconds   = ( numseconds > 1 ) ? numseconds : '00';

    return stringHours + stringMinutes + stringSeconds ;
}

/**
 *  Method in charge of convert bytes to human readable size.
 */
function bytesToSize(bytes) {
    var sizes = ['bytes', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
    if (!isNotUndefined(bytes) || bytes == 0) return 'n/a';
    var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));

    if (i == 0) { 
        return (bytes / Math.pow(1024, i)) + ' ' + sizes[i];
    }
    return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
}