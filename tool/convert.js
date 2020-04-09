//
// @ Thomas LANDSPURG 2020
// Tool used to convert csv file and upload it into
// firebase, for the 'QuiEstOuvert' Open source app
// Note that you need to have an admin file to be able to do this, and the admin file is not included
// in this tool.
//

const fs = require('fs');
const neatCsv = require('neat-csv');
const geohash = require('ngeohash');
require('dotenv').config()
// The Firebase Admin SDK to access the Firebase Realtime Database.
var admin = require("firebase-admin");
var serviceAccount = require("./quiestouvert-firebase-adminsdk.json");

// Initialize Firebase access
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://quiestouvert.firebaseio.com"
});
var db = admin.firestore();

// Add an element into the Firebase database, using batching.
// location is translated into a Firebase GeoPoint, and a GeoHash is added
// to speed up research...

function addElem(batch, elem) {
  let baseRef = db.collection('locations');
  let docRef = baseRef.doc(elem.osm_id.split('/')[1]);
  const lat = parseFloat(elem.lat); const lon = parseFloat(elem.lon);
  elem.location = { geopoint: new admin.firestore.GeoPoint(lat, lon), geohash: geohash.encode(lat, lon) }
  console.log("Seeting", elem.osm_id.split('/')[1], elem);
  //  docRef.set(elem);
  batch.set(docRef, elem);
}
function readAll() {
  readFile("poi_osm.csv");
}

// Read the CSV file and convert it into JSON, then call
// the firebase update in a batched mode (batchSize of 400)
function readFile(name) {
  console.log("Reading all");
  fs.readFile(name, async (err, data) => {
    if (err) {
      console.error(err)
      return
    }
    console.log("Read...");
    neatCsv(data).then((data) => {
      res = {}
      data.forEach((elem) => {
        res[elem['cat']] = 1;
      });
      console.log(res);
      /*    const batchSize=400;
          for(var i = 0; i < data.length; i+=batchSize) {
           var batch = db.batch();
            data.slice(i,i+batchSize).forEach((elem)=>{
              console.log(elem);
              addElem(batch,elem);
            });
            console.log("Commiting");
            batch.commit();
          };
        */
      });
    });
  }

readAll();


