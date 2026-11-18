// Signs in as Tom against the local API and looks for this run's mention among his newest notifications.
var api = 'http://localhost:8080/api/v1';
var login = http.post(api + '/auth/mobile/login', {
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'tom@brightpath.demo', password: PASSWORD, deviceName: 'maestro' }),
});
var token = json(login.body).accessToken;
var page = json(http.get(api + '/notifications?page=1&pageSize=10', {
  headers: { Authorization: 'Bearer ' + token },
}).body);
output.tomMentioned = page.items.some(function (n) {
  return n.type === 'Mention' && n.preview.indexOf(output.mention) >= 0;
});
