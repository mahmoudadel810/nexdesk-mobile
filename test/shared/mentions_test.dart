import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/shared/mentions.dart';

/// The same cases as the web app's frontend/src/app/shared/mentions.spec.ts.
void main() {
  test('finds the name being typed after an at sign', () {
    expect(mentionQuery('Hi @ma', 6), (start: 3, query: 'ma'));
    expect(mentionQuery('@Maya Pa', 8), (start: 0, query: 'Maya Pa'));
    expect(mentionQuery('(@', 2), (start: 1, query: ''));
    expect(mentionQuery('mail me@home', 12), isNull);
    expect(mentionQuery('@a b c', 6), isNull);
    expect(mentionQuery('no mention', 10), isNull);
    expect(mentionQuery('مرحبا @لي', 9), (start: 6, query: 'لي'));
  });

  test('suggests people by the start of any of their names', () {
    final people = ['Maya Patel', 'Tom Reed', 'Omar Haddad'];
    String name(String p) => p;
    expect(mentionCandidates(people, name, 'pa'), ['Maya Patel']);
    expect(mentionCandidates(people, name, 'om'), ['Omar Haddad']);
    expect(mentionCandidates(people, name, '', limit: 2), hasLength(2));
  });

  test('replaces the typed query with the full name and moves the caret after it', () {
    final query = mentionQuery('Ask @ma about it', 7)!;
    expect(insertMention('Ask @ma about it', query, 7, 'Maya Patel'), (
      text: 'Ask @Maya Patel about it',
      caret: 16,
    ));
  });

  test('splits a message into text and whole-name mentions', () {
    expect(splitMentions('cc @ann lee, @Ann and me@ann', ['Ann', 'Ann Lee']), [
      (text: 'cc ', mention: false),
      (text: '@ann lee', mention: true),
      (text: ', ', mention: false),
      (text: '@Ann', mention: true),
      (text: ' and me@ann', mention: false),
    ]);
    expect(splitMentions('@Annie', ['Ann']), [(text: '@Annie', mention: false)]);
  });
}
