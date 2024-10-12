# AGraph

This is a swift app developed for the course "Sviluppo applicazioni per dispositivi mobili" which uses some powerful features of Arkit framework.

AGraphs allows to place and render agumented 3d graphs (described by csv tables stored in a dropbox directory)
through an iphone camera.

# Application features

The application allows to:
<ul>
  <li><b>Display 3d graphs described by csv files</b></li>
  <li><b>Move or remove 3d graphs from the Augmented Reality scene</b></li>
  <li><b>Take picture of the Augmented Reality scene</b></li>
  <li><b>Print coordinates of Augmented 3d points</b></li>
</ul>

# Project Usage

The project uses SwiftyDropbox libraries, to access, retrieve and download files from a dropbox directory.

In order to add all missing dependencies, run 'pod install' from the project directory.

At the end of the process, open 'ProjectMobidev.xcworkspace' with XCode.

The app has been developed for <b>iOS 12.2</b>.

# Graph format

Each csv must store points following this format:

Title of the graph

x;y;z;r;g;b

x;y;z;r;g;b

The first line is the title that will be displayed over the graph, while all lines under are 3d points with their relative colors.

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

The result on the application is shown below:

</br><p align="center">
  <img width="375" height="667" src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/example.jpg">
</p></br>

Some examples are available in the directory <a href="https://github.com/Kegbird/ProjectMobidev/tree/master/Examples">"/Examples/"</a>.

# Application usage

The application plots graphs over this image marker:

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/marker.jpeg">
</p></br>

The marker image is in "/Image/marker.jpeg" and can be changed with whatever image you want.

To plot a graph, you must first tap on the add button at the bottom right of the screen.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/1.PNG">
</p></br>

If it's the first time that you use it, AGraph will ask you to access to your Dropbox folder.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/2.PNG">
</p></br>

If the authentication is succesful, then the app will display all .csv files available in your dropbox directory.
Choose one or more graphs to display.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/3.PNG">
</p></br>

Finally aim towards the marker until the first selected graph will appear.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/4.PNG">
</p></br>

Once you have decided the best position for it, tap on screen to confirm its location; you have to do so for all previously selected graphs.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/5.PNG">
</p></br>

After you placed all graphs, you can read each point position by just aiming at it.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/6.PNG">
</p></br>

A long press over a graph will let you enable the edit mode; in edit mode all graphs can
be moved by panning.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/7.PNG">
</p></br>

You can also take photos of the AR scene through the camera button.

</br><p align="center">
  <img src="https://raw.githubusercontent.com/KegBird/ProjectMobidev/master/Images/Tutorial/8.PNG">
</p></br>

# Application limits

The application runs smoothly with no fps drops, if the overall number of
points drawn is approximately under 900.

The application doesn't let to display more than 1000 points for stability reasons.
