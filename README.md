# AYFile

[![CI Status](http://img.shields.io/travis/alan-yeh/AYFile.svg?style=flat)](https://travis-ci.org/alan-yeh/AYFile)
[![Version](https://img.shields.io/cocoapods/v/AYFile.svg?style=flat)](http://cocoapods.org/pods/AYFile)
[![License](https://img.shields.io/cocoapods/l/AYFile.svg?style=flat)](http://cocoapods.org/pods/AYFile)
[![Platform](https://img.shields.io/cocoapods/p/AYFile.svg?style=flat)](http://cocoapods.org/pods/AYFile)

## 引用
　　使用[CocoaPods](http://cocoapods.org)可以很方便地引入AYFile。Podfile添加AYFile的依赖。

```ruby
pod "AYFile"
```

## 简介
　　你是否厌倦了写一长串代码来获取Documents目录？你是否厌倦了NSFileManager那一大串复杂又难记又难打的api？很好，你现在可以用AYFile了。因为它足够简单，但功能却不简单。

　　AYFile简单地封装了AYFileManager的一些功能，用于支持快速管理文件和目录。
### 用法
　　AYFile的头文件中，已经为每个方法做上了注释，看了注释之后便可以了解它的用法了。

使用用例：

```objective-c
   //获取Documents目录
   [AYFile documents];
   
   //在Documents目录下创建Users/Caches/Files目录
   [[[[[AYFile documents] child:@"Users"] child:@"Caches"] child:@"Files"] createIfNotExists];
   
   //获取Documents/Users/Database/workflows.db文件路径
   //仅仅只是获取路径，尽管Database目录还没有创建
   NSString *filePath = [[[[[AYFile documents] child:@"Users"] child:@"Database"] child:@"workflows.db"].path;
   
   //清空Library/Caches目录
   [[AYFile caches] clear];
   
   //删除Document/Users目录（子目录和文件都会被删掉）
   [[[AYFile documents] child:@"Users"] delete];
   
   //获取目录下所有文件和文件夹
   NSArray<AYFile *> *files = [[AYFile documents] childs];
   
   //获取文件或文件夹(递归计算)大小
   long long folderSize = [[[AYFile documents] child:@"Users"] child:@"Caches"].size;
   
   //判断是文件夹还是文件
   //NO
   BOOL isDocument = [[[[[[AYFile documents] child:@"Users"] child:@"Database"] child:@"workflows.db"] isDocument];
   //YES
   BOOL isDocument = [AYFile documents].isDocument;
```

## License

AYFile is available under the MIT license. See the LICENSE file for more info.
