# AGraph

This is a simple swift app, developed for the course "Sviluppo applicazioni per dispositivi mobili".

This app allows to place and render agumented 3d graphs (described by csv tables stored in a dropbox directory)
through an iphone camera.

# Application features

The application can:
<ul>
  <li><b>Display 3d graphs described by csv files</b></li>
  <li><b>Move or remove 3d graphs from the Agmented Reality scene</b></li>
  <li><b>Take picture of the Agmented Reality scene</b></li>
</ul>

# Project Usage

The project uses SwiftyDropbox libraries, to access, retriev and download files from a dropbox directory.

To add all missing dependencies, run 'pod install' from the project directory.

At the end of the process, open 'ProjectMobidev.xcworkspace' with XCode.

The app has been developed for <b>iOS 12.2</b>.

# Graph format

Each csv must store points in this structure, in order to be recognized by the application:

Title of the graph

x;y;z;r;g;b

x;y;z;r;g;b

The first line is the title that will display over the graph, while all lines under are 3d points with their relative colors.

This example may clarify everything:

Diagonal

0;0;0;255;238;75

10;10;10;255;74;74

20;20;20;100;228;255

30;30;30;76;255;124

40;40;40;255;103;164

50;50;50;255;238;75

60;60;60;255;74;74

70;70;70;100;228;255

80;80;80;76;255;124

90;90;90;255;103;164

100;100;100;255;238;75

And this is what the application produces:

</br><p align="center">
  <img width="375" height="667" src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/example.jpg">
</p></br>

Some examples are available in the directory <a href="https://github.com/Kegbird/ProjectMobidev/tree/master/Examples">"/Examples/"</a>; to make available to the app your graphs,
just put them into your dropbox as .csv files.

# Application usage

The application plots graphs over this image marker:

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/marker.jpeg">
</p></br>

The marker image is in "/Image/marker.jpeg".

Graphs are positioned in front of the marker, in this way:

To plot graph with AGraph you must first tap on the add button, in the bottom right of the screen.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/1.PNG">
</p></br>

If it's the first time that you use it, AGraph will ask you to access to your Dropbox folder.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/2.PNG">
</p></br>

If the authentication is succesful, then the app will display all .csv files, presents in your dropbox.
Choose one or more graphs to display.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/3.PNG">
</p></br>

Finally aim towards the marker, until a graph will appear.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/4.PNG">
</p></br>

For each graph, tap on the screen to confirm their positions.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/5.PNG">
</p></br>

When you place all the graph, you can read each point position, by just aiming at it.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/6.PNG">
</p></br>

A long press over the graph will let you enable the edit mode; in edit mode, graphs can
be moved with the pan gesture.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/7.PNG">
</p></br>

You can take photos of the ar scene, by tapping on the camera button.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/8.PNG">
</p></br>

# Application limits

The application runs smoothly, with no fps drops, if the overall number of
points drawn is under 900.

The application doesn't let to display more than 1000 points, for stability reasons.

This limit derives from a sequence of tests, done on an Iphone 6S.
