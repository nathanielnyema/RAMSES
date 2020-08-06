# RAMSES
RAMSES is a real-time alerting and monitoring system for epiliptic seizures. The system is intended to be deployed on a server behind a given hospital’s firewall, where it will intermittently pull EEG data from the hospital network as it is recorded from Natus machines, run an algorithm on the backend to classify the likelihood of seizure activity, and update a web dashboard accordingly. As the system will be deployed behind the hospital firewall, only individuals with designated access who are logged into the hospital system can view the web pages. 

## Software requirements
Generally, any server running this application must have [MATLAB R2018b](https://www.mathworks.com/products/new_products/release2018b.html) (or newer), [Python 3](https://www.python.org/downloads/), [redis](https://redis.io/download), and [MongoDB](https://docs.mongodb.com/manual/installation/) installed.
__NOTE:__ _Future versions of RAMSES will be entirely Python-based, eliminating the need for MATLAB._

### MATLAB Dependencies
These can all be installed from the MATLAB user interface under the tab for Apps.
* Wavelet Toolbox
* Signal Processing Toolbox
* Statistics and Machine Learning Toolbox
* IEEG Toolbox (only needed for demo purposes)

## Installing Dependencies
__NOTE:__ _We recommend building and running RAMSES inside of a Python [virtual environment](https://docs.python.org/3/tutorial/venv.html) in order to avoid conflicts with any preinstalled packages._

We are currently working towards docker containerizing the app; in the meantime, however, one can follow these steps to install all of the dependencies:
1. Make sure you've built the [matlab engine for python](https://www.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html) on your local device.
2. Build the [ieeg python package](https://github.com/ieeg-portal/ieegpy) and [create an ieeg.org account](https://main.ieeg.org/?q=user/register) if you have not already done so.
3. Run the following command:
```bash
python3 -m pip install -r requirements.txt
```

## Running the app
1. To start the app run the command `bash start_app.sh <path to your mongo installation directory>/bin`. For more information on the mongo installation directory and the need for this argument see the MongoDB [documentation](https://docs.mongodb.com/manual/mongo/).

## Notes on using the interface
Once everything is set up you can access the dashboard from your browser of choice by navigating to port 5000 on your localhost. The home page will be blank at first, though, because the database is reset before the first request to the flask app. In the process, all beds are set to inactive (i.e. all beds are empty). To start mock streaming you'll need to manually add a patient to a bed. To do this, open the menu in the top left corner and navigate to the options page. Here you can enter any arbitrary patient name and a number from 1-16 as the bed id. For demo purposes these bed ids map to the dataset names on ieeg (1-16 maps to RID0060 to RID0075). When you see that you've successfully added a patient you can then navigate back to the home page. The patient still won't appear for some time until a non-artifact prediction has been made by the classifier (note predictions are made every 10 seconds).

## Contact
Reach out to [Nathaniel Nyema](mailto:nyema@seas.upenn.edu), [Ola Owoputi](mailto:owo@seas.upenn.edu), [Elom Dumenyo](mailto:edumenyo@seas.upenn.edu), or [Shyon Small](mailto:shyons@seas.upenn.edu).
