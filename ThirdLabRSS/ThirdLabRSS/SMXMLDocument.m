#import "SMXMLDocument.h"

NSString *const SMXMLDocumentErrorDomain = @"SMXMLDocumentErrorDomain";

static NSError *SMXMLDocumentError(NSXMLParser *parser, NSError *parseError) {
    
    NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Malformed XML document. Error at line %@:%@.", @""),
                             @(parser.lineNumber), @(parser.columnNumber)];
    
    NSDictionary *userInfo = @{
                               NSUnderlyingErrorKey: parseError,
                               NSLocalizedDescriptionKey: description,
                               @"LineNumber": @(parser.lineNumber),
                               @"ColumnNumber": @(parser.columnNumber)
                               };
    
    return [NSError errorWithDomain:SMXMLDocumentErrorDomain code:1 userInfo:userInfo];
}

@implementation SMXMLElement

- (id)initWithDocument:(SMXMLDocument *)document {
    if (self = [super init])
        self.document = document;
    return self;
}

- (NSString *)descriptionWithIndent:(NSString *)indent truncatedValues:(BOOL)truncated encoded:(BOOL)encode {
    
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"%@<%@", indent, self.name];
    
    for (NSString *attribute in self.attributes) {
        NSString *attributeValue = self.attributes[attribute];
        [s appendFormat:@" %@=\"%@\"", attribute, encode ? [self encodeString:attributeValue] : attributeValue];
    }
    
    NSString *valueOrTrimmed = [self.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (truncated && valueOrTrimmed.length > 25)
        valueOrTrimmed = [NSString stringWithFormat:@"%@…", [valueOrTrimmed substringToIndex:25]];
    
    if (encode)
        valueOrTrimmed = [self encodeString:valueOrTrimmed];
    
    if (self.children.count) {
        [s appendString:@">\n"];
        
        NSString *childIndent = [indent stringByAppendingString:@"  "];
        
        if (valueOrTrimmed.length)
            [s appendFormat:@"%@%@\n", childIndent, valueOrTrimmed];
        
        for (SMXMLElement *child in self.children)
            [s appendFormat:@"%@\n", [child descriptionWithIndent:childIndent truncatedValues:truncated encoded:encode]];
        
        [s appendFormat:@"%@</%@>", indent, self.name];
    }
    else if (valueOrTrimmed.length) {
        [s appendFormat:@">%@</%@>", valueOrTrimmed, self.name];
    }
    else [s appendString:@"/>"];
    
    return s;
}

- (NSString *)encodeString:(NSString *)string
{
    if (!string.length)
        return string;
    
    NSMutableString *encoded = [NSMutableString stringWithString:string];
    
    [encoded replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
    [encoded replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
    [encoded replaceOccurrencesOfString:@"'"  withString:@"&#x27;" options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
    [encoded replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
    [encoded replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
    
    return encoded;
}

- (NSString *)description {
    return [self descriptionWithIndent:@"" truncatedValues:YES encoded:NO];
}

- (NSString *)fullDescription {
    return [self descriptionWithIndent:@"" truncatedValues:NO encoded:NO];
}

- (NSString *)encodedDescription {
    return [self descriptionWithIndent:@"" truncatedValues:NO encoded:YES];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (!string) return;
    
    if (self.value)
        [(NSMutableString *)self.value appendString:string];
    else
        self.value = [NSMutableString stringWithString:string];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    SMXMLElement *child = [[SMXMLElement alloc] initWithDocument:self.document];
    child.parent = self;
    child.name = elementName;
    child.attributes = attributeDict;
    
    if (self.children)
        [(NSMutableArray *)self.children addObject:child];
    else
        self.children = [NSMutableArray arrayWithObject:child];
    
    [parser setDelegate:child];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [parser setDelegate:self.parent];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    self.document.error = SMXMLDocumentError(parser, parseError);
}

- (SMXMLElement *)childNamed:(NSString *)nodeName {
    for (SMXMLElement *child in self.children)
        if ([child.name isEqual:nodeName])
            return child;
    return nil;
}

- (NSArray *)childrenNamed:(NSString *)nodeName {
    NSMutableArray *array = [NSMutableArray array];
    for (SMXMLElement *child in self.children)
        if ([child.name isEqual:nodeName])
            [array addObject:child];
    return array.count ? [array copy] : nil;
}

- (SMXMLElement *)childWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue {
    for (SMXMLElement *child in self.children)
        if ([[child attributeNamed:attributeName] isEqual:attributeValue])
            return child;
    return nil;
}

- (NSString *)attributeNamed:(NSString *)attributeName {
    return self.attributes[attributeName];
}

- (SMXMLElement *)descendantWithPath:(NSString *)path {
    SMXMLElement *descendant = self;
    for (NSString *childName in [path componentsSeparatedByString:@"."])
        descendant = [descendant childNamed:childName];
    return descendant;
}

- (NSString *)valueWithPath:(NSString *)path {
    NSArray *components = [path componentsSeparatedByString:@"@"];
    SMXMLElement *descendant = [self descendantWithPath:components[0]];
    return [components count] > 1 ? [descendant attributeNamed:components[1]] : descendant.value;
}


- (SMXMLElement *)firstChild { return [self.children count] > 0 ? self.children[0] : nil; }
- (SMXMLElement *)lastChild { return [self.children lastObject]; }

@end

@interface SMXMLDocument ()
@property (nonatomic, assign) BOOL parsedRoot;
@end

@implementation SMXMLDocument

- (id)initWithData:(NSData *)data error:(NSError **)outError {
    if (self = [super initWithDocument:self]) {
        
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        parser.delegate = self;
        parser.shouldProcessNamespaces = YES;
        parser.shouldReportNamespacePrefixes = YES;
        parser.shouldResolveExternalEntities = NO;
        [parser parse];
        
        if (self.error) {
            if (outError)
                *outError = self.error;
            return nil;
        }
        else if (outError)
            *outError = nil;
    }
    return self;
}

+ (SMXMLDocument *)documentWithData:(NSData *)data error:(NSError **)outError {
    return [[SMXMLDocument alloc] initWithData:data error:outError];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if (!self.parsedRoot) {
        self.name = elementName;
        self.attributes = attributeDict;
        self.parsedRoot = YES;
    }
    else {
        [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    }
}

@end