/// Curated emoji set for the category picker. [keywords] are space
/// separated search words for the whole group; [extra] adds words for
/// single emojis. Any emoji not here can be added with "Custom".
class EmojiGroup {
  final String label;
  final String keywords;
  final List<String> emojis;
  const EmojiGroup(this.label, this.keywords, this.emojis);
}

const List<EmojiGroup> emojiGroups = [
  EmojiGroup('Sports', 'sport sports game play fitness gym match', [
    '🏸', '🎾', '⚽', '🏀', '🏏', '🏐', '🏈', '⚾', '🥎', '🏓', '🏒', '🏑', '🥍', '🏉',
    '🎱', '⛳', '🏹', '🥊', '🥋', '🥅', '⛸️', '🎿', '🏂', '🏋️', '🤸', '🤺', '🏇', '🧘',
    '🏊', '🚴', '🚵', '🏄', '🚣', '🧗', '🤾', '🏆', '🥇', '🥈', '🥉', '🏅', '🎽', '🛹',
  ]),
  EmojiGroup('Food & Drink', 'food eat drink dining restaurant meal snack cafe', [
    '🍕', '🍔', '🍟', '🌭', '🥪', '🌮', '🌯', '🥙', '🧆', '🍝', '🍜', '🍲', '🍛', '🍣',
    '🍱', '🥟', '🍤', '🍙', '🍚', '🍘', '🥗', '🍿', '🧂', '🥓', '🍳', '🥞', '🧇', '🧀',
    '🍞', '🥐', '🥖', '🥨', '🍰', '🎂', '🧁', '🥧', '🍩', '🍪', '🍫', '🍬', '🍭', '🍮',
    '🍦', '🍧', '🍨', '☕', '🍵', '🧋', '🥤', '🧃', '🥛', '🍼', '🍺', '🍻', '🥂', '🍷',
    '🥃', '🍸', '🍹', '🍾', '🍎', '🍌', '🍇', '🍓', '🍉', '🍊', '🥭', '🍍', '🥥', '🥑',
    '🍆', '🥕', '🌽', '🌶️', '🥦', '🍄', '🥜',
  ]),
  EmojiGroup('Travel & Places', 'travel trip car vehicle transport fuel flight hotel place', [
    '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚚', '🚛', '🚜', '🛵', '🏍️',
    '🚲', '🛴', '🚂', '🚆', '🚇', '🚊', '🚉', '✈️', '🛫', '🛬', '🚁', '🚀', '🛸', '⛵',
    '🚤', '🛥️', '🚢', '⚓', '⛽', '🚏', '🚦', '🅿️', '🗺️', '🧭', '🏔️', '⛰️', '🌋', '🏕️',
    '🏖️', '🏝️', '🏜️', '🏠', '🏡', '🏢', '🏨', '🏩', '🏪', '🏫', '🏥', '🏦', '🏭', '🏰',
    '🕌', '🛕', '⛪', '🗼', '🗽', '🎡', '🎢', '🎠', '⛲', '🌃', '🌆', '🌉', '🧳', '🛄',
  ]),
  EmojiGroup('Activities', 'fun party game event hobby music movie', [
    '🎮', '🕹️', '🎲', '♟️', '🧩', '🎯', '🎳', '🎰', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁',
    '🎷', '🎺', '🎸', '🪕', '🎻', '🎨', '🖌️', '🎭', '🎪', '🎟️', '🎫', '🎉', '🎊', '🎈',
    '🎁', '🎀', '🪅', '🎃', '🎄', '🎆', '🎇', '🧨', '✨', '🎐', '🎑', '📸', '🎥', '📺',
  ]),
  EmojiGroup('Home & Bills', 'home rent bill utility electricity water wifi repair house', [
    '🛋️', '🛏️', '🚿', '🛁', '🚽', '🧻', '🧼', '🧽', '🧴', '🪒', '🧹', '🧺', '🪣', '🔑',
    '🗝️', '🚪', '🪟', '🪑', '💡', '🔌', '🔋', '🕯️', '🔥', '💧', '🌡️', '📶', '📡', '☎️',
    '📞', '📱', '🔧', '🔨', '🛠️', '⚙️', '🧰', '🪛', '🪚', '🧱', '🪜', '🧯', '🗑️', '🪴',
  ]),
  EmojiGroup('Shopping & Money', 'shop shopping money cash bank pay gift clothes finance', [
    '🛒', '🛍️', '🏷️', '💰', '💵', '💴', '💶', '💷', '💳', '🧾', '💸', '🪙', '🏧', '📈',
    '📉', '📊', '💎', '👗', '👕', '👖', '👔', '🧥', '👟', '👠', '👜', '🎒', '👓', '🕶️',
    '⌚', '💍', '💄', '🎁', '📦', '📮', '🛎️', '🧸', '🪆', '🧵', '🧶',
  ]),
  EmojiGroup('Health & Care', 'health doctor medicine hospital care gym spa wellness', [
    '🩺', '💊', '💉', '🩹', '🩼', '🦷', '🩻', '🧬', '🔬', '🧪', '🏥', '🚑', '❤️‍🩹', '🧘',
    '💆', '💇', '💅', '🛀', '😷', '🤒', '🤕', '🏋️‍♀️', '🏋️‍♂️', '🥗', '🍎', '😴',
  ]),
  EmojiGroup('Work & School', 'work office school study book laptop job learn', [
    '💻', '🖥️', '⌨️', '🖱️', '🖨️', '📱', '📚', '📖', '📝', '✏️', '🖊️', '📐', '📏', '🎓',
    '🏫', '💼', '📁', '📂', '🗂️', '📅', '📆', '📋', '📌', '📎', '✂️', '🗃️', '🧮', '🔭',
  ]),
  EmojiGroup('Animals & Nature', 'animal pet dog cat nature plant flower tree', [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸',
    '🐵', '🐔', '🐧', '🐦', '🦆', '🦉', '🦋', '🐝', '🐞', '🐢', '🐍', '🐙', '🐠', '🐬',
    '🐳', '🦈', '🐘', '🦒', '🐴', '🐕', '🐈', '🐾', '🌳', '🌴', '🌵', '🌱', '🌿', '🍀',
    '🌸', '🌹', '🌻', '🌼', '🌷', '🍁', '🌞', '🌙', '⭐', '🌈', '☁️', '⛈️', '❄️', '🌊',
  ]),
  EmojiGroup('Smileys & People', 'face smile people happy love emotion friends family baby', [
    '😀', '😄', '😁', '😂', '🤣', '😊', '😍', '🥰', '😎', '🤩', '🥳', '😇', '🙂', '😉',
    '😋', '😜', '🤗', '🤔', '😴', '🤯', '😭', '😤', '🙏', '👍', '👏', '🙌', '🤝', '💪',
    '👋', '✌️', '🤞', '👨‍👩‍👧', '👨‍👩‍👧‍👦', '👫', '👭', '👬', '🧑‍🤝‍🧑', '👶', '🧒', '🧓', '💑', '💏',
  ]),
  EmojiGroup('Symbols', 'symbol heart star sign mark check alert', [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💯', '✅', '❌', '⚠️', '🔔', '🔕',
    '⭐', '🌟', '💫', '⚡', '🔥', '💥', '♻️', '🔰', '🔱', '📍', '🚩', '🏁', '🔖', '🆗',
    '🆕', '🆓', '🔝', '➕', '➖', '✖️', '➗', '♾️', '‼️', '❓', '❗', '💬', '💭', '🕐',
  ]),
];

/// Extra search words for popular single emojis.
const Map<String, String> emojiExtra = {
  '🏸': 'badminton shuttle racket turf',
  '🎾': 'tennis',
  '⚽': 'football soccer turf',
  '🏏': 'cricket bat',
  '🍕': 'pizza tacos',
  '🌮': 'taco tacos',
  '☕': 'coffee tea cafe',
  '🍺': 'beer pub bar',
  '⛽': 'fuel petrol diesel gas',
  '🚗': 'car cab taxi drive',
  '✈️': 'flight plane trip',
  '🏨': 'hotel stay',
  '🏠': 'rent home house',
  '💡': 'electricity power light bulb',
  '📶': 'wifi internet',
  '💧': 'water',
  '🛒': 'grocery groceries cart',
  '🎬': 'movie cinema film',
  '🎮': 'game gaming',
  '🎁': 'gift present birthday',
  '💊': 'medicine pharmacy',
  '🩺': 'doctor clinic',
  '🐶': 'dog pet',
  '🐱': 'cat pet',
  '📚': 'books study',
  '💻': 'laptop work',
  '🏋️': 'gym workout',
  '🧘': 'yoga',
  '💳': 'card credit bill',
  '🧾': 'receipt bill',
  '🧳': 'luggage trip travel',
  '🎉': 'party celebration',
};

/// All emojis matching [query] (empty = every emoji, grouped order).
List<String> searchEmojis(String query) {
  final q = query.trim().toLowerCase();
  final seen = <String>{};
  final out = <String>[];
  for (final g in emojiGroups) {
    final groupHit =
        q.isEmpty || g.label.toLowerCase().contains(q) || g.keywords.contains(q);
    for (final e in g.emojis) {
      final hit = groupHit || (emojiExtra[e]?.contains(q) ?? false) || e == q;
      if (hit && seen.add(e)) out.add(e);
    }
  }
  return out;
}
