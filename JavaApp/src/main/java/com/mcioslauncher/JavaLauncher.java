package com.mcioslauncher;

import java.io.*;
import java.lang.reflect.*;
import java.net.*;
import java.nio.*;
import java.nio.file.*;
import java.util.*;
import java.util.jar.*;

/**
 * Java Launcher - boots Minecraft: Java Edition on iOS
 * 
 * This is written from scratch - handles:
 * - Classpath construction from version JSON
 * - Native library loading (LWJGL, SDL3)
 * - JVM arguments parsing
 * - Minecraft main class invocation
 */
public class JavaLauncher {
    
    private static final String TAG = "MCLauncher";
    
    // Native method to get the iOS bundle path
    private static native String getBundlePath();
    private static native String getDocumentsPath();
    private static native void logToNSLog(String message);
    
    public static void main(String[] args) {
        log("JavaLauncher starting, args: " + Arrays.toString(args));
        
        try {
            // Parse launch arguments from native side
            LaunchConfig config = parseLaunchConfig(args);
            
            // Set up the environment
            setupEnvironment(config);
            
            // Load native libraries
            loadNativeLibraries(config);
            
            // Build and set classpath
            ClassLoader classLoader = buildClassLoader(config);
            
            // Find and invoke Minecraft's main class
            invokeMinecraftMain(config, classLoader);
            
        } catch (Exception e) {
            log("Launcher failed: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    private static LaunchConfig parseLaunchConfig(String[] args) throws Exception {
        // Args format: --config=<path> or JSON string directly
        LaunchConfig config = new LaunchConfig();
        
        for (String arg : args) {
            if (arg.startsWith("--config=")) {
                String configPath = arg.substring(9);
                config = LoadConfig.fromJson(new String(Files.readAllBytes(Paths.get(configPath))));
            } else if (arg.startsWith("{")) {
                // Direct JSON
                config = LoadConfig.fromJson(arg);
            }
        }
        
        return config;
    }
    
    private static void setupEnvironment(LaunchConfig config) {
        // Set game directory
        System.setProperty("gameDir", config.gameDir);
        System.setProperty("minecraft.dir", config.gameDir);
        
        // Set assets directory
        System.setProperty("assetDirectory", config.assetsDir);
        
        // Set LWJGL version (for version detection)
        System.setProperty("lwjgl.version", config.lwjglVersion);
        
        // Set renderer preference
        System.setProperty("mcios.renderer", config.renderer);
        
        // Java system properties for Minecraft
        System.setProperty("java.awt.headless", "true");
        System.setProperty("awt.headless", "true");
        
        // iOS-specific properties
        System.setProperty("os.name", "Mac OS X"); // Minecraft checks this for Mac paths
        System.setProperty("os.arch", "aarch64");
        System.setProperty("os.version", System.getProperty("os.version"));
        
        log("Environment setup complete, gameDir=" + config.gameDir);
    }
    
    private static void loadNativeLibraries(LaunchConfig config) throws Exception {
        log("Loading native libraries from: " + config.nativesDir);
        
        File nativesDir = new File(config.nativesDir);
        if (!nativesDir.exists()) {
            throw new RuntimeException("Natives directory not found: " + config.nativesDir);
        }
        
        // Load libraries in dependency order
        String[] libOrder = {
            // Core SDL3
            "SDL3",
            
            // LWJGL core
            "lwjgl",
            "lwjgl-glfw",
            "lwjgl-opengl",
            "lwjgl-openal",
            "lwjgl-stb",
            "lwjgl-vma",
            
            // Renderer (MobileGlues for shaders)
            "mobileglues",
            
            // Optional: spirv-cross for 26.2+
            "spirv-cross",
            
            // JNA (for Minecraft's native access)
            "jna"
        };
        
        for (String libName : libOrder) {
            try {
                String libPath = findLibrary(nativesDir, libName);
                if (libPath != null) {
                    log("Loading native: " + libPath);
                    System.load(libPath);
                } else {
                    log("Native library not found (optional): " + libName);
                }
            } catch (UnsatisfiedLinkError e) {
                log("Failed to load " + libName + ": " + e.getMessage());
                // Continue - some libs are optional
            }
        }
        
        log("Native library loading complete");
    }
    
    private static String findLibrary(File dir, String name) {
        // Try different naming conventions
        String[] patterns = {
            "lib" + name + ".dylib",
            name + ".dylib",
            "lib" + name + ".so",
            name + ".so"
        };
        
        for (String pattern : patterns) {
            File lib = new File(dir, pattern);
            if (lib.exists()) {
                return lib.getAbsolutePath();
            }
        }
        
        // Search subdirectories
        File[] subdirs = dir.listFiles(File::isDirectory);
        if (subdirs != null) {
            for (File subdir : subdirs) {
                String found = findLibrary(subdir, name);
                if (found != null) return found;
            }
        }
        
        return null;
    }
    
    private static ClassLoader buildClassLoader(LaunchConfig config) throws Exception {
        log("Building classpath...");
        
        List<URL> urls = new ArrayList<>();
        
        // Add Minecraft client JAR
        File clientJar = new File(config.minecraftJar);
        if (clientJar.exists()) {
            urls.add(clientJar.toURI().toURL());
            log("Added to classpath: " + clientJar.getAbsolutePath());
        } else {
            throw new RuntimeException("Minecraft JAR not found: " + config.minecraftJar);
        }
        
        // Add libraries
        File libsDir = new File(config.librariesDir);
        if (libsDir.exists()) {
            int libCount = 0;
            for (File lib : listJars(libsDir)) {
                urls.add(lib.toURI().toURL());
                libCount++;
            }
            log("Added " + libCount + " libraries to classpath");
        }
        
        // Add our launcher classes
        String launcherJar = System.getProperty("java.class.path").split(":")[0];
        urls.add(new File(launcherJar).toURI().toURL());
        
        // Create classloader with parent-first delegation
        ClassLoader parent = ClassLoader.getSystemClassLoader();
        URLClassLoader classLoader = new URLClassLoader(
            urls.toArray(new URL[0]),
            parent
        ) {
            @Override
            protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
                // Try parent first (for Java standard library)
                try {
                    return getParent().loadClass(name);
                } catch (ClassNotFoundException e) {
                    // Then try our URLs
                    return super.loadClass(name, resolve);
                }
            }
        };
        
        // Set as context classloader (Minecraft expects this)
        Thread.currentThread().setContextClassLoader(classLoader);
        
        log("ClassLoader built with " + urls.size() + " entries");
        return classLoader;
    }
    
    private static List<File> listJars(File dir) {
        List<File> jars = new ArrayList<>();
        listJarsRecursive(dir, jars);
        return jars;
    }
    
    private static void listJarsRecursive(File dir, List<File> jars) {
        File[] files = dir.listFiles();
        if (files == null) return;
        
        for (File file : files) {
            if (file.isDirectory()) {
                listJarsRecursive(file, jars);
            } else if (file.getName().endsWith(".jar")) {
                jars.add(file);
            }
        }
    }
    
    private static void invokeMinecraftMain(LaunchConfig config, ClassLoader classLoader) throws Exception {
        log("Invoking Minecraft main class...");
        
        // Minecraft's main class
        String mainClass = config.mainClass != null ? config.mainClass : "net.minecraft.client.main.Main";
        
        // Load the class
        Class<?> mainClazz = classLoader.loadClass(mainClass);
        log("Loaded main class: " + mainClazz.getName());
        
        // Find main method
        Method mainMethod = mainClazz.getMethod("main", String[].class);
        
        // Build Minecraft arguments
        String[] mcArgs = buildMinecraftArguments(config);
        log("Minecraft args: " + Arrays.toString(mcArgs));
        
        // Invoke - this is where Minecraft actually starts
        log("=== Launching Minecraft ===");
        mainMethod.invoke(null, (Object) mcArgs);
    }
    
    private static String[] buildMinecraftArguments(LaunchConfig config) {
        List<String> args = new ArrayList<>();
        
        // Version
        args.add("--version");
        args.add(config.versionId);
        
        // Asset index
        args.add("--assetsDir");
        args.add(config.assetsDir);
        
        // Asset index name
        args.add("--assetIndex");
        args.add(config.assetIndex != null ? config.assetIndex : config.versionId);
        
        // Access token (from Microsoft auth)
        args.add("--accessToken");
        args.add(config.accessToken);
        
        // Username
        args.add("--username");
        args.add(config.username);
        
        // UUID
        args.add("--uuid");
        args.add(config.uuid);
        
        // Game directory
        args.add("--gameDir");
        args.add(config.gameDir);
        
        // Assets directory
        args.add("--assetsDir");
        args.add(config.assetsDir);
        
        // Renderer type (for 26.3+)
        if (config.renderer != null) {
            args.add("--renderer");
            args.add(config.renderer);
        }
        
        // Additional JVM arguments from version JSON
        if (config.extraArgs != null) {
            args.addAll(Arrays.asList(config.extraArgs));
        }
        
        return args.toArray(new String[0]);
    }
    
    private static void log(String message) {
        System.out.println("[" + TAG + "] " + message);
        logToNSLog("[" + TAG + "] " + message);
    }
    
    // Inner classes for config parsing
    
    static class LaunchConfig {
        String versionId = "";
        String gameDir = "";
        String assetsDir = "";
        String librariesDir = "";
        String nativesDir = "";
        String minecraftJar = "";
        String mainClass = "";
        String lwjglVersion = "3.4.3";
        String renderer = "MobileGlues";
        String accessToken = "";
        String username = "";
        String uuid = "";
        String assetIndex = "";
        String[] extraArgs = new String[0];
    }
    
    static class LoadConfig {
        static LaunchConfig fromJson(String json) throws Exception {
            // Simple JSON parser - in production use a proper library
            LaunchConfig config = new LaunchConfig();
            
            config.versionId = extractString(json, "versionId");
            config.gameDir = extractString(json, "gameDir");
            config.assetsDir = extractString(json, "assetsDir");
            config.librariesDir = extractString(json, "librariesDir");
            config.nativesDir = extractString(json, "nativesDir");
            config.minecraftJar = extractString(json, "minecraftJar");
            config.mainClass = extractString(json, "mainClass");
            config.accessToken = extractString(json, "accessToken");
            config.username = extractString(json, "username");
            config.uuid = extractString(json, "uuid");
            config.assetIndex = extractString(json, "assetIndex");
            config.renderer = extractString(json, "renderer");
            
            return config;
        }
        
        private static String extractString(String json, String key) {
            String search = "\"" + key + "\"";
            int keyPos = json.indexOf(search);
            if (keyPos == -1) return "";
            
            int colonPos = json.indexOf(':', keyPos);
            if (colonPos == -1) return "";
            
            int quoteStart = json.indexOf('"', colonPos + 1);
            if (quoteStart == -1) return "";
            
            int quoteEnd = json.indexOf('"', quoteStart + 1);
            if (quoteEnd == -1) return "";
            
            return json.substring(quoteStart + 1, quoteEnd);
        }
    }
}
