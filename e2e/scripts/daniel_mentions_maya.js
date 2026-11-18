// Daniel, signed in on the "web" (the API directly), adds a note on ticket NUMBER that mentions Maya.
var api = 'http://localhost:8080/api/v1';
var login = http.post(api + '/auth/mobile/login', {
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'daniel@brightpath.demo', password: PASSWORD, deviceName: 'maestro' }),
});
var token = json(login.body).accessToken;
var headers = { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' };
var number = NUMBER.replace('#', '');
var found = json(http.get(api + '/tickets?Search=' + number + '&Page=1&PageSize=5', { headers: headers }).body).items
  .filter(function (t) { return String(t.number) === number; })[0];
var sent = http.post(api + '/tickets/' + found.id + '/messages', {
  headers: headers,
  body: JSON.stringify({ body: '@Maya Chen live check ' + output.mention, isInternal: true }),
});
output.noteSent = sent.status === 200;
