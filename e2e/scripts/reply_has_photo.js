// Finds this run's reply on ticket NUMBER ("#271") through the local API and checks that its photo was stored as a
// JPEG under 2 MB.
var api = 'http://localhost:8080/api/v1';
var login = http.post(api + '/auth/mobile/login', {
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'maya@brightpath.demo', password: PASSWORD, deviceName: 'maestro' }),
});
var auth = { headers: { Authorization: 'Bearer ' + json(login.body).accessToken } };
var number = NUMBER.replace('#', '');
var found = json(http.get(api + '/tickets?Search=' + number + '&Page=1&PageSize=5', auth).body).items
  .filter(function (t) { return String(t.number) === number; })[0];
var timeline = json(http.get(api + '/tickets/' + found.id + '/timeline', auth).body);
var reply = timeline.filter(function (item) {
  return item.body && item.body.indexOf(output.mention) >= 0;
})[0];
var photo = reply && reply.attachments[0];
output.photoStored = !!photo && photo.contentType === 'image/jpeg' && photo.sizeBytes < 2 * 1024 * 1024;
console.log('photo on #' + number + ': ' + JSON.stringify(photo));
