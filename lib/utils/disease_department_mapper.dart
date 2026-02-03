String mapDiseaseToDepartment(String disease) {
  const Map<String, String> diseaseToDepartment = {
    "Malaria": "General Physician",
    "Typhoid": "General Physician",
    "Flu": "General Physician",
    "Diabetes": "Endocrinologist",
    "Heart Attack": "Cardiologist",
    "Migraine": "Neurologist",
    "Skin Allergy": "Dermatologist",
  };

  return diseaseToDepartment[disease] ?? "General Physician";
}
