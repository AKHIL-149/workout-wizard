# Fitness Recommender System

A machine learning-based recommendation system that provides personalized workout programs based on individual fitness profiles, goals, and preferences.

## 🏋️‍♀️ Overview

This project implements a hybrid recommendation system for fitness programs that combines content-based and collaborative filtering approaches. The system analyzes user attributes (fitness level, goals, equipment availability) and program characteristics to suggest optimal workout plans tailored to individual needs.

## ✨ Features

- **Hybrid Recommendation Engine**: Combines content-based filtering with collaborative filtering for more accurate suggestions
- **Personalized Matching**: Recommends programs based on fitness level, goals, available equipment, and training preferences
- **Flexible Parameter Tuning**: Optimized weights between content-based and collaborative filtering components
- **High Match Accuracy**: Achieves 80%+ match rate across multiple evaluation metrics
- **Interactive Demo**: Jupyter notebooks for testing the system with your own preferences

## 📊 Dataset

The system is trained on a dataset containing:
- 1500+ fitness programs with detailed attributes
- Program metadata including difficulty level, duration, equipment requirements
- User preference data for collaborative filtering

## 🔧 Technologies Used

- Python 3.8+
- pandas & NumPy for data processing
- scikit-learn for machine learning components
- Jupyter notebooks for interactive demos
- Matplotlib & Seaborn for data visualization

## 🚀 Getting Started

### Prerequisites
- Python 3.8 or higher
- pip or conda for package management

### Installation

1. Clone the repository:
```bash
git clone https://github.com/AKHIL-149/workout-wizard.git
cd workout-wizard
```

2. Install required packages:
```bash
pip install -r requirements.txt
```

3. Run the demo notebook:
```bash
jupyter rs_test.ipynb
```

## 📖 How It Works

The recommendation system operates in three main steps:

1. **Content-Based Filtering**: Analyzes the attributes of fitness programs and matches them with user preferences.

2. **Collaborative Filtering**: Identifies similar users and recommends programs that these similar users preferred.

3. **Hybrid Recommendations**: Combines both approaches with optimized weights (found through evaluation) to provide the most relevant suggestions.

## 📁 Repository Structure
```
fitness_rms/
├── .ipynb_checkpoints/        # Jupyter notebook checkpoints
├── enhanced_fitness.csv       # Enhanced dataset with additional features
├── fit.ipynb                  # Main analysis and model development notebook
├── fitness_program.json       # Raw fitness program data
├── fitness_recommendation_model.pkl  # Saved recommendation model
├── fitness_users_trail_data.csv      # User data for training/testing
├── fitness_users.json         # User profile data
├── json_transform.py          # Utilities for JSON processing
├── processed_programs.csv     # Processed program data
├── program_features.csv       # Extracted program features
├── rs_test.ipynb              # Model testing notebook
└── texput.log                 # Log file
```

## 📊 Evaluation Results

The system was evaluated on multiple metrics:

- **Level Match Rate**: 99%
- **Goal Match Rate**: 54% 
- **Equipment Match Rate**: 98%
- **Workout Time Match Rate**: 62%
- **Workout Frequency Match Rate**: 100%
- **Overall Match Rate**: 83.6%

## 🔍 Example Usage
```python
# Load the model
with open('fitness_recommendation_model.pkl', 'rb') as f:
    model = pickle.load(f)

# Create a user profile
user_profile = {
    'fitness_level': 'Intermediate',
    'goals': ['Weight Loss', 'Strength'],
    'equipment': 'Full Gym',
    'preferred_duration': '60-75 min',
    'preferred_frequency': 4,
    'preferred_style': 'Upper/Lower'
}

# Get personalized recommendations
recommendations = get_program_recommendations(user_profile)
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👏 Acknowledgments

- Dataset inspired by real-world fitness programs
- Thanks to the scikit-learn team for their excellent machine learning tools
- Special thanks to all contributors who helped improve this system