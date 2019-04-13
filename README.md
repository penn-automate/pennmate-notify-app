# Pennmate Notify
<img src="https://www.seas.upenn.edu/~hanbangw/assets/images/pennmate/pennmate-notify.png" alt="Pennmate Notify" width="200"/>

## Introuduction

The notification by email is not stupid&mdash;it's just slow. The process of sending emails is not concurrent; The email would take much more time to actually arrive at your inbox; Massive emails from the same address could trigger anti-spam; The message might simply won't pop-up, or easily mixed with other of your emails.

Also, there will be privacy concerns if you give out your email and the course you want to be in at the same time. The data could be easily correlated to your individual identity and used to figure out how you planned your schedule. I heard<sup>[<i>citation needed</i>]</sup> that PennLabs is already doing this when you fill in your course on Penn Mobile.

So now forget about all that and embrace **Pennmate Notify**. An app that pushed simplicity and functionality to its maximum and does nothing other than telling you the course is open at the shortest notice.

This app would also not collect your data because it has no ability to do so. The app would never interact with any of my servers nor send any data to anyone other than Google. When it communicates with Google, your device will generate a unique ID for push notification, and I won't be able to know that ID whatsoever. Everything is stored locally.

The backend that gets the status of the courses is the same with PCN or PCA. The difference is that my backend is written in Go, which is faster and ｓｕｐｅｒｉｏｒ in many ways.

## Usage

The usage is simple after installation: just input the course and section ID you want to be in, wait and receive a push notification as soon as the section is open.

## Screenshots

<div style="display: block;">
<img width="50%" alt="notify-home" src="https://www.seas.upenn.edu/~hanbangw/assets/images/pennmate/notify-home.jpg"/>

<img width="50%" style="float: right;" alt="notify-message" src="https://www.seas.upenn.edu/~hanbangw/assets/images/pennmate/notify-message.jpg"/>
</div>

## Installation

This app is written in [Dart](https://www.dartlang.org/) and uses the [Flutter](https://flutter.dev/) framework. It is natively a cross-platform app, meaning that it can run on both iOS and Android devices.

Unfortunately, it is not possible to install an app from an unknown source on unjailbreaked iOS devices. The only way for me is to obtain a developer account from Apple, which would cost me $99/yr. <small>im cute plz give me money</small>

Although it would also cost money to publish the app in Google Play, users can install a third-party apk without any extra modification. Just make sure you **DON'T click on OK when the prompt pops up**, which asks you to NOT install from an unknown developer. If you did so, you'll have to turn off the protection in Google Play settings.

***APK download (ver. 0.1) for ARM:*** [pennmate-notify-0.1.apk](https://github.com/penn-automate/pennmate-notify-app/releases/download/v0.1/pennmate-notify-0.1.apk)  
<small>\*Make sure your device's CPU set is ARM or ARM64. If you need x86 version plz comment below.</small>

## Changelog

- v0.1: Initial public release. Fixes adding duplicate course.
- v0.1b: Initial beta release. Add custome logo and versioning. 
- v0.1a: Initial alpha release.