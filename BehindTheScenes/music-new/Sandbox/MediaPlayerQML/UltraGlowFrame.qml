import QtQuick 2.15
import Qt5Compat.GraphicalEffects 6.0

Item {
    id: root                            // we called it root which is a convention for a top level item
    property url source                // Image path
    property Item target
    
    property real glowScale: 0      // How far the bloom spreads was 1.8 ie 180% of the image size
    property real blurOne: 0       // First blur radius to soften the glow was 60 zero = hard edge a 60 pixel overlap
    property real blurTwo: 0         // Second blur radius smooths it further was 45 ... pixel overlap
    property real goldOpacity: 0   // Strength of opacity golden colour was o.35 0 is no gold tint
    property color glowColor: "#e5dfc4ff" // NEW: customizable glow color cant set to zero but can be transparent
    property real glowRadius: 10  // NEW: customizable glow radius, the bigger the radius the further it spreads was 15 0 = no rim 
                                    // glow 15 is a 15 pixel blurring radius
    property real glowSpread: 0.25    // how much the glow bleeds outward, high spread = thicker glow band was0.25
                                    //- Visually, it produces a moderately thin rim glow: 1 is maximum .25 is 25%

    property real glowOpacity: 0.4   // overall strength of the glow higher = thicker glow  was 0.8
                                    // 1.0 is solid It will dominate the edges unless balanced with a lighter color or larger blur radius.

    //- Instead of hard‑coding values inside UltraGlowFrame.qml, you expose them as properties so you can override
    // them from CarouselView.qml (or anywhere else).
    //- Instead of hard‑coding values inside UltraGlowFrame.qml, you expose them as properties
    // so you can override them from CarouselView.qml (or anywhere else).



    // Ensures the component behaves like an image
    width: imageItem.implicitWidth
    height: imageItem.implicitHeight
    //- You’re telling the root Item (UltraGlowFrame) to adopt the natural size of the image inside it.
    //- This ensures the component behaves like a plain image by default:
    //- If the image is 400×300 pixels, the UltraGlowFrame will also be 400×300.
    //- If you swap in a different image, the frame resizes automatically.

    //--------------------------------------------------------------------
    // 1. Main image
    //--------------------------------------------------------------------
    Image {
        id: imageItem
        anchors.fill: parent
        source: root.source
        //so when a view wants to display an image it calls for a frame. passing in a aurl of the image
        //root.source is that url
        fillMode: Image.PreserveAspectFit
        smooth: false        //smooth is softened not pixel sharp
        antialiasing: true  //when images are drwn and changed jagged edges can appear, this smooths them
        z:0    // minus values are shown behind the image
    }

    //--------------------------------------------------------------------
    // 2. Bloom glow system
    //--------------------------------------------------------------------

    // High-resolution buffer to increase blur spread
    //this is a key piece of how your glow/blur effects are actually applied. 
    // It’s a QML type that lets you take the output of one item (like your Image) and feed it into a shader or effect (e.g. Glow, GaussianBlur, DropShadow).


    ShaderEffectSource {
        id: srcOuter
        visible: false          // we dont want to see it, its a temporary object that we will work on and later
                                //associate with the image as a layer
        sourceItem: imageItem   //it applies this effect to this source ie the image, a frame/Item is a non visual image and cant be used
                                //it has no pixels of its own The frame enables the image and effects to be combined
                                //but has no drawable surcae of its own
        smooth: true            //- Effect: The copied texture looks polished and soft when resized, avoiding jagged edges.

        hideSource: false       //the original image stays visible, and the snapshot is available for effects.
                                //a snapshot is a copy of the image that has effects added

        mipmap: true            //When you expect zooming, scaling, or heavy blur — mipmaps prevent aliasing and shimmering.

        width: imageItem.width * root.glowScale     //so a glowscale of 1.8 adds 80% to the width oh the image
        height: imageItem.height * root.glowScale   //it should be a lot less than 50% of the gap between inages


        // This is the heart of how your snapshot is expanded and centered for the glow.
        //- sourceRect defines the portion of the source item (imageItem) that the ShaderEffectSource will capture.
        //- It’s expressed as a rectangle:
        //so it takes all the values that we have applied and calculates the impact area of the effect plus image size

        sourceRect: Qt.rect(
            -imageItem.width * ((root.glowScale - 1) / 2),
            -imageItem.height * ((root.glowScale - 1) / 2),
            imageItem.width * root.glowScale,
            imageItem.height * root.glowScale
        )
    }


    // when an image is missing this relaces it with a background blurred gold panel its not essential
    // this property is not called anywhere but when you create it it becomes part of the QML object tree
    //and is rendered with all other objects in here
    // the -4 is about layer stacking, if 2 objects have the same number the order is as defined in the code
    //ie anything defined after goldenlayer will appear on top of it
    // Golden tint background
    Rectangle {
        id: goldenLayer
        anchors.fill: imageItem
        color: "#FFD700"
        opacity: root.goldOpacity
        z: -4
    }

    // First wide blur
    GaussianBlur {
        id: blur1
        anchors.fill: imageItem
        source: srcOuter        //this ties in with sourceRect above the envelope size after adding effects
        radius: root.blurOne
        samples: 32         //More samples = smoother, higher‑quality blur. 32 lookups per pixel so its set to high
        opacity: 0.85
        z: -3
    }

    // Second softening blur
    GaussianBlur {
        id: blur2
        anchors.fill: imageItem
        source: blur1       //takes the previous GaussianBlur as its source
        radius: root.blurTwo
        samples: 32
        opacity: 0.75
        z: -3
    }

    //--------------------------------------------------------------------
    // 3. Rim glow
    //he glow is generated directly from the image itself, not from an expanded snapshot like your wide blur layers.
    //
    //--------------------------------------------------------------------
    Glow {
        id: innerGlow
        anchors.fill: imageItem
        source: imageItem
        radius: root.glowRadius   //- radius → Controls how far the glow extends outward.
                                   


        spread: root.glowSpread  //- spread → Controls how tightly the glow hugs the edges (low spread = diffuse, high spread = sharp rim).
                                    //- Low values (0.0 – 0.3)
                                    //- Glow is very soft, almost mist‑like.
                                    //- Edges blur into the background.
                                    //- Good for atmospheric halos.
                                    //- Medium values (0.4 – 0.6)
                                    //Balanced glow: visible rim highlight but still 
                                    //some diffusion outward.
                                    //- Often used for subtle UI accents.
                                    //- High values (0.7 – 1.0)
                                    //- Glow is tight and intense at the edge.
                                    //- Looks like a neon rim or outline.
                                    //- Great for “rim glow” effects where you want the subject to pop sharply.


        color: root.glowColor
        opacity: root.glowOpacity
        z: -2
    }


    //--------------------------------------------------------------------
    // 4. Depth shadow
    //
    //--------------------------------------------------------------------
    DropShadow {
        id: shadow
        anchors.fill: imageItem
        source: imageItem //The shadow is generated from the image itself, just like rim glow.
        radius: 18 //Controls how soft the shadow edges are. Larger radius = softer shadow.
        samples: 16
        horizontalOffset: 4 //Pushes the shadow diagonally (here, 4px right and 4px down).
        verticalOffset: 4   //That’s what makes it look like a cast shadow rather than a halo.
        color: "#40000000"
        z: -5
    }
}
