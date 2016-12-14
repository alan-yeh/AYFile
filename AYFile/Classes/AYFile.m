//
//  AYFile.m
//  AYFile
//
//  Created by Alan Yeh on 16/7/22.
//
//

#import "AYFile.h"

NSString * const AYFileErrorDomain = @"cn.yerl.error.AYFile";
NSString * const AYFileErrorKey = @"cn.yerl.error.AYFile.error.key";

@interface AYFile ()
@property (nonatomic, retain) NSFileManager *manager;
@end

@implementation AYFile{
    NSError *_lastError;
    NSString *_path;
}

+ (AYFile *)fileWithPath:(NSString *)path{
    return [[AYFile alloc] initWithPath:path];
}

+ (AYFile *)fileWithURL:(NSURL *)url{
    if (url == nil) {
        return nil;
    }
    NSParameterAssert([url.scheme isEqualToString:@"file"]);
    return [[AYFile alloc] initWithPath:url.path];
}

- (instancetype)initWithPath:(NSString *)path{
    if (path.length < 1) {
        return nil;
    }
    if (self = [super init]) {
        _path = [path copy];
        _manager = [NSFileManager new];
        [_manager changeCurrentDirectoryPath:path];
    }
    return self;
}

#pragma mark - 状态
- (NSString *)path{
    return _path;
}

- (NSURL *)url{
    return [NSURL fileURLWithPath:_path];
}

- (NSString *)name{
    return [self.path lastPathComponent];;
}

- (BOOL)isDirectory{
    BOOL isDirectory;
    [_manager fileExistsAtPath:_path isDirectory:&isDirectory];
    return isDirectory;
}

- (BOOL)isFile{
    return !self.isDirectory;
}

- (BOOL)isExists{
    return [_manager fileExistsAtPath:_path isDirectory:nil];
}

- (BOOL)delete{
    NSError *error = nil;
    BOOL result = [_manager removeItemAtPath:_path error:&error];
    _lastError = error;
    _log_error(_lastError, _cmd);
    return result;
}

- (BOOL)clear{
    NSError *error = nil;
    BOOL isDirector = self.isDirectory;
    BOOL result = [_manager removeItemAtPath:_path error:&error];
    _lastError = error;
    _log_error(error, _cmd);
    if (error == nil && isDirector) {
        [self makeDirs];
    }
    return result;
}

- (long long)size{
    if (self.isFile) {
        return [_manager attributesOfItemAtPath:_path error:nil].fileSize;
    }else{
        long long size =0;
        for (AYFile *child in self.childs) {
            size += child.size;
        }
        return size;
    }
}
#pragma mark - 进入/返回文件夹
- (AYFile *)root{
    return [AYFile home];
}

- (AYFile *)parent{
    NSString *parentPath = [_path stringByDeletingLastPathComponent];
    NSAssert(!(![parentPath isEqualToString:NSHomeDirectory()] && [NSHomeDirectory() rangeOfString:parentPath].location != NSNotFound), @"AYFile: path is out of sandbox.\npath: %@", parentPath);
    return [AYFile fileWithPath:parentPath];
}

- (AYFile *)child:(NSString *)name{
    return [AYFile fileWithPath:[_path stringByAppendingPathComponent:name]];
}

- (NSArray<AYFile *> *)childs{
    NSError *error = nil;
    NSArray<NSString *> *directories = [_manager contentsOfDirectoryAtPath:_path error:&error];
    if (error) {
        
        return nil;
    }
    
    NSMutableArray<AYFile *> *files = [NSMutableArray new];
    [directories enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [files addObject:[[AYFile alloc] initWithPath:[_path stringByAppendingPathComponent:obj]]];
    }];
    
    return files;
}

#pragma mark - 读取与写入
- (BOOL)makeDirs{
    if (self.isExists) {
        return YES;
    }else{
        NSError *error = nil;
        BOOL result = [_manager createDirectoryAtPath:_path
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:&error];
        _lastError = error;
        _log_error(_lastError, _cmd);
        
        return result;
    }
}

- (NSData *)data{
    return [NSData dataWithContentsOfFile:_path];
}

- (AYFile *)write:(NSData *)data withName:(NSString *)name{
    NSParameterAssert(name.length > 0);
    [self makeDirs];
    
    if (data.length < 1) {
        data = [NSData data];
    }
    
    NSString *targetFile = [_path stringByAppendingPathComponent:name];
    [data writeToFile:targetFile atomically:YES];
    return [[AYFile alloc] initWithPath:targetFile];
}

- (BOOL)copyToPath:(AYFile *)newFile{
    NSParameterAssert(newFile != nil && !self.isDirectory);
    if ([self isEqualToFile:newFile]) {
        return YES;
    }
    
    if (!self.isExists) {
        _lastError = [NSError errorWithDomain:AYFileErrorDomain code:-1001 userInfo:@{AYFileErrorKey: [NSString stringWithFormat:@"Source file in path <%@> is not exists.", self.path]}];
        _log_error(_lastError, _cmd);
        return NO;
    }
    
    [[newFile parent] makeDirs];
    
    NSError *error = nil;
    BOOL result = [_manager copyItemAtPath:self.path toPath:newFile.path error:&error];
    _lastError = error;
    _log_error(_lastError, _cmd);
    return result;
}

- (BOOL)moveToPath:(AYFile *)newFile{
    NSParameterAssert(newFile != nil && !self.isDirectory);
    
    if ([self isEqualToFile:newFile]) {
        return YES;
    }
    
    if (!self.isExists) {
        _lastError = [NSError errorWithDomain:AYFileErrorDomain code:-1001 userInfo:@{AYFileErrorKey: [NSString stringWithFormat:@"Source file in path <%@> is not exists.", self.path]}];
        _log_error(_lastError, _cmd);
        return NO;
    }
    [[newFile parent] makeDirs];
    
    NSError *error = nil;
    BOOL result = [_manager moveItemAtPath:self.path toPath:newFile.path error:&error];
    _lastError = error;
    _log_error(_lastError, _cmd);
    return result;
}

#pragma mark - orverride
- (NSString *)description{
    return [NSString stringWithFormat:@"\n<AYFile: %p>:\n{\n   type: %@,\n   path: %@\n}", self, self.isDirectory ? @"Directory" : @"File", _path];
}

- (NSString *)debugDescription{
    return [NSString stringWithFormat:@"\n<AYFile: %p>:\n{\n   type: %@,\n   path: %@\n}", self, self.isDirectory ? @"Directory" : @"File", _path];
}

- (BOOL)isEqualToFile:(AYFile *)otherFile{
    return [self.path isEqualToString:otherFile.path];
}

static void _log_error(NSError *error, SEL selector){
    if (error) {
        NSLog(@"\n⚠️⚠️WARNING: \n  An error occured when execute selector [- %@]:\n%@", NSStringFromSelector(selector) , error);
    }
}

@end

@implementation AYFile (Directory)
+ (AYFile *)home{
    return [AYFile fileWithPath:NSHomeDirectory()];
}

+ (AYFile *)caches{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    return [AYFile fileWithPath:cachesDir];
}

+ (AYFile *)documents{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    return [AYFile fileWithPath:docDir];
}

+ (AYFile *)tmp{
    return [AYFile fileWithPath:NSTemporaryDirectory()];
}
@end
