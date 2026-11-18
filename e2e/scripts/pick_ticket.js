// Picks a Brightpath ticket through the local API for the link flows: output.ticketId and output.ticketNumber.
var api = 'http://localhost:8080/api/v1';
var login = http.post(api + '/auth/mobile/login', {
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'maya@brightpath.demo', password: PASSWORD, deviceName: 'maestro' }),
});
var auth = { headers: { Authorization: 'Bearer ' + json(login.body).accessToken } };
var ticket = json(http.get(api + '/tickets?Page=1&PageSize=1', auth).body).items[0];
output.ticketId = ticket.id;
output.ticketNumber = String(ticket.number);
