The first extension point that is loaded in a Blocks based application. Plugins that need to start immeditatly can extend from this point, but normally it's better for them to extend from the `com.blocks.BLifecycle.lifecycle` extension point where they have finner control over the specific stage of application startup where the callback will be made.

## Examples:

In this configuration example the class method `[MyController sharedInstance]` will be sent early in the Blocks startup process. This configuration markup should be added to the Plugin.xml file of the plugin that declares the `MyController` class.

    <extension point="com.blocks.Blocks.main">
        <callback class="MyController sharedInstance" />
    </extension>