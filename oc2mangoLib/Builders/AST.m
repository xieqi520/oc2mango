//
//  AST.m
//  oc2mangoLib
//
//  Created by Jiang on 2019/5/18.
//  Copyright © 2019年 SilverFruity. All rights reserved.
//

#import "AST.h"
#import "MakeDeclare.h"
AST *GlobalAst = nil;
void classProrityDetect(AST *ast,ORClass *class, int *level){
    if ([class.superClassName isEqualToString:@"NSObject"] || NSClassFromString(class.superClassName) != nil) {
        return;
    }
    ORClass *superClass = ast.classCache[class.superClassName];
    if (superClass) {
        (*level)++;
    }else{
        return;
    }
    classProrityDetect(ast, superClass, level);
}
int startClassProrityDetect(AST *ast, ORClass *class){
    int prority = 0;
    classProrityDetect(ast, class, &prority);
    return prority;
}
@implementation AST
- (ORClass *)classForName:(NSString *)className{
    ORClass *class = self.classCache[className];
    if (!class) {
        class = makeOCClass(className);
        self.classCache[className] = class;
    }
    return class;
}
- (nonnull ORProtocol *)protcolForName:(NSString *)protcolName{
    ORProtocol *protocol = self.protcolCache[protcolName];
    if (!protocol) {
        protocol = makeORProtcol(protcolName);
        self.protcolCache[protcolName] = protocol;
    }
    return protocol;
}
- (instancetype)init
{
    self = [super init];
    self.classCache = [NSMutableDictionary dictionary];
    self.protcolCache = [NSMutableDictionary dictionary];
    self.globalStatements = [NSMutableArray array];
    return self;
}
- (void)addGlobalStatements:(id)objects{
    if ([objects isKindOfClass:[NSArray class]]) {
        [self.globalStatements addObjectsFromArray:objects];
    }else{
        [self.globalStatements addObject:objects];
    }
}
- (NSArray *)sortClasses{
    //TODO: 根据Class继承关系，进行排序
    NSMutableDictionary <NSString *, NSNumber *>*classProrityDict = [@{} mutableCopy];
    for (ORClass *clazz in self.classCache.allValues) {
        classProrityDict[clazz.className] = @(startClassProrityDetect(self,clazz));
    }
    NSArray *classes = self.classCache.allValues;
    classes = [classes sortedArrayUsingComparator:^NSComparisonResult(ORClass *obj1, ORClass *obj2) {
        return classProrityDict[obj1.className].intValue > classProrityDict[obj2.className].intValue;
    }];
    return classes;
}
- (void)merge:(AST *)ast{
    [ast.classCache enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, ORClass *obj, BOOL * _Nonnull stop) {
        ORClass *current = self.classCache[key];
        if (current) {
            [current.privateVariables addObjectsFromArray:obj.privateVariables];
            [current.properties addObjectsFromArray:obj.properties];
            [current.protocols addObjectsFromArray:obj.protocols];
            if (!current.superClassName && obj.superClassName) {
                current.superClassName = obj.superClassName;
            }
            for (ORMethodImplementation *imp in obj.methods) {
                if (imp.scopeImp) {
                    [current.methods addObject:imp];
                }
            }
        }else{
            self.classCache[key] = obj;
        }
    }];
    [self.globalStatements addObjectsFromArray:ast.globalStatements];
    [self.protcolCache addEntriesFromDictionary:ast.protcolCache];
}
@end

