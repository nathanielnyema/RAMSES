# Seizure Detection Classifier

This folder (adapted from [jbernabei/ICU_EEG_Final](https://github.com/jbernabei/ICU_EEG_Final/)) contains the random forest classifer, implemented in MATLAB.
To train and/or test the model, follow the instructions in `run_all_experiments.m`.

This folder is organized as follows:
- **Data**: This has the annotation files for all patients we are using in the project. The format is .mat files where each patient has fields that describe seizure start and stop times as well as interictal start and stop times.
- **Features**: This folder is where calculated feature files will go which also store patient specific annotations.
- **Models**: This contains trained machine learning models.
- **Results**: This contains model evaluation results.
