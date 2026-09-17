"""Vocabulary for Crossword Bonanza.

Every entry is (WORD, emoji, clue). The emoji is the picture clue shown to
pre-readers in tier 1 and shrunk to a corner badge in tier 2. The clue is the
text shown from tier 2 onward and spoken aloud by the narrator at every tier.

Rules for anything added here:
  * Words are A-Z only, uppercase, 3-8 letters, and must be concrete nouns a
    5-10 year old can picture. No abstractions, no plurals-as-tricks.
  * Emoji must be a single standard emoji. No ZWJ sequences (e.g. no family or
    profession emoji) -- they render inconsistently across iOS versions and at
    small sizes.
  * Clues are one short sentence, present tense, no proper nouns, no wordplay.
    A six-year-old hearing it read aloud should be able to guess the word.
"""

# (word, emoji, clue)
WORDS = [
    # --- 3 letters -------------------------------------------------------
    ("CAT", "\U0001F431", "A furry pet that says meow"),
    ("DOG", "\U0001F436", "A friendly pet that says woof"),
    ("PIG", "\U0001F437", "A pink farm animal that says oink"),
    ("COW", "\U0001F42E", "A farm animal that gives us milk"),
    ("HEN", "\U0001F414", "A farm bird that lays eggs"),
    ("FOX", "\U0001F98A", "An orange animal with a bushy tail"),
    ("OWL", "\U0001F989", "A bird that hoots at night"),
    ("BEE", "\U0001F41D", "It buzzes around flowers and makes honey"),
    ("ANT", "\U0001F41C", "A tiny insect that lives in a hill"),
    ("BAT", "\U0001F987", "It flies at night and sleeps upside down"),
    ("EGG", "\U0001F95A", "A hen lays this"),
    ("PIE", "\U0001F967", "A sweet treat baked in a round dish"),
    ("CUP", "\U0001F964", "You drink out of it"),
    ("HAT", "\U0001F452", "You wear it on your head"),
    ("BAG", "\U0001F392", "You carry your things inside it"),
    ("BED", "\U0001F6CF", "You sleep in it at night"),
    ("KEY", "\U0001F511", "This little thing opens a lock"),
    ("MAP", "\U0001F5FA", "It shows you where to go"),
    ("BOX", "\U0001F4E6", "You keep things inside this square container"),
    ("BUS", "\U0001F68C", "A long vehicle that carries lots of people"),
    ("CAR", "\U0001F697", "You drive it on the road"),
    ("SUN", "☀", "It shines bright in the sky all day"),
    ("PEN", "\U0001F58A", "You write with it"),
    ("NET", "\U0001F945", "You catch a ball or a fish with it"),
    ("TOY", "\U0001F9F8", "Something fun you play with"),
    ("JAR", "\U0001FAD9", "A glass pot with a lid"),
    ("FAN", "\U0001FA83", "It spins around to make you cool"),
    ("BOW", "\U0001F380", "A pretty ribbon tied in a loop"),
    ("ICE", "\U0001F9CA", "Frozen water that is very cold"),
    ("SEA", "\U0001F30A", "A huge stretch of salty water"),

    # --- 4 letters -------------------------------------------------------
    ("CAKE", "\U0001F382", "You blow out candles on it on your birthday"),
    ("FISH", "\U0001F41F", "It swims in the water and has fins"),
    ("BIRD", "\U0001F426", "It has feathers and can fly"),
    ("FROG", "\U0001F438", "A green animal that hops and says ribbit"),
    ("DUCK", "\U0001F986", "A bird that swims and says quack"),
    ("BEAR", "\U0001F43B", "A big furry animal that loves honey"),
    ("LION", "\U0001F981", "The big cat that roars and has a mane"),
    ("GOAT", "\U0001F410", "A farm animal with horns that eats grass"),
    ("CRAB", "\U0001F980", "It walks sideways and has claws"),
    ("STAR", "⭐", "It twinkles high in the night sky"),
    ("MOON", "\U0001F319", "It glows in the sky when it is dark"),
    ("TREE", "\U0001F333", "It is tall with branches and leaves"),
    ("LEAF", "\U0001F343", "It grows green on a branch"),
    ("RAIN", "\U0001F327", "Water that falls down from the clouds"),
    ("SNOW", "❄", "Cold white flakes that fall in winter"),
    ("MILK", "\U0001F95B", "A white drink that comes from a cow"),
    ("CORN", "\U0001F33D", "A yellow vegetable that grows on a cob"),
    ("PEAR", "\U0001F350", "A green fruit shaped like a bell"),
    ("BOAT", "⛵", "It floats and sails on the water"),
    ("BIKE", "\U0001F6B2", "It has two wheels and you pedal it"),
    ("DRUM", "\U0001F941", "You hit it to make a beat"),
    ("BALL", "⚽", "You kick it, throw it, or bounce it"),
    ("BOOK", "\U0001F4DA", "You turn its pages and read it"),
    ("DOOR", "\U0001F6AA", "You open it to walk into a room"),
    ("SOCK", "\U0001F9E6", "You pull it onto your foot before your shoe"),
    ("SHOE", "\U0001F45F", "You wear it on your foot to go outside"),
    ("HAND", "✋", "It has five fingers"),
    ("NOSE", "\U0001F443", "You smell with it"),
    ("CAVE", "\U0001F5FB", "A dark hole in the side of a hill"),
    ("NEST", "\U0001FAB9", "A bird builds this home out of twigs"),
    ("KITE", "\U0001FA81", "You fly it on a string on a windy day"),
    ("LAMP", "\U0001F4A1", "You switch it on to make light"),
    ("RING", "\U0001F48D", "A round band you wear on your finger"),
    ("ROSE", "\U0001F339", "A red flower with a lovely smell"),
    ("WORM", "\U0001FAB1", "A long wiggly creature in the soil"),
    ("SEAL", "\U0001F9AD", "A smooth sea animal that claps its flippers"),
    ("SWAN", "\U0001F9A2", "A big white bird with a long neck"),
    ("DEER", "\U0001F98C", "A gentle forest animal with antlers"),
    ("WOLF", "\U0001F43A", "It looks like a dog and howls at the moon"),
    ("RICE", "\U0001F35A", "Little white grains you eat in a bowl"),
    ("SOUP", "\U0001F372", "A hot dinner you eat with a spoon"),
    ("SALT", "\U0001F9C2", "White grains you shake onto your dinner"),

    # --- 5 letters -------------------------------------------------------
    ("APPLE", "\U0001F34E", "A round red fruit that grows on a tree"),
    ("HOUSE", "\U0001F3E0", "A building where a family lives"),
    ("TRAIN", "\U0001F682", "A long vehicle that runs on rails"),
    ("HORSE", "\U0001F434", "A big animal you can ride in a saddle"),
    ("SHEEP", "\U0001F411", "A woolly farm animal that says baa"),
    ("MOUSE", "\U0001F42D", "A tiny animal with a long thin tail"),
    ("TIGER", "\U0001F42F", "A big orange cat with black stripes"),
    ("ZEBRA", "\U0001F993", "A horse-like animal with stripes"),
    ("WHALE", "\U0001F433", "The biggest animal in the ocean"),
    ("SNAKE", "\U0001F40D", "A long animal with no legs that hisses"),
    ("BREAD", "\U0001F35E", "You slice it to make a sandwich"),
    ("PIZZA", "\U0001F355", "A round dinner with cheese on top"),
    ("JUICE", "\U0001F9C3", "A sweet drink squeezed from fruit"),
    ("WATER", "\U0001F4A7", "You drink this when you are thirsty"),
    ("CLOUD", "☁", "A fluffy white shape floating in the sky"),
    ("GRASS", "\U0001F33F", "Green blades that cover a garden"),
    ("BEACH", "\U0001F3D6", "The sandy place beside the sea"),
    ("PLANE", "✈", "It has wings and flies people through the sky"),
    ("TRUCK", "\U0001F69A", "A big vehicle that carries heavy loads"),
    ("CLOCK", "\U0001F551", "Its hands tell you the time"),
    ("CHAIR", "\U0001FA91", "You sit down on it"),
    ("SPOON", "\U0001F944", "You eat your soup with it"),
    ("PLATE", "\U0001F37D", "Your food sits on this flat round dish"),
    ("SHIRT", "\U0001F455", "You wear it on the top half of your body"),
    ("SMILE", "\U0001F600", "What your mouth does when you are happy"),
    ("HEART", "❤", "It beats inside your chest"),
    ("MUSIC", "\U0001F3B5", "Sounds and songs you listen to"),
    ("PAINT", "\U0001F3A8", "Coloured liquid you brush onto paper"),
    ("ROBOT", "\U0001F916", "A metal helper made of machines"),
    ("QUEEN", "\U0001FAC5", "A royal lady who wears a crown"),
    ("BRUSH", "\U0001FAA5", "You use it to clean your teeth"),
    ("CANDY", "\U0001F36C", "A sugary sweet in a wrapper"),
    ("HONEY", "\U0001F36F", "A sticky golden food made by bees"),
    ("LEMON", "\U0001F34B", "A yellow fruit with a very sour taste"),
    ("MELON", "\U0001F348", "A big juicy fruit with lots of seeds"),
    ("GRAPE", "\U0001F347", "A small round fruit that grows in bunches"),
    ("PEACH", "\U0001F351", "A soft orange fruit with fuzzy skin"),
    ("ONION", "\U0001F9C5", "A vegetable that makes your eyes water"),
    ("SHARK", "\U0001F988", "A sea animal with lots of sharp teeth"),
    ("SNAIL", "\U0001F40C", "A slow creature that carries its shell"),
    ("PANDA", "\U0001F43C", "A black and white bear that eats bamboo"),
    ("KOALA", "\U0001F428", "A grey animal that hugs a tree all day"),
    ("CAMEL", "\U0001F42A", "A desert animal with a hump on its back"),
    ("EAGLE", "\U0001F985", "A huge bird with a sharp curved beak"),
    ("GOOSE", "\U0001FABF", "A big noisy bird that honks"),
    ("TEETH", "\U0001F9B7", "You chew your food with them"),
    ("RIVER", "\U0001F3DE", "Water that flows along to the sea"),
    ("STONE", "\U0001FAA8", "A hard grey lump you find on the ground"),
    ("CROWN", "\U0001F451", "A king wears this on his head"),
    ("SWORD", "⚔", "A knight carries this shiny blade"),
    ("TRAIL", "\U0001F97E", "A narrow path you walk along"),
    ("STORM", "⛈", "Wild weather with wind and thunder"),

    # --- 6 letters -------------------------------------------------------
    ("FLOWER", "\U0001F338", "A pretty plant with coloured petals"),
    ("MONKEY", "\U0001F435", "It swings through the trees and loves bananas"),
    ("RABBIT", "\U0001F430", "A fluffy animal with long ears that hops"),
    ("TURTLE", "\U0001F422", "A slow animal with a hard shell"),
    ("SPIDER", "\U0001F577", "It has eight legs and spins a web"),
    ("PARROT", "\U0001F99C", "A colourful bird that copies what you say"),
    ("BANANA", "\U0001F34C", "A long yellow fruit you peel"),
    ("ORANGE", "\U0001F34A", "A round juicy fruit the colour of its name"),
    ("CHEESE", "\U0001F9C0", "A yellow food made from milk"),
    ("CARROT", "\U0001F955", "A long orange vegetable that rabbits love"),
    ("COOKIE", "\U0001F36A", "A sweet round biscuit with chips in it"),
    ("ROCKET", "\U0001F680", "It blasts off and flies into space"),
    ("PENCIL", "✏", "You draw with it and rub out your mistakes"),
    ("SCHOOL", "\U0001F3EB", "The place where you go to learn"),
    ("CASTLE", "\U0001F3F0", "A huge stone home with tall towers"),
    ("BRIDGE", "\U0001F309", "You cross it to get over a river"),
    ("GUITAR", "\U0001F3B8", "You strum its six strings to make music"),
    ("CAMERA", "\U0001F4F7", "You use it to take photographs"),
    ("WINDOW", "\U0001FA9F", "You look through this hole in the wall"),
    ("BASKET", "\U0001F9FA", "A woven container with a handle"),
    ("ISLAND", "\U0001F3DD", "Land with water all the way around it"),
    ("PLANET", "\U0001FA90", "A giant round world out in space"),
    ("DRAGON", "\U0001F409", "A make-believe beast that breathes fire"),
    ("BUTTON", "\U0001F518", "You press it or sew it on a shirt"),
    ("PUPPET", "\U0001F9F5", "A little figure you move with strings"),
    ("YELLOW", "\U0001F7E1", "The colour of a lemon and the sun"),
    ("PURPLE", "\U0001F7E3", "The colour you get mixing red and blue"),
    ("WINTER", "☃", "The coldest season of the year"),
    ("SUMMER", "\U0001F31E", "The hottest season of the year"),
    ("GARDEN", "\U0001F33B", "A patch of ground where plants grow"),
    ("FOREST", "\U0001F332", "A big wood with hundreds of trees"),
    ("BOTTLE", "\U0001F37C", "A tall container you pour a drink from"),
    ("MITTEN", "\U0001F9E4", "A warm cover for your hand in the snow"),
    ("TUNNEL", "\U0001F687", "A long hole dug right through a hill"),
    ("HAMMER", "\U0001F528", "You bang a nail in with it"),
    ("LADDER", "\U0001FA9C", "You climb its steps to reach up high"),
    ("ROOSTER", "\U0001F413", "The farm bird that crows in the morning"),

    # --- 7 letters -------------------------------------------------------
    ("DOLPHIN", "\U0001F42C", "A clever sea animal that leaps and clicks"),
    ("PENGUIN", "\U0001F427", "A black and white bird that waddles on ice"),
    ("GIRAFFE", "\U0001F992", "The tallest animal, with a very long neck"),
    ("RAINBOW", "\U0001F308", "Coloured stripes in the sky after the rain"),
    ("BALLOON", "\U0001F388", "You blow it up and it floats away"),
    ("PUMPKIN", "\U0001F383", "A big orange vegetable you carve"),
    ("POPCORN", "\U0001F37F", "Corn that goes pop and puffs up white"),
    ("LIBRARY", "\U0001F4D6", "A quiet place full of books to borrow"),
    ("KITCHEN", "\U0001F373", "The room where the cooking is done"),
    ("BLANKET", "\U0001F9F6", "A soft cover that keeps you warm in bed"),
    ("DIAMOND", "\U0001F48E", "A sparkling stone that is very precious"),
    ("VOLCANO", "\U0001F30B", "A mountain that shoots out hot lava"),
    ("COMPASS", "\U0001F9ED", "Its needle always points north"),
    ("LANTERN", "\U0001F3EE", "A little lamp you carry in the dark"),
    ("MONSTER", "\U0001F47E", "A make-believe creature in a story"),
    ("OCTOPUS", "\U0001F419", "A sea creature with eight long arms"),
    ("PEACOCK", "\U0001F99A", "A bird that fans out a huge bright tail"),
    ("HAMSTER", "\U0001F439", "A tiny pet that runs on a wheel"),
    ("TEAPOT", "\U0001FAD6", "You pour a hot drink out of its spout"),
    ("SANDALS", "\U0001F461", "Open shoes you wear in hot weather"),
    ("PYJAMAS", "\U0001F457", "The soft clothes you wear to bed"),
    ("CRAYONS", "\U0001F58D", "Coloured wax sticks for drawing"),
    ("TRACTOR", "\U0001F69C", "A farm machine that pulls a plough"),
    ("WHISTLE", "\U0001FA88", "You blow it to make a loud sharp sound"),
    ("ELEPHANT", "\U0001F418", "A huge grey animal with a long trunk"),
    ("SQUIRREL", "\U0001F43F", "A bushy-tailed animal that hides nuts"),
    ("DINOSAUR", "\U0001F996", "A giant reptile from long, long ago"),
]


def by_length():
    """Return {length: [(word, emoji, clue), ...]} with duplicates removed."""
    buckets = {}
    seen = set()
    for word, emoji, clue in WORDS:
        if word in seen:
            continue
        seen.add(word)
        buckets.setdefault(len(word), []).append((word, emoji, clue))
    return buckets


def validate_bank():
    """Sanity-check the bank itself. Returns a list of problem strings."""
    problems = []
    seen = set()
    for word, emoji, clue in WORDS:
        if word in seen:
            problems.append(f"duplicate word: {word}")
        seen.add(word)
        if not word.isalpha() or not word.isupper():
            problems.append(f"word must be A-Z uppercase: {word!r}")
        if not 3 <= len(word) <= 8:
            problems.append(f"word length out of range: {word}")
        if not emoji:
            problems.append(f"missing emoji: {word}")
        if "‍" in emoji:
            problems.append(f"emoji uses a ZWJ sequence: {word}")
        if not clue or not clue[0].isupper() or clue.endswith("."):
            problems.append(f"clue should start capitalised and have no full stop: {word}")
        if word.lower() in clue.lower():
            problems.append(f"clue gives the answer away: {word}")

    # Two entries sharing an emoji would be indistinguishable as picture clues.
    emoji_owners = {}
    for word, emoji, _ in WORDS:
        emoji_owners.setdefault(emoji, []).append(word)
    for emoji, owners in emoji_owners.items():
        if len(owners) > 1:
            problems.append(f"emoji {emoji} shared by {', '.join(owners)}")
    return problems


if __name__ == "__main__":
    issues = validate_bank()
    for issue in issues:
        print("PROBLEM:", issue)
    counts = {k: len(v) for k, v in sorted(by_length().items())}
    print(f"{len(WORDS)} words, {len(issues)} problems, by length: {counts}")
