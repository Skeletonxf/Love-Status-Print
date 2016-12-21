# Love-Status-Print
Overrides the print function in lua to also print the messages briefly onto the screen and then fade out

This project is a lua module for love2d to easily use the lua print command and see the results in game on the screen. Messages are briefly printed onto the screen before fading out and the module leaves the origional print behaviour still working.

Messages that can't be made into meaningful string messages yet are printed as their type, or you can go into error mode and make those values throw an error instead.

The module only prints the first value handed to print()