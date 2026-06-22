 Smart Heat Tracker
- This is an Apple Watch and iPhone companion application that monitors physiological heat stress using wearable sensor data and delivers actionable insights during physical activity.

 Overview
- Smart Heat Detection is a health and fitness monitoring application for the Apple ecosystem. 
- It leverages Apple Watch sensor data to analyze physiological responses associated with heat stress and physical exertion, presenting users with intuitive dashboards, historical trends, and personalized insights.
- This is privacy first application that does not use cloud in any way. All the data is stored offline SQLite database, where data is first de-identified.
 Motivation
- Heat-related illnesses affect thousands of athletes, outdoor workers, and individuals exercising in demanding environments each year. This project investigates whether wearable sensor data can provide meaningful, 
real-time information about physiological heat stress and thermal strain.

 Screenshots of the application:

<img width="250" height="541" alt="0x0ss" src="https://github.com/user-attachments/assets/637aa008-79ab-41a7-af6e-9e8c2bcb74d4" />
<img width="250" height="541" alt="0x0ss (1)" src="https://github.com/user-attachments/assets/4e4e788d-57dd-4a02-814d-20b46d70310e" />
<img width="250" height="541" alt="0x0ss (2)" src="https://github.com/user-attachments/assets/ae75aca3-48fe-40e4-9fcb-43bc0b4e47c2" />
<img width="250" height="541" alt="0x0ss (3)" src="https://github.com/user-attachments/assets/e4856dea-e6e2-4516-bc09-4a649c158ea3" />
<img width="250" height="541" alt="0x0ss (4)" src="https://github.com/user-attachments/assets/9e8f0005-5190-47cd-bc47-6757a0a2c4b8" />
<img width="250" height="541" alt="0x0ss (5)" src="https://github.com/user-attachments/assets/c00d5782-cbb9-4138-8ef4-8188f66f6893" />
<img width="250" height="541" alt="0x0ss (6)" src="https://github.com/user-attachments/assets/96924a53-a7f0-4fcc-8782-e7219c106875" />
<img width="250" height="541" alt="0x0ss (7)" src="https://github.com/user-attachments/assets/61272b86-5ff0-4a45-9889-9e94521ed086" />
<img width="150" height="183" alt="0x0ss (8)" src="https://github.com/user-attachments/assets/7894db79-8d20-4180-a116-29c9bf951f05" />
<img width="150" height="183" alt="0x0ss (9)" src="https://github.com/user-attachments/assets/87cf0b2a-c799-4ad4-bbce-c69e217796a1" />
<img width="150" height="183" alt="0x0ss (10)" src="https://github.com/user-attachments/assets/c29b4534-64fb-4886-ab85-432405562018" />
<img width="150" height="183" alt="0x0ss (11)" src="https://github.com/user-attachments/assets/c09c681a-f214-4942-8d34-c592c6534bd6" />


 Secondary objectives included:
- Gaining hands-on experience with SwiftUI and HealthKit APIs
- Building a companion Apple Watch application
- Exploring health data visualization techniques
- Understanding the regulatory and validation landscape for health technology


 Features
- Real-Time Core body heat estimation including alerts. 
- Streams live metrics from Apple HealthKit:
- Heart Rate
- Step Count
- Distance Traveled
- Active Calories Burned
- Activity Data

 Historical Trends
- Interactive dashboards for visualizing health and activity data across daily, weekly, and monthly timeframes, with metric comparisons and pattern analysis.

 Apple Watch Integration
- A companion watchOS application that collects sensor data, synchronizes with HealthKit, and surfaces key metrics on-device.

 SwiftUI Interface
- Built entirely in SwiftUI with dark mode support, responsive layouts, interactive charts, and native Apple design conventions.
 User Profiles
- Configurable profiles for personal information, preferred measurement units, and application preferences.

 Technology Stack
- CategoryDetails: 
- Language: Swift
- Frameworks: SwiftUI, HealthKit, WatchKit, CombinePlatformsiOS, watchOSToolsXcode, Git, GitHub

 Algorithm: 
- We the EC Temp algorithm to estimate the core body temperature based on the heart rate in real time. 
Reseach paper used for reference: Looney, David & Buller, Mark & Gribok, Andrei & Leger, Jayme & Potter, Adam & Rumpler, William & Tharion, William & Welles, Alexander & Friedl, Karl & Hoyt, Reed. (2018). Estimating Resting Core Temperature Using Heart Rate. Journal for the Measurement of Physical Behaviour. 1. 1-7. 10.1123/jmpb.2017-0003. 

 Architecture
<img width="572" height="668" alt="smart_heat_detection_architecture" src="https://github.com/user-attachments/assets/bc18088c-420f-42c0-9845-0b02d73f2888" />


 Privacy
- All health data remains within Apple's HealthKit ecosystem.
- No third-party analytics are used.
- No health data is sold or shared with external parties.
- Explicit user authorization is required before any health data is accessed.


 Disclaimer
- Smart Heat Detection is a software engineering and research project intended for informational and educational purposes only.
- It is not a medical device and must not be used for diagnosis, treatment decisions, or emergency response. 

 Challenges & Lessons Learned
- HealthKit Integration
- Working with HealthKit required careful handling of authorization workflows, data permissions, background delivery, and sensor limitations.

 Wearable Data Interpretation
- A key insight from this project was recognizing the distinction between collecting physiological data, interpreting it, and scientifically validating health-related conclusions.
- This underscored the importance of rigorous validation, regulatory awareness, and responsible development practices in health technology.

 App Store Submission
- The project provided direct experience with App Store Connect, TestFlight, metadata preparation, and Apple's health application review requirements.
- It unfortunately was not approved beacuse we could not conduct pilot studies and write a paper about the results. 

 Future Work

- Advanced heat stress modeling algorithms
- Machine learning–based analytics
-  Cloud synchronization
- Expanded watchOS functionality
- Additional HealthKit metric integrations
- Scientific validation studies

 Acknowledgements

- Apple HealthKit Documentation
- SwiftUI Community
- Arizona State University faculty and peers
