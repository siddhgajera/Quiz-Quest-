import 'dart:math';

class QuestionBank {
  static final Map<String, Map<String, List<Map<String, Object>>>> questions = {
    // ===================== HISTORY =====================
    "History": {
      "easy": [
        {
          'question': 'Who was the first President of the USA?',
          'answers': ['George Washington', 'Abraham Lincoln', 'John Adams', 'Thomas Jefferson'],
          'correct': 'George Washington'
        },
        {
          'question': 'In which year did India gain independence?',
          'answers': ['1947', '1950', '1939', '1962'],
          'correct': '1947'
        },
        {
          'question': 'Who discovered America?',
          'answers': ['Christopher Columbus', 'Vasco da Gama', 'Magellan', 'James Cook'],
          'correct': 'Christopher Columbus'
        },
        {
          'question': 'Which empire built the pyramids?',
          'answers': ['Egyptian', 'Roman', 'Mayan', 'Greek'],
          'correct': 'Egyptian'
        },
        {
          'question': 'Who was the first Indian Prime Minister?',
          'answers': ['Jawaharlal Nehru', 'Mahatma Gandhi', 'Sardar Patel', 'Rajendra Prasad'],
          'correct': 'Jawaharlal Nehru'
        },
      ],
      "medium": [
        {
          'question': 'Who was the first Mughal Emperor of India?',
          'answers': ['Babur', 'Akbar', 'Humayun', 'Shah Jahan'],
          'correct': 'Babur'
        },
        {
          'question': 'Which treaty ended World War I?',
          'answers': ['Treaty of Versailles', 'Treaty of Paris', 'Treaty of Ghent', 'Treaty of Vienna'],
          'correct': 'Treaty of Versailles'
        },
        {
          'question': 'The Cold War was mainly between which nations?',
          'answers': ['USA & USSR', 'USA & Germany', 'USSR & China', 'USA & Japan'],
          'correct': 'USA & USSR'
        },
        {
          'question': 'Who built the Red Fort in Delhi?',
          'answers': ['Shah Jahan', 'Akbar', 'Aurangzeb', 'Humayun'],
          'correct': 'Shah Jahan'
        },
        {
          'question': 'Which battle in 1066 changed English history?',
          'answers': ['Battle of Hastings', 'Battle of Waterloo', 'Battle of Agincourt', 'Battle of Trafalgar'],
          'correct': 'Battle of Hastings'
        },
      ],
      "hard": [
        {
          'question': 'Who was the last Tsar of Russia?',
          'answers': ['Nicholas II', 'Peter the Great', 'Ivan the Terrible', 'Alexander III'],
          'correct': 'Nicholas II'
        },
        {
          'question': 'Which empire was ruled by Genghis Khan?',
          'answers': ['Mongol Empire', 'Ottoman Empire', 'Roman Empire', 'Persian Empire'],
          'correct': 'Mongol Empire'
        },
        {
          'question': 'The Rosetta Stone helped decode which script?',
          'answers': ['Egyptian hieroglyphs', 'Sanskrit', 'Mayan', 'Cuneiform'],
          'correct': 'Egyptian hieroglyphs'
        },
        {
          'question': 'Who led the Bolshevik Revolution?',
          'answers': ['Vladimir Lenin', 'Joseph Stalin', 'Leon Trotsky', 'Karl Marx'],
          'correct': 'Vladimir Lenin'
        },
        {
          'question': 'Which pharaoh built the Great Pyramid of Giza?',
          'answers': ['Khufu', 'Tutankhamun', 'Ramses II', 'Akhenaten'],
          'correct': 'Khufu'
        },
      ],
    },

    // ===================== SCIENCE =====================
    "Science": {
      "easy": [
        {
          'question': 'What is H2O commonly known as?',
          'answers': ['Water', 'Hydrogen', 'Oxygen', 'Salt'],
          'correct': 'Water'
        },
        {
          'question': 'Which planet is called the Red Planet?',
          'answers': ['Mars', 'Venus', 'Jupiter', 'Mercury'],
          'correct': 'Mars'
        },
        {
          'question': 'What force keeps us on the ground?',
          'answers': ['Gravity', 'Magnetism', 'Friction', 'Energy'],
          'correct': 'Gravity'
        },
        {
          'question': 'Which organ pumps blood?',
          'answers': ['Heart', 'Brain', 'Lungs', 'Kidney'],
          'correct': 'Heart'
        },
        {
          'question': 'Which gas do humans breathe in?',
          'answers': ['Oxygen', 'Carbon dioxide', 'Nitrogen', 'Hydrogen'],
          'correct': 'Oxygen'
        },
      ],
      "medium": [
        {
          'question': 'What is the chemical symbol for Gold?',
          'answers': ['Au', 'Ag', 'Gd', 'Pt'],
          'correct': 'Au'
        },
        {
          'question': 'Which planet has the most moons?',
          'answers': ['Saturn', 'Jupiter', 'Mars', 'Uranus'],
          'correct': 'Saturn'
        },
        {
          'question': 'What is the speed of light?',
          'answers': ['3×10^8 m/s', '3×10^6 m/s', '1.5×10^7 m/s', '3×10^5 m/s'],
          'correct': '3×10^8 m/s'
        },
        {
          'question': 'What part of the cell contains DNA?',
          'answers': ['Nucleus', 'Cytoplasm', 'Mitochondria', 'Ribosome'],
          'correct': 'Nucleus'
        },
        {
          'question': 'What is the powerhouse of the cell?',
          'answers': ['Mitochondria', 'Chloroplast', 'Nucleus', 'Golgi Apparatus'],
          'correct': 'Mitochondria'
        },
      ],
      "hard": [
        {
          'question': 'Who proposed the theory of relativity?',
          'answers': ['Albert Einstein', 'Isaac Newton', 'Galileo', 'Stephen Hawking'],
          'correct': 'Albert Einstein'
        },
        {
          'question': 'What is the heaviest naturally occurring element?',
          'answers': ['Uranium', 'Plutonium', 'Lead', 'Thorium'],
          'correct': 'Uranium'
        },
        {
          'question': 'Which scientist discovered penicillin?',
          'answers': ['Alexander Fleming', 'Louis Pasteur', 'Joseph Lister', 'Robert Koch'],
          'correct': 'Alexander Fleming'
        },
        {
          'question': 'Which gas is used in atomic bombs?',
          'answers': ['Uranium-235', 'Carbon dioxide', 'Nitrogen', 'Oxygen'],
          'correct': 'Uranium-235'
        },
        {
          'question': 'Which theory explains the origin of the universe?',
          'answers': ['Big Bang Theory', 'String Theory', 'Steady State', 'Quantum Theory'],
          'correct': 'Big Bang Theory'
        },
      ],
    },

    // ===================== GEOGRAPHY =====================
    "Geography": {
      "easy": [
        {
          'question': 'Which is the largest continent?',
          'answers': ['Asia', 'Africa', 'Europe', 'Australia'],
          'correct': 'Asia'
        },
        {
          'question': 'Which is the largest ocean?',
          'answers': ['Pacific Ocean', 'Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
          'correct': 'Pacific Ocean'
        },
        {
          'question': 'Which country is known as the Land of Rising Sun?',
          'answers': ['Japan', 'China', 'Korea', 'Thailand'],
          'correct': 'Japan'
        },
        {
          'question': 'Which river is the longest in the world?',
          'answers': ['Nile', 'Amazon', 'Yangtze', 'Ganga'],
          'correct': 'Nile'
        },
        {
          'question': 'Which is the coldest continent?',
          'answers': ['Antarctica', 'Asia', 'North America', 'Europe'],
          'correct': 'Antarctica'
        },
      ],
      "medium": [
        {
          'question': 'Which is the highest mountain peak in the world?',
          'answers': ['Mount Everest', 'K2', 'Kangchenjunga', 'Makalu'],
          'correct': 'Mount Everest'
        },
        {
          'question': 'Which desert is the largest in the world?',
          'answers': ['Sahara', 'Gobi', 'Thar', 'Kalahari'],
          'correct': 'Sahara'
        },
        {
          'question': 'Which country has the largest population?',
          'answers': ['India', 'China', 'USA', 'Russia'],
          'correct': 'India'
        },
        {
          'question': 'Which river flows through Egypt?',
          'answers': ['Nile', 'Amazon', 'Yangtze', 'Tigris'],
          'correct': 'Nile'
        },
        {
          'question': 'Which ocean surrounds Maldives?',
          'answers': ['Indian Ocean', 'Pacific Ocean', 'Atlantic Ocean', 'Arctic Ocean'],
          'correct': 'Indian Ocean'
        },
      ],
      "hard": [
        {
          'question': 'Which line divides Earth into Northern and Southern Hemisphere?',
          'answers': ['Equator', 'Tropic of Cancer', 'Tropic of Capricorn', 'Prime Meridian'],
          'correct': 'Equator'
        },
        {
          'question': 'What is the smallest country in the world?',
          'answers': ['Vatican City', 'Monaco', 'San Marino', 'Malta'],
          'correct': 'Vatican City'
        },
        {
          'question': 'Which lake is the deepest in the world?',
          'answers': ['Lake Baikal', 'Lake Superior', 'Caspian Sea', 'Lake Victoria'],
          'correct': 'Lake Baikal'
        },
        {
          'question': 'Which country has the most time zones?',
          'answers': ['France', 'USA', 'Russia', 'China'],
          'correct': 'France'
        },
        {
          'question': 'Which is the largest island in the world?',
          'answers': ['Greenland', 'Madagascar', 'New Guinea', 'Borneo'],
          'correct': 'Greenland'
        },
      ],
    },

    // ===================== LITERATURE =====================
    "Literature": {
      "easy": [
        {
          'question': 'Who wrote Romeo and Juliet?',
          'answers': ['William Shakespeare', 'Charles Dickens', 'Mark Twain', 'Jane Austen'],
          'correct': 'William Shakespeare'
        },
        {
          'question': 'Who wrote the Harry Potter series?',
          'answers': ['J.K. Rowling', 'J.R.R. Tolkien', 'C.S. Lewis', 'George Orwell'],
          'correct': 'J.K. Rowling'
        },
        {
          'question': 'Which book features Sherlock Holmes?',
          'answers': ['A Study in Scarlet', 'Hamlet', 'Moby Dick', 'The Odyssey'],
          'correct': 'A Study in Scarlet'
        },
        {
          'question': 'Who wrote Pride and Prejudice?',
          'answers': ['Jane Austen', 'Emily Bronte', 'Charlotte Bronte', 'Mary Shelley'],
          'correct': 'Jane Austen'
        },
        {
          'question': 'Who wrote The Odyssey?',
          'answers': ['Homer', 'Sophocles', 'Plato', 'Aristotle'],
          'correct': 'Homer'
        },
      ],
      "medium": [
        {
          'question': 'Who wrote 1984?',
          'answers': ['George Orwell', 'Aldous Huxley', 'F. Scott Fitzgerald', 'Ernest Hemingway'],
          'correct': 'George Orwell'
        },
        {
          'question': 'Who is the author of The Hobbit?',
          'answers': ['J.R.R. Tolkien', 'C.S. Lewis', 'J.K. Rowling', 'George R.R. Martin'],
          'correct': 'J.R.R. Tolkien'
        },
        {
          'question': 'Who wrote War and Peace?',
          'answers': ['Leo Tolstoy', 'Fyodor Dostoevsky', 'Anton Chekhov', 'Alexander Pushkin'],
          'correct': 'Leo Tolstoy'
        },
        {
          'question': 'Who wrote Macbeth?',
          'answers': ['William Shakespeare', 'Christopher Marlowe', 'John Milton', 'Geoffrey Chaucer'],
          'correct': 'William Shakespeare'
        },
        {
          'question': 'Who wrote Frankenstein?',
          'answers': ['Mary Shelley', 'Bram Stoker', 'Emily Bronte', 'Charles Dickens'],
          'correct': 'Mary Shelley'
        },
      ],
      "hard": [
        {
          'question': 'Who wrote Paradise Lost?',
          'answers': ['John Milton', 'William Blake', 'Geoffrey Chaucer', 'Alexander Pope'],
          'correct': 'John Milton'
        },
        {
          'question': 'Who wrote The Divine Comedy?',
          'answers': ['Dante Alighieri', 'Homer', 'Virgil', 'Sophocles'],
          'correct': 'Dante Alighieri'
        },
        {
          'question': 'Who wrote Crime and Punishment?',
          'answers': ['Fyodor Dostoevsky', 'Leo Tolstoy', 'Anton Chekhov', 'Ivan Turgenev'],
          'correct': 'Fyodor Dostoevsky'
        },
        {
          'question': 'Who wrote Don Quixote?',
          'answers': ['Miguel de Cervantes', 'Gabriel Garcia Marquez', 'Pablo Neruda', 'Jorge Luis Borges'],
          'correct': 'Miguel de Cervantes'
        },
        {
          'question': 'Who wrote The Iliad?',
          'answers': ['Homer', 'Virgil', 'Sophocles', 'Plato'],
          'correct': 'Homer'
        },
      ],
    },

    // ===================== ARTIFICIAL INTELLIGENCE =====================
    "Artificial Intelligence": {
      "easy": [
        {
          'question': 'AI stands for?',
          'answers': ['Artificial Intelligence', 'Automatic Information', 'Advanced Internet', 'Applied Innovation'],
          'correct': 'Artificial Intelligence'
        },
        {
          'question': 'Who is considered the father of AI?',
          'answers': ['John McCarthy', 'Alan Turing', 'Marvin Minsky', 'Geoffrey Hinton'],
          'correct': 'John McCarthy'
        },
        {
          'question': 'Which language is commonly used in AI?',
          'answers': ['Python', 'C', 'Java', 'PHP'],
          'correct': 'Python'
        },
        {
          'question': 'What does NLP stand for in AI?',
          'answers': ['Natural Language Processing', 'Network Level Protocol', 'New Logic Program', 'None'],
          'correct': 'Natural Language Processing'
        },
        {
          'question': 'What is a chatbot an example of?',
          'answers': ['AI application', 'Operating system', 'Compiler', 'Game'],
          'correct': 'AI application'
        },
      ],
      "medium": [
        {
          'question': 'Which algorithm is used in AI for decision making?',
          'answers': ['Minimax', 'Bubble Sort', 'Binary Search', 'Merge Sort'],
          'correct': 'Minimax'
        },
        {
          'question': 'Which AI technique is inspired by human brain?',
          'answers': ['Neural Networks', 'Genetic Algorithm', 'Decision Tree', 'Expert System'],
          'correct': 'Neural Networks'
        },
        {
          'question': 'Which company created AlphaGo?',
          'answers': ['DeepMind', 'OpenAI', 'Google Brain', 'IBM'],
          'correct': 'DeepMind'
        },
        {
          'question': 'Which AI branch deals with vision?',
          'answers': ['Computer Vision', 'NLP', 'Expert Systems', 'Robotics'],
          'correct': 'Computer Vision'
        },
        {
          'question': 'Which AI technique is used in self-driving cars?',
          'answers': ['Reinforcement Learning', 'Sorting', 'Parsing', 'Hashing'],
          'correct': 'Reinforcement Learning'
        },
      ],
      "hard": [
        {
          'question': 'What does GAN stand for?',
          'answers': ['Generative Adversarial Network', 'General AI Node', 'Global Analysis Network', 'Graph Attention Net'],
          'correct': 'Generative Adversarial Network'
        },
        {
          'question': 'Which year was the first AI winter?',
          'answers': ['1974', '1980', '1990', '1960'],
          'correct': '1974'
        },
        {
          'question': 'Which AI system defeated Garry Kasparov?',
          'answers': ['IBM Deep Blue', 'AlphaGo', 'Watson', 'GPT-3'],
          'correct': 'IBM Deep Blue'
        },
        {
          'question': 'Which learning technique uses labeled data?',
          'answers': ['Supervised Learning', 'Unsupervised Learning', 'Reinforcement Learning', 'Semi-supervised'],
          'correct': 'Supervised Learning'
        },
        {
          'question': 'Which AI algorithm is used in recommendation systems?',
          'answers': ['Collaborative Filtering', 'Sorting', 'Searching', 'Greedy'],
          'correct': 'Collaborative Filtering'
        },
      ],
    },

    // ---------------- Python ----------------
    "Python": {
      "easy": [
        {
          'question': 'Who developed Python programming language?',
          'answers': ['Guido van Rossum', 'Dennis Ritchie', 'James Gosling', 'Bjarne Stroustrup'],
          'correct': 'Guido van Rossum'
        },
        {
          'question': 'Which symbol is used for comments in Python?',
          'answers': ['#', '//', '--', '/* */'],
          'correct': '#'
        },
        {
          'question': 'What is the file extension of Python files?',
          'answers': ['.py', '.java', '.cpp', '.txt'],
          'correct': '.py'
        },
        {
          'question': 'Which keyword is used to define a function in Python?',
          'answers': ['function', 'def', 'fun', 'lambda'],
          'correct': 'def'
        },
        {
          'question': 'Which data type is mutable in Python?',
          'answers': ['List', 'Tuple', 'String', 'Integer'],
          'correct': 'List'
        },
      ],
      "medium": [
        {
          'question': 'Which of these is NOT a Python data type?',
          'answers': ['Set', 'Dictionary', 'ArrayList', 'Tuple'],
          'correct': 'ArrayList'
        },
        {
          'question': 'What does PEP stand for in Python?',
          'answers': ['Python Enhancement Proposal', 'Programming Easy Protocol', 'Python Event Processing', 'Portable Execution Program'],
          'correct': 'Python Enhancement Proposal'
        },
        {
          'question': 'Which library is used for data analysis in Python?',
          'answers': ['pandas', 'matplotlib', 'numpy', 'scipy'],
          'correct': 'pandas'
        },
        {
          'question': 'What is the output of: type([])?',
          'answers': ['list', 'tuple', 'set', 'dict'],
          'correct': 'list'
        },
        {
          'question': 'Which keyword is used for exception handling in Python?',
          'answers': ['catch', 'error', 'try', 'except'],
          'correct': 'try'
        },
      ],
      "hard": [
        {
          'question': 'Which module in Python supports regular expressions?',
          'answers': ['re', 'regex', 'pyregex', 'match'],
          'correct': 're'
        },
        {
          'question': 'What is Python’s built-in immutable sequence type?',
          'answers': ['Tuple', 'List', 'Set', 'Dict'],
          'correct': 'Tuple'
        },
        {
          'question': 'Which keyword is used for creating a generator in Python?',
          'answers': ['yield', 'return', 'generate', 'lambda'],
          'correct': 'yield'
        },
        {
          'question': 'Which Python library is used for deep learning?',
          'answers': ['TensorFlow', 'pandas', 'matplotlib', 'numpy'],
          'correct': 'TensorFlow'
        },
        {
          'question': 'What is the default recursion limit in Python?',
          'answers': ['1000', '500', '2000', '1500'],
          'correct': '1000'
        },
      ],
    },

    // ---------------- Cross Platform ----------------
    "Cross Platform": {
      "easy": [
        {
          'question': 'Which of these is a cross-platform mobile development framework?',
          'answers': ['Flutter', 'React Native', 'Xamarin', 'All of these'],
          'correct': 'All of these'
        },
        {
          'question': 'Flutter is developed by?',
          'answers': ['Google', 'Facebook', 'Microsoft', 'Apple'],
          'correct': 'Google'
        },
        {
          'question': 'React Native is maintained by?',
          'answers': ['Facebook', 'Google', 'Microsoft', 'IBM'],
          'correct': 'Facebook'
        },
        {
          'question': 'Which language is used in Flutter?',
          'answers': ['Dart', 'Java', 'Kotlin', 'C#'],
          'correct': 'Dart'
        },
        {
          'question': 'Which company owns Xamarin?',
          'answers': ['Microsoft', 'Apple', 'Google', 'Oracle'],
          'correct': 'Microsoft'
        },
      ],
      "medium": [
        {
          'question': 'Which of the following provides native-like performance?',
          'answers': ['Flutter', 'React Native', 'Cordova', 'Ionic'],
          'correct': 'Flutter'
        },
        {
          'question': 'Which tool is used for packaging React Native apps?',
          'answers': ['Metro Bundler', 'Gradle', 'Maven', 'Webpack'],
          'correct': 'Metro Bundler'
        },
        {
          'question': 'Which architecture does Flutter use?',
          'answers': ['Skia Engine', 'Virtual DOM', 'JVM', 'CLR'],
          'correct': 'Skia Engine'
        },
        {
          'question': 'Which language is primarily used in Xamarin?',
          'answers': ['C#', 'Java', 'Kotlin', 'Dart'],
          'correct': 'C#'
        },
        {
          'question': 'Cordova uses which technology?',
          'answers': ['HTML, CSS, JS', 'Java', 'Swift', 'Kotlin'],
          'correct': 'HTML, CSS, JS'
        },
      ],
      "hard": [
        {
          'question': 'Which of these is not cross-platform?',
          'answers': ['Swift', 'Flutter', 'Xamarin', 'React Native'],
          'correct': 'Swift'
        },
        {
          'question': 'Which database is commonly used with Flutter apps?',
          'answers': ['SQLite', 'Realm', 'Firestore', 'All of these'],
          'correct': 'All of these'
        },
        {
          'question': 'Which rendering engine does Flutter use?',
          'answers': ['Skia', 'Blink', 'WebKit', 'Gecko'],
          'correct': 'Skia'
        },
        {
          'question': 'React Native bridges JavaScript with?',
          'answers': ['Native APIs', 'Python', 'Kotlin', 'C++'],
          'correct': 'Native APIs'
        },
        {
          'question': 'Xamarin compiles into?',
          'answers': ['Native Code', 'Bytecode', 'JavaScript', 'IL only'],
          'correct': 'Native Code'
        },
      ],
    },

    // ---------------- Mathematical ----------------
    "Mathematical": {
      "easy": [
        {
          'question': 'What is 5 + 7?',
          'answers': ['12', '11', '10', '13'],
          'correct': '12'
        },
        {
          'question': 'What is 9 × 3?',
          'answers': ['27', '18', '36', '21'],
          'correct': '27'
        },
        {
          'question': 'Square root of 81 is?',
          'answers': ['9', '8', '7', '6'],
          'correct': '9'
        },
        {
          'question': 'What is 15 - 4?',
          'answers': ['11', '12', '9', '10'],
          'correct': '11'
        },
        {
          'question': 'What is 10 ÷ 2?',
          'answers': ['5', '2', '10', '20'],
          'correct': '5'
        },
      ],
      "medium": [
        {
          'question': 'What is the value of π (approx)?',
          'answers': ['3.14', '2.17', '3.41', '3.00'],
          'correct': '3.14'
        },
        {
          'question': 'What is 12²?',
          'answers': ['144', '122', '120', '124'],
          'correct': '144'
        },
        {
          'question': 'Derivative of x² is?',
          'answers': ['2x', 'x', 'x²', '1'],
          'correct': '2x'
        },
        {
          'question': 'What is the factorial of 5?',
          'answers': ['120', '60', '24', '100'],
          'correct': '120'
        },
        {
          'question': 'What is log₁₀(100)?',
          'answers': ['2', '10', '100', '1'],
          'correct': '2'
        },
      ],
      "hard": [
        {
          'question': 'Integral of 1/x dx is?',
          'answers': ['ln|x| + C', 'x', '1/x', 'e^x'],
          'correct': 'ln|x| + C'
        },
        {
          'question': 'What is the limit of (1 + 1/n)^n as n → ∞?',
          'answers': ['e', '1', '0', '∞'],
          'correct': 'e'
        },
        {
          'question': 'What is the value of sin(90°)?',
          'answers': ['1', '0', '-1', '0.5'],
          'correct': '1'
        },
        {
          'question': 'If matrix A is 2x2, its determinant formula is?',
          'answers': ['ad - bc', 'ab + cd', 'a+b+c+d', 'None'],
          'correct': 'ad - bc'
        },
        {
          'question': 'The Fibonacci series starts with?',
          'answers': ['0, 1', '1, 1', '2, 3', '1, 2'],
          'correct': '0, 1'
        },
      ],
    },
  };

  static List<Map<String, Object>> getQuestions(String subject, String difficulty) {
    final all = questions[subject]?[difficulty] ?? [];
    final shuffled = List<Map<String, Object>>.from(all);
    shuffled.shuffle(Random());
    return shuffled; // Return all available questions, let QuestionService handle the limit
  }

  // Add a new question to the question bank
  static void addQuestion({
    required String subject,
    required String difficulty,
    required String question,
    required List<String> answers,
    required String correct,
  }) {
    // Ensure subject exists
    if (!questions.containsKey(subject)) {
      questions[subject] = {
        'easy': [],
        'medium': [],
        'hard': [],
      };
    }
    
    // Ensure difficulty exists for this subject
    if (!questions[subject]!.containsKey(difficulty)) {
      questions[subject]![difficulty] = [];
    }
    
    // Add the new question
    questions[subject]![difficulty]!.add({
      'question': question,
      'answers': answers,
      'correct': correct,
    });
    
    print('QuestionBank: Added question to $subject/$difficulty. Total questions: ${questions[subject]![difficulty]!.length}');
  }

  // Get count of questions for a subject/difficulty
  static int getQuestionCount(String subject, String difficulty) {
    return questions[subject]?[difficulty]?.length ?? 0;
  }

  // Get all subjects
  static List<String> getSubjects() {
    return questions.keys.toList();
  }

  // Get total questions across all subjects/difficulties
  static int getTotalQuestionCount() {
    int total = 0;
    for (var subject in questions.keys) {
      for (var difficulty in questions[subject]!.keys) {
        total += questions[subject]![difficulty]!.length;
      }
    }
    return total;
  }

  // Remove a question (for admin management)
  static bool removeQuestion({
    required String subject,
    required String difficulty,
    required int index,
  }) {
    try {
      if (questions[subject]?[difficulty] != null && 
          index >= 0 && 
          index < questions[subject]![difficulty]!.length) {
        questions[subject]![difficulty]!.removeAt(index);
        print('QuestionBank: Removed question from $subject/$difficulty. Remaining: ${questions[subject]![difficulty]!.length}');
        return true;
      }
      return false;
    } catch (e) {
      print('QuestionBank: Error removing question: $e');
      return false;
    }
  }

  // Update an existing question
  static bool updateQuestion({
    required String subject,
    required String difficulty,
    required int index,
    required String question,
    required List<String> answers,
    required String correct,
  }) {
    try {
      if (questions[subject]?[difficulty] != null && 
          index >= 0 && 
          index < questions[subject]![difficulty]!.length) {
        questions[subject]![difficulty]![index] = {
          'question': question,
          'answers': answers,
          'correct': correct,
        };
        print('QuestionBank: Updated question in $subject/$difficulty at index $index');
        return true;
      }
      return false;
    } catch (e) {
      print('QuestionBank: Error updating question: $e');
      return false;
    }
  }
}
