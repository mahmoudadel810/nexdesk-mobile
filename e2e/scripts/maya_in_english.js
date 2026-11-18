// Puts Maya's account back to English through the API, whatever happened in the flow, so a failed language flow
// does not leave the other flows facing an Arabic app.
var api = 'http://localhost:8080/api/v1';
var login = http.post(api + '/auth/mobile/login', {
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'maya@brightpath.demo', password: 'NexDesk-demo-2026', deviceName: 'maestro' }),
});
var auth = json(login.body);
http.put(api + '/users/me/profile', {
  headers: { Authorization: 'Bearer ' + auth.accessToken, 'Content-Type': 'application/json' },
  body: JSON.stringify({ fullName: auth.session.user.fullName, language: 'en' }),
});
