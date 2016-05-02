
Hi there and welcome to the Lux Shader framework!

Before you can dive into Lux and explore its features you will have set up your project properly to ensure that everythig work like it is intended.

# Setting up your Project
In case you use deferred rendering you have to assign the “Lux Internal-DeferredShading” shader:
1. Go to “Edit” -> “Project Settings” -> “Graphics” -> “Built in shader settings” -> “Deferred” and set it to “Custom”.
2. Assign the “Lux Internal-DeferredShading” shader to the new slot (The shader is located in the folder: “Lux Shaders/Lux Core/Resources”).
3. Lux Pro only: You have to assign the custom deferred reflection shader “Lux Internal-DeferredReflections” too. You will find it in the same folder as the deferred lighting shader.

You should also make sure that your project uses linear color space (“Edit” -> “Project Settings” -> “Player” -> “Other Settings” -> “Color space”) and your camera is set to “HDR”.

# Setting up your Scenes
Lux has been written having deferred shading in mind. And as the size of unity’s gbuffer is rather large but still limited not all shading parameters can be setup per material and some parameters have to be defined globally.
For this reason each scene which you would like to use Lux driven shaders in need the “Lux Setup” script to be present.
In case you want to use dynamic weather you have to also add the “Lux Dynamic Weather” script.
Please have a look at the provided demo scenes.

When done you should be ready to go.


Docs: https://docs.google.com/document/d/19LM0qbnUSrdgR_Eb5eWTBLbPfiEAoM2jijPV_-7GZKg/edit?usp=sharing

