//
//  AYFile.m
//  AYFile
//
//  Created by Alan Yeh on 16/7/22.
//
//

#import "AYFile.h"
#include <CommonCrypto/CommonDigest.h>
#import <SSZipArchive/SSZipArchive.h>

NSString *const AYFileErrorPathKey = @"AYFileErrorPathKey";

@interface AYFile ()
@property (nonatomic, retain) NSFileManager *manager;
@end

@implementation AYFile{
    NSString *_path;
}

+ (AYFile *)fileWithPath:(NSString *)path{
    return [[AYFile alloc] initWithPath:path];
}

+ (AYFile *)fileWithURL:(NSURL *)url{
    if (url == nil) {
        return nil;
    }
    // 不支持非file://协议的URL
    if (![url.scheme isEqualToString:@"file"]) {
        return nil;
    }
    return [[AYFile alloc] initWithPath:url.path];
}

- (instancetype)initWithPath:(NSString *)path{
    if (path.length < 1) {
        return nil;
    }
    if (self = [super init]) {
        _path = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // 超出沙盒的路径不支持
        if (![_path isEqualToString:NSHomeDirectory()] && [NSHomeDirectory() rangeOfString:_path].location != NSNotFound) {
            @throw [NSException exceptionWithName:@"没有权限访问"
                                           reason:@"无法访问超出沙盒以外的文件或目录"
                                         userInfo:@{
                                                    AYFileErrorPathKey: path
                                                    }];
        }
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

- (NSString *)simpleName{
    return [[self.path lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)extension{
    return [[self.path lastPathComponent] pathExtension];
}

- (BOOL)isDirectory{
    BOOL isDirectory;
    BOOL isExists = [_manager fileExistsAtPath:_path isDirectory:&isDirectory];
    return isDirectory && isExists;
}

- (BOOL)isFile{
    BOOL isDirectory;
    BOOL isExists = [_manager fileExistsAtPath:_path isDirectory:&isDirectory];
    return !isDirectory && isExists;
}

- (BOOL)isExists{
    return [_manager fileExistsAtPath:_path isDirectory:nil];
}

- (BOOL)hasParent{
    NSString *parentPath = [_path stringByDeletingLastPathComponent];
    return !([parentPath isEqualToString:NSHomeDirectory()] && [NSHomeDirectory() rangeOfString:parentPath].location != NSNotFound);
}

- (NSString *)md5{
    if (!self.isExists) {
        return nil;
    }
    if (self.isDirectory) {
        return nil;
    }
    
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self.path];
    
    CC_MD5_CTX MD5_CTX;
    CC_MD5_Init(&MD5_CTX);
    
    BOOL done = NO;
    while (!done) {
        NSData *fileData = [handle readDataOfLength:1024];
        CC_MD5_Update(&MD5_CTX, fileData.bytes, (uint32_t)fileData.length);
        done = fileData.length < 1024;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &MD5_CTX);
    NSMutableString *result = [NSMutableString new];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i ++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return result.copy;
}

- (BOOL)isImmutable{
    return [self.attributes fileIsImmutable];
}

- (BOOL)isReadable{
    return [_manager isReadableFileAtPath:self.path];
}

- (BOOL)isWritable{
    return [_manager isWritableFileAtPath:self.path];
}

- (BOOL)isExecutable{
    return [_manager isExecutableFileAtPath:self.path];
}

- (BOOL)isDeletable{
    return [_manager isDeletableFileAtPath:self.path];
}

- (nullable NSDictionary<NSFileAttributeKey, id> *)attributes{
    NSError *error = nil;
    @try{
        return [_manager attributesOfItemAtPath:_path error:&error];
    }@finally{
        if (error) {
            @throw [NSException exceptionWithName:error.localizedDescription
                                           reason:error.localizedFailureReason
                                         userInfo:@{
                                                    @"InternalError": error
                                                    }];
        }
    }
}

- (void)setAttributes:(NSDictionary<NSFileAttributeKey,id> *)attributes{
    NSError *error = nil;
    @try{
        [_manager setAttributes:attributes ofItemAtPath:self.path error:nil];
    }@finally{
        if (error) {
            @throw [NSException exceptionWithName:error.localizedDescription
                                           reason:error.localizedFailureReason
                                         userInfo:@{
                                                    @"InternalError": error
                                                    }];
        }
    }
}

- (NSTimeInterval)modificationDate{
    return self.attributes.fileModificationDate.timeIntervalSince1970;
}

- (NSTimeInterval)creationDate{
    return self.attributes.fileCreationDate.timeIntervalSince1970;
}

- (BOOL)delete{
    if (self.isExists) {
        NSError *error = nil;
        @try{
            return [_manager removeItemAtPath:_path error:&error];
        }@finally{
            if (error) {
                @throw [NSException exceptionWithName:error.localizedDescription
                                               reason:error.localizedFailureReason
                                             userInfo:@{
                                                        @"InternalError": error
                                                        }];
            }
        }
    }
    return YES;
}

- (BOOL)clear{
    if (self.isExists) {
        NSError *error = nil;
        @try{
            BOOL isDirector = self.isDirectory;
            BOOL result = [_manager removeItemAtPath:_path error:&error];
            if (result && isDirector) {
                [self makeDirs];
            }
            return result;
        }@finally{
            if (error) {
                @throw [NSException exceptionWithName:error.localizedDescription
                                               reason:error.localizedFailureReason
                                             userInfo:@{
                                                        @"InternalError": error
                                                        }];
            }
        }
    }
    return YES;
}

- (long long)size{
    if (self.isFile) {
        return self.attributes.fileSize;
    }else{
        long long size =0;
        for (AYFile *child in self.children) {
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
    //判断是否超出沙盒
    if (![parentPath isEqualToString:NSHomeDirectory()] && [NSHomeDirectory() rangeOfString:parentPath].location != NSNotFound) {
        @throw [NSException exceptionWithName:@"没有权限访问"
                                       reason:@"无法访问超出沙盒以外的文件或目录"
                                     userInfo:@{
                                                AYFileErrorPathKey: parentPath
                                                }];
    }
    return [AYFile fileWithPath:parentPath];
}

- (AYFile *)child:(NSString *)name{
    return [AYFile fileWithPath:[_path stringByAppendingPathComponent:name]];
}

- (NSArray<AYFile *> *)children{
    NSError *error = nil;
    NSArray<NSString *> *directories = [_manager contentsOfDirectoryAtPath:_path error:&error];
    if (error) {
        @throw [NSException exceptionWithName:error.localizedDescription
                                       reason:error.localizedFailureReason
                                     userInfo:@{
                                                @"InternalError": error
                                                }];
    }
    
    NSMutableArray<AYFile *> *files = [NSMutableArray new];
    [directories enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [files addObject:[[AYFile alloc] initWithPath:[self.path stringByAppendingPathComponent:obj]]];
    }];
    
    return files;
}

- (BOOL)isChildOf:(AYFile *)parent{
    NSString *parentPath = [parent.path hasSuffix:@"/"] ? parent.path : [parent.path stringByAppendingString:@"/"];
    
    return ![parentPath isEqualToString:self.path] && [self.path hasPrefix:parentPath];
}

#pragma mark - 读取与写入
- (BOOL)makeDirs{
    if (self.isExists) {
        return YES;
    }else{
        NSError *error = nil;
        @try{
            return [_manager createDirectoryAtPath:_path
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&error];
        }@finally{
            if (error) {
                @throw [NSException exceptionWithName:error.localizedDescription
                                               reason:error.localizedFailureReason
                                             userInfo:@{
                                                        @"InternalError": error
                                                        }];
            }
        }
    }
}

- (NSData *)data{
    return [NSData dataWithContentsOfFile:_path];
}

- (NSString *)text{
    return [self textWithEncoding:NSUTF8StringEncoding];
}

- (NSString *)textWithEncoding:(NSStringEncoding)encoding{
    NSError *error;
    @try{
        return [NSString stringWithContentsOfFile:self.path encoding:encoding error:&error];
    }@finally{
        if (error) {
            @throw [NSException exceptionWithName:error.localizedDescription
                                           reason:error.localizedFailureReason
                                         userInfo:@{
                                                    @"InternalError": error
                                                    }];
        }
    }
}

- (void)writeData:(NSData *)data{
    if (self.isExists) {
        [self delete];
    }
    [data writeToFile:self.path atomically:YES];
}

- (void)writeText:(NSString *)text{
    [self writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeText:(NSString *)text withEncoding:(NSStringEncoding)encoding{
    [self writeData:[text dataUsingEncoding:encoding]];
}

- (void)appendData:(NSData *)data{
    if (!self.isExists) {
        [self writeData:data];
    }else{
        NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:self.path];
        [handle seekToEndOfFile];
        [handle writeData:data];
        [handle closeFile];
    }
}

- (void)appendText:(NSString *)text{
    [self appendData:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendText:(NSString *)text withEncoding:(NSStringEncoding)encoding{
    [self appendData:[text dataUsingEncoding:encoding]];
}

- (AYFile *)write:(NSData *)data withName:(NSString *)name{
    NSParameterAssert(name.length > 0);
    [self makeDirs];
    
    data = data ?: [NSData data];
    
    AYFile *target = [self child:name];
    [data writeToFile:target.path atomically:YES];
    return target;
}

- (AYFile *)write:(NSData *)data withName:(NSString *)simpleName andExtension:(NSString *)ext{
    return [self write:data withName:[simpleName stringByAppendingPathExtension:ext]];
}

- (BOOL)copyToPath:(AYFile *)newFile{
    NSParameterAssert(newFile != nil);
    
    if ([self isEqualToFile:newFile]) {
        return YES;
    }
    
    if (!self.isExists) {
        @throw [NSException exceptionWithName:@"源文件不存在"
                                       reason:@"源文件不存在"
                                     userInfo:@{
                                                AYFileErrorPathKey: self.path
                                                }];
    }
    if ([newFile.parent isEqualToFile:[AYFile home]]) {
        
        @throw [NSException exceptionWithName:@"没有权限访问"
                                       reason:@"没有权限写入数据"
                                     userInfo:@{
                                                AYFileErrorPathKey: newFile.path
                                                }];
    }
    
    [[newFile parent] makeDirs];
    
    if (self.isDirectory) {
        NSArray<AYFile *> *children = self.children;
        BOOL result = YES;
        if (children.count < 1) {
            // 如果没有子文件（夹），就直接在目标上创建文件夹就好
            result = [newFile makeDirs];
        }else{
            for (AYFile *file in children) {
                if (!result) {
                    return result;
                }
                result  = [file copyToPath:[newFile child: file.name]];
            }
        }
        return result;
    }else{
        // 移动文件
        NSError *error = nil;
        @try{
            return [_manager copyItemAtPath:self.path toPath:newFile.path error:&error];
        }@finally{
            if (error) {
                @throw [NSException exceptionWithName:error.localizedDescription
                                               reason:error.localizedFailureReason
                                             userInfo:@{
                                                        @"InternalError": error
                                                        }];
            }
        }
    }
}

- (BOOL)moveToPath:(AYFile *)newFile{
    BOOL result = [self copyToPath:newFile];
    if (result) {
        [self delete];
    }
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

- (BOOL)isContentEqualToFile:(AYFile *)anotherFile{
    return [_manager contentsEqualAtPath:self.path andPath:anotherFile.path];
}

@end

@implementation AYFile (Zip)

+ (AYFile *)zipFiles:(NSArray<AYFile *> *)files to:(AYFile *)path{
    return [self zipFiles:files to:path withPassword:nil];
}

+ (AYFile *)zipFiles:(NSArray<AYFile *> *)files to:(AYFile *)path withPassword:(NSString *)password{
    if ([path isExists]) {
        @throw [NSException exceptionWithName:@"文件已存在"
                                       reason:@"目标路径已存在文件，无法在此路径生成压缩文件"
                                     userInfo:@{
                                                AYFileErrorPathKey: path.path
                                                }];
    }
    // 压缩多个文件的时候，先创建一个容器，再将所有文件复制到容器下，最后进行压缩
    AYFile *zipContainer = nil;
    if ([path isChildOf:[AYFile tmp]]) {
        zipContainer = [[[AYFile caches] child:[NSUUID UUID].UUIDString] child:path.simpleName];
    }else{
        zipContainer = [[[AYFile tmp] child:[NSUUID UUID].UUIDString] child:path.simpleName];
    }
    
    [zipContainer makeDirs];
    
    for (AYFile *file in files) {
        [file copyToPath:[zipContainer child:file.name]];
    }
    
    AYFile *file = [zipContainer zipToPath:path];
    // 压缩完了之后，将临时文件删除
    [zipContainer.parent delete];
    return file;
}


- (AYFile *)zip{
    return [self zipToPath:[[self parent] child:[self.simpleName stringByAppendingPathExtension:@"zip"]] withPassword:nil];
}

- (AYFile *)zipWithPassword:(NSString *)password{
    return [self zipToPath:[[self parent] child:[self.simpleName stringByAppendingPathExtension:@"zip"]] withPassword:password];
}

- (AYFile *)zipToPath:(AYFile *)file{
    return [self zipToPath:file withPassword:nil];
}

- (AYFile *)zipToPath:(AYFile *)file withPassword:(NSString *)password{
    [file.parent makeDirs];
    
    if (self.isDirectory) {
        BOOL res = [SSZipArchive createZipFileAtPath:file.path withContentsOfDirectory:self.path keepParentDirectory:YES withPassword:password];
        return res ? file : nil;
    }else {
        BOOL res = [SSZipArchive createZipFileAtPath:file.path withFilesAtPaths:@[self.path] withPassword:password];
        return res ? file : nil;
    }
}

- (AYFile *)unZip{
    return [self unZipToPath:[[self parent] child:self.simpleName] withPassword:nil];
}

- (AYFile *)unZipWithPassword:(NSString *)password{
    return [self unZipToPath:[[self parent] child:self.simpleName] withPassword:password];
}

- (AYFile *)unZipToPath:(AYFile *)file{
    return [self unZipToPath:file withPassword:nil];
}

- (AYFile *)unZipToPath:(AYFile *)file withPassword:(NSString *)password{
    NSParameterAssert([file isKindOfClass:[AYFile class]]);
    
    if (file.isExists && file.isFile) {
        @throw [NSException exceptionWithName:@"文件已存在"
                                       reason:@"目标路径已存在文件，无法在此路径解压文件"
                                     userInfo:@{
                                                AYFileErrorPathKey: file.path
                                                }];
    }
    
    if (!self.isExists) {
        @throw [NSException exceptionWithName:@"文件不存在"
                                       reason:@"源路径不存在，无法解压该文件"
                                     userInfo:@{
                                                AYFileErrorPathKey: self.path
                                                }];
    }
    
    if (!self.isFile || ![self.extension isEqualToString:@"zip"]) {
        
        @throw [NSException exceptionWithName:@"解压异常"
                                       reason:@"源文件不是有效的压缩文件"
                                     userInfo:@{
                                                AYFileErrorPathKey: file.path
                                                }];
    }
    
    [file makeDirs];
    
    NSError *error;
    @try{
        BOOL res = [SSZipArchive unzipFileAtPath:self.path toDestination:file.path overwrite:YES password:password error:&error];
        return res ? file : nil;
    }@finally{
        if (error) {
            @throw [NSException exceptionWithName:error.localizedDescription
                                           reason:error.localizedFailureReason
                                         userInfo:@{
                                                    @"InternalError": error
                                                    }];
        }
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


