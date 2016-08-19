//
//  AYFile.h
//  AYFile
//
//  Created by Alan Yeh on 16/7/22.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface AYFile : NSObject
+ (AYFile *)fileWithPath:(NSString *)path;
+ (AYFile *)fileWithURL:(NSURL *)url;
- (instancetype)initWithPath:(NSString *)path;

#pragma mark - 状态
@property (nonatomic, readonly) NSString *path;/**< 获取当前文件(夹)的路径. */
@property (nonatomic, readonly) NSURL *url;/**< 获取当前文件(夹)的路径 */
@property (nonatomic, readonly) NSString *name;/**< 获取文件(夹)名 */
@property (nonatomic, readonly) BOOL isDirectory;/**< 判断当前File是否是目录.*/
@property (nonatomic, readonly) BOOL isFile;/**< 判断是否是文件. */
@property (nonatomic, readonly) BOOL isExists;/**< 判断是否存在. */
@property (nonatomic, readonly) long long size;/**< 计算大小. 注意: 如果是文件夹, 会递归查询大小, 是耗时操作 */



#pragma mark - 进入/返回文件夹
- (AYFile *)root;/**< 返回根文件夹 */
- (nullable AYFile *)parent;/**< 获取父目录 */
- (AYFile *)child:(NSString *)name;/**< 获取子文件(夹) */
- (nullable NSArray<AYFile *> *)childs;/**< 获取当前目录下所有文件(夹). 注意: 耗时操作 */

#pragma mark - 读取与写入
- (BOOL)delete;/**< 删除文件(夹) */
- (BOOL)clear;/**< 如果是文件夹, 则清空(不删除目录), 是文件, 则删除 */

- (BOOL)makeDirs;/**< 创建文件夹(如果不存在的话) */

- (nullable NSData *)data;/**< 读取文件*/
- (AYFile *)write:(NSData *)data withName:(NSString *)name;/**< 在当前文件夹下写文件. 如果已有文件, 则复盖 */
- (BOOL)copyFile:(AYFile *)oldFile toPath:(AYFile *)newFile;/**< 复制文件 */
- (BOOL)moveFile:(AYFile *)oldFile toPath:(AYFile *)newFile;/**< 移动文件 */

#pragma mark - 其它
@property (nonatomic, readonly) NSError *lastError;/**< 最后一次发生的错误 */

- (BOOL)isEqualToFile:(AYFile *)otherFile;
@end

@interface AYFile (Directory)
+ (AYFile *)home;/**< 获取Home目录, 根目录 */
+ (AYFile *)caches;/**< 获取Library/Caches目录, iTunes不会备份此目录, 应用退出时, 此目录不清空 */
+ (AYFile *)documents;/**< 获取Documents目录, iTunes将会备份此目录 */
+ (AYFile *)tmp;/**< 获取tmp目录, 应用退出时清空 */
@end
NS_ASSUME_NONNULL_END