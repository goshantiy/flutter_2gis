enum EventStatus {
  current('Идут сейчас'),
  soon('Скоро'),
  future('В будущем'),
  all('Все');

  const EventStatus(this.displayName);
  final String displayName;
}