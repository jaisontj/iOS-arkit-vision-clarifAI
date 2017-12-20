# iOS-arkit-vision-clarifAI

![Demo](https://raw.githubusercontent.com/jaisontj/iOS-arkit-vision-clarifAI/master/assets/arkit_demo.gif "Demo")

Point the phone at a celebrity (or a picture of a celebrity), the name and the date of birth of the celebrity will be printed on screen as an AR object.

The app uses the iOS vision API to detect faces on the screen, it then crops out the face and sends this image to [ClarifAI](https://clarifai.com/) to identify the celebrity. The name of the celebrity is then used to get their date of birth from [TheMovieDB](https://www.themoviedb.org/). 

Hasura is used to host a nodejs express app which receives the celebrity name and then queries TheMovieDB accordingly to get the date of birth.

# Deploy 

## Step 1: Get the project and deploy

```sh
$ hasura quickstart jaison/arkit
$ cd arkit
$ git add . && git commit -m "First commit"
$ git push hasura master
```

## Step 2: Setup account at themoviedb

Get an account at [TheMovieDB](https://www.themoviedb.org/) and then get an API key (head to your account settings).

Once you have the API key, add this to your hasura secrets

```sh
$ hasura secret update mbd.api.token <your-mdb-api-token>
```

## Step 3: Tweak iOS app

```sh
# Assuming you are inside the arkit directory
$ cd iOS_app
# The app uses Alamofire to make the API calls, install the pod
$ pod install
```

Once you have installed the pods, open up the iOS app in Xcode (`ArSample.xcworkspace`).

Navigate to `HasuraApiHelper.swift` and change `CLUSTER_NAME` to your Hasura cluster name.

To know the name of your cluster,

```sh
$ hasura cluster status
```

```swift
static let CLUSTER_NAME = <Your-Cluster-Name> //Replace <Your-Cluster-Name> with the name of your cluster
```

## Step 4: Run the iOS app

Run the iOS, give the app some time to set up the camera, once that is done, point it at an image of a celebrity and tap on the screen.

## Acknowledgements

[FaceRecognition-in-ARKit](https://github.com/NovaTecConsulting/FaceRecognition-in-ARKit)
