//
//  JNIBridge.m
//  MC iOS Launcher
//
//  JNI bridge between Swift app and Java launcher
//  Implements the native methods called from JavaLauncher.java
//

#import <Foundation/Foundation.h>
#import <JavaNativeFoundation/JavaNativeFoundation.h>
#import <dlfcn.h>

// JNI function declarations from JavaLauncher
JNIEXPORT jstring JNICALL Java_com_mcioslauncher_JavaLauncher_getBundlePath(JNIEnv *env, jclass clazz);
JNIEXPORT jstring JNICALL Java_com_mcioslauncher_JavaLauncher_getDocumentsPath(JNIEnv *env, jclass clazz);
JNIEXPORT void JNICALL Java_com_mcioslauncher_JavaLauncher_logToNSLog(JNIEnv *env, jclass clazz, jstring message);

// Bundle path cache
static NSString *_bundlePath = nil;
static NSString *_documentsPath = nil;

@implementation JNIBridge

+ (void)initialize {
    if (self == [JNIBridge class]) {
        _bundlePath = [[NSBundle mainBundle] bundlePath];
        _documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    }
}

@end

// JNI Implementation

JNIEXPORT jstring JNICALL Java_com_mcioslauncher_JavaLauncher_getBundlePath(JNIEnv *env, jclass clazz) {
    const char *path = [_bundlePath UTF8String];
    return (*env)->NewStringUTF(env, path);
}

JNIEXPORT jstring JNICALL Java_com_mcioslauncher_JavaLauncher_getDocumentsPath(JNIEnv *env, jclass clazz) {
    const char *path = [_documentsPath UTF8String];
    return (*env)->NewStringUTF(env, path);
}

JNIEXPORT void JNICALL Java_com_mcioslauncher_JavaLauncher_logToNSLog(JNIEnv *env, jclass clazz, jstring message) {
    const char *msg = (*env)->GetStringUTFChars(env, message, 0);
    NSLog(@"[MCLauncher] %s", msg);
    (*env)->ReleaseStringUTFChars(env, message, msg);
}

// JVM Initialization

static JavaVM *_jvm = NULL;

BOOL initializeJVM(NSString *javaHome, NSArray *extraOptions) {
    // Find libjli.dylib (Java Launcher Interface)
    NSString *libjliPath = [javaHome stringByAppendingPathComponent:@"lib/libjli.dylib"];
    void *libjli = dlopen([libjliPath UTF8String], RTLD_NOW | RTLD_LOCAL);
    
    if (!libjli) {
        NSLog(@"[JNIBridge] Failed to load libjli: %s", dlerror());
        return NO;
    }
    
    // Get JLI_Launch function pointer
    typedef int (*JLI_LaunchFn)(int, char **, int, int, int, jboolean, 
                                 const char *, const char *, const char *, 
                                 const char *, jboolean, jlong, jlong, 
                                 char **, int, void **);
    JLI_LaunchFn JLI_Launch = (JLI_LaunchFn)dlsym(libjli, "JLI_Launch");
    
    if (!JLI_Launch) {
        NSLog(@"[JNIBridge] Failed to find JLI_Launch: %s", dlerror());
        return NO;
    }
    
    // Build JVM options
    NSMutableArray *options = [NSMutableArray array];
    
    // Required: JNI version
    [options addObject:@"-Djava.compiler=NONE"]; // No JIT compiler on iOS initially
    [options addObject:@"-Xmx2048m"]; // Default heap size
    
    // Add extra options from caller
    if (extraOptions) {
        [options addObjectsFromArray:extraOptions];
    }
    
    // Set JNI invocation args
    JavaVMInitArgs vm_args;
    JavaVMOption *vm_options = malloc(sizeof(JavaVMOption) * [options count]);
    
    for (NSUInteger i = 0; i < [options count]; i++) {
        vm_options[i].optionString = (char *)[options[i] UTF8String];
        vm_options[i].extraInfo = NULL;
    }
    
    vm_args.version = JNI_VERSION_1_8;
    vm_args.nOptions = (jint)[options count];
    vm_args.options = vm_options;
    vm_args.ignoreUnrecognized = JNI_FALSE;
    
    // Create the JVM
    JNIEnv *env = NULL;
    jint result = JNI_CreateJavaVM(&_jvm, (void **)&env, &vm_args);
    free(vm_options);
    
    if (result != JNI_OK) {
        NSLog(@"[JNIBridge] Failed to create JVM: %d", result);
        return NO;
    }
    
    NSLog(@"[JNIBridge] JVM initialized successfully");
    return YES;
}

int launchJavaApplication(NSString *mainClass, NSArray *args, NSString *classpath) {
    if (!_jvm) {
        NSLog(@"[JNIBridge] JVM not initialized");
        return -1;
    }
    
    JNIEnv *env = NULL;
    [_jvm GetEnv:(void **)&env, JNI_VERSION_1_8];
    
    // Build arguments array
    jobjectArray argArray = (*env)->NewObjectArray(env, (jsize)[args count], 
                                                    (*env)->FindClass(env, "java/lang/String"), NULL);
    
    for (NSUInteger i = 0; i < [args count]; i++) {
        jstring arg = (*env)->NewStringUTF(env, [[args objectAtIndex:i] UTF8String]);
        (*env)->SetObjectArrayElement(env, argArray, (jsize)i, arg);
    }
    
    // Find main class
    jclass mainClazz = (*env)->FindClass(env, [mainClass cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!mainClazz) {
        NSLog(@"[JNIBridge] Failed to find main class: %s", [mainClass UTF8String]);
        return -1;
    }
    
    // Get main method
    jmethodID mainMethod = (*env)->GetStaticMethodID(env, mainClazz, "main", "([Ljava/lang/String;)V");
    if (!mainMethod) {
        NSLog(@"[JNIBridge] Failed to find main method");
        return -1;
    }
    
    // Invoke main
    (*env)->CallStaticVoidMethod(env, mainClazz, mainMethod, argArray);
    
    // Check for exceptions
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
        return -1;
    }
    
    return 0;
}
