# AGraph

This is a simple swift app, developed for the course "Sviluppo applicazioni per dispositivi mobili".

This app allows to place and render agumented 3d graphs (described by csv tables on a dropbox directory)
through an iphone camera.

# Usage

The project uses SwiftyDropbox libraries, to access, retriev and download files from a dropbox directory.

To add all missing dependencies, run 'pod install' from the project directory.

At the end of the process, open 'ProjectMobidev.xcworkspace' with XCode.

# Graph format

Each csv must store points in this structure, in order to be recognized by the application:

Title of the graph
x;y;z;r;g;b
x;y;z;r;g;b
.
.
.

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

![alt text](https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/example.jpg)

Some examples are available in the directory "/Examples/"; to make available to the app your graphs,
just put them into your dropbox as .csv files.

# Application usage

The application plots graphs over this image marker:

![alt text](https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/marker.jpeg)

The marker image is in "/Image/marker.jpeg".

To plot graph with AGraph you must first tap on the add button, in the bottom right of the screen.

If it's the first time that you use it, AGraph will ask you to access to your Dropbox folder.

If the authentication is succesful, then the app will display all .csv files, presents in your dropbox.

Choose one or more graphs to display.

Finally aim towards the marker, until a graph will appear.

For each graph, tap on the screen to confirm their positions.

When you place all the graph, you can read each point position, by just aiming at it.

A long press over the graph will let you also to move graphs onto the blackboard.

You can take photos of the ar scene, by tapping on the camera button.

# Application limits

The application runs smoothly, with no fps drops if the overall number of
points drawn is under 900.
The application itself could drawn up to 1200
This limit is valid for Iphone 6s.
