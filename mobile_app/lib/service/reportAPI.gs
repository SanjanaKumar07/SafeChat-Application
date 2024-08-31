function doPost(request){
  // Open Google Sheet using ID
  var sheet = SpreadsheetApp.openById("1_C9Jl2nysHNXvVytXQ5WjyD6IIKHQSa0LbJX7aOCHtc");
  var result = {"status": "SUCCESS"};
  try{
    // Get all Parameters
    var message = request.parameter.message;
    var toxicity = request.parameter.toxicity;
   

    // Append data on Google Sheet
    var rowData = sheet.appendRow([message,toxicity]);

  }catch(exc){
    // If error occurs, throw exception
    result = {"status": "FAILED", "message": exc};
  }

  // Return result
  return ContentService
  .createTextOutput(JSON.stringify(result))
  .setMimeType(ContentService.MimeType.JSON);
}

function doGet(request){
  // Open Google Sheet using ID
  var sheet = SpreadsheetApp.openById("1_C9Jl2nysHNXvVytXQ5WjyD6IIKHQSa0LbJX7aOCHtc");

  // Get all values in active sheet
  var values = sheet.getActiveSheet().getDataRange().getValues();
  var data = [];

  for (var i = values.length - 1; i >= 0; i--) {

    // Get each row
    var row = values[i];

    // Create object
    var feedback = {};

    feedback['message'] = row[0];
    feedback['toxicity'] = row[1];
    
    // Push each row object in data
    data.push(feedback);
  }

  // Return result
  return ContentService
  .createTextOutput(JSON.stringify(data))
  .setMimeType(ContentService.MimeType.JSON);
}