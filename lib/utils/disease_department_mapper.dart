String mapDiseaseToDepartment(String disease) {
  final String d = disease.toLowerCase().trim();

  if (d.isEmpty || d == "uncertain" || d == "unknown") {
    return "General Physician";
  }

  /// Exact disease mapping according to your available departments
  const Map<String, String> exactDiseaseToDepartment = {
    // General Physician
    "malaria": "General Physician",
    "typhoid": "General Physician",
    "flu": "General Physician",
    "influenza": "General Physician",
    "viral fever": "General Physician",
    "fever": "General Physician",
    "common cold": "General Physician",
    "allergy": "General Physician",
    "dengue": "General Physician",
    "covid": "General Physician",
    "pneumonia": "General Physician",
    "asthma": "General Physician",
    "diabetes": "General Physician",
    "thyroid": "General Physician",

    // Cardiology
    "heart attack": "Cardiology",
    "myocardial infarction": "Cardiology",
    "hypertension": "Cardiology",
    "high blood pressure": "Cardiology",
    "angina": "Cardiology",
    "arrhythmia": "Cardiology",

    // Neurology
    "migraine": "Neurology",
    "headache": "Neurology",
    "epilepsy": "Neurology",
    "seizure": "Neurology",
    "stroke": "Neurology",
    "paralysis": "Neurology",
    "vertigo": "Neurology",

    // Dermatology
    "skin allergy": "Dermatology",
    "acne": "Dermatology",
    "eczema": "Dermatology",
    "rash": "Dermatology",
    "psoriasis": "Dermatology",
    "fungal infection": "Dermatology",
    "scabies": "Dermatology",

    // Orthopedics
    "fracture": "Orthopedics",
    "arthritis": "Orthopedics",
    "joint pain": "Orthopedics",
    "back pain": "Orthopedics",
    "knee pain": "Orthopedics",
    "shoulder pain": "Orthopedics",
    "bone pain": "Orthopedics",

    // ENT
    "ear infection": "ENT",
    "sinusitis": "ENT",
    "tonsillitis": "ENT",
    "sore throat": "ENT",
    "throat infection": "ENT",
    "hearing loss": "ENT",

    // Pediatrics
    "measles": "Pediatrics",
    "mumps": "Pediatrics",
    "chickenpox": "Pediatrics",
    "whooping cough": "Pediatrics",

    // Psychiatry
    "depression": "Psychiatry",
    "anxiety": "Psychiatry",
    "panic disorder": "Psychiatry",
    "insomnia": "Psychiatry",
    "stress": "Psychiatry",
  };

  if (exactDiseaseToDepartment.containsKey(d)) {
    return exactDiseaseToDepartment[d]!;
  }

  /// Keyword-based closest department matching

  if (_containsAny(d, [
    "heart",
    "cardiac",
    "chest pain",
    "angina",
    "palpitation",
    "palpitations",
    "blood pressure",
    "hypertension",
    "bp",
    "arrhythmia",
    "myocardial",
    "infarction",
  ])) {
    return "Cardiology";
  }

  if (_containsAny(d, [
    "migraine",
    "headache",
    "brain",
    "seizure",
    "epilepsy",
    "stroke",
    "paralysis",
    "numbness",
    "tingling",
    "dizziness",
    "vertigo",
    "memory",
    "nerve",
    "tremor",
    "fainting",
  ])) {
    return "Neurology";
  }

  if (_containsAny(d, [
    "skin",
    "rash",
    "itch",
    "itching",
    "acne",
    "pimple",
    "eczema",
    "psoriasis",
    "dermatitis",
    "fungal",
    "ringworm",
    "hives",
    "allergic rash",
    "skin allergy",
    "spots",
    "blister",
    "boil",
    "scabies",
  ])) {
    return "Dermatology";
  }

  if (_containsAny(d, [
    "bone",
    "joint",
    "fracture",
    "sprain",
    "arthritis",
    "back pain",
    "knee pain",
    "shoulder pain",
    "neck pain",
    "muscle pain",
    "ligament",
    "orthopedic",
    "orthopaedic",
  ])) {
    return "Orthopedics";
  }

  if (_containsAny(d, [
    "ear",
    "nose",
    "throat",
    "sinus",
    "tonsil",
    "tonsillitis",
    "hearing",
    "sore throat",
    "ear infection",
    "nasal",
    "voice",
    "laryngitis",
  ])) {
    return "ENT";
  }

  if (_containsAny(d, [
    "child",
    "children",
    "pediatric",
    "paediatric",
    "measles",
    "mumps",
    "chickenpox",
    "whooping cough",
    "infant",
    "baby",
  ])) {
    return "Pediatrics";
  }

  if (_containsAny(d, [
    "depression",
    "anxiety",
    "stress",
    "panic",
    "insomnia",
    "sleep disorder",
    "mental",
    "psychiatric",
    "bipolar",
    "ocd",
    "phobia",
  ])) {
    return "Psychiatry";
  }

  if (_containsAny(d, [
    "fever",
    "viral",
    "infection",
    "flu",
    "cold",
    "cough",
    "body pain",
    "weakness",
    "vomiting",
    "nausea",
    "diarrhea",
    "stomach",
    "abdominal",
    "malaria",
    "typhoid",
    "dengue",
    "covid",
    "pneumonia",
    "asthma",
    "allergy",
    "fatigue",
    "diabetes",
    "thyroid",
    "pain",
  ])) {
    return "General Physician";
  }

  /// Default fallback
  return "General Physician";
}

bool _containsAny(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (text.contains(keyword)) {
      return true;
    }
  }
  return false;
}