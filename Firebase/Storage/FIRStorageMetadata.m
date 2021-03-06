// Copyright 2017 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FIRStorageMetadata.h"

#import "FIRStorageConstants.h"
#import "FIRStorageConstants_Private.h"
#import "FIRStorageMetadata_Private.h"
#import "FIRStorageUtils.h"

// TODO: consider rewriting this using GTLR (GTLRStorageObjects.h)
@implementation FIRStorageMetadata

#pragma mark - Initializers

- (instancetype)init {
  return [self initWithDictionary:[NSDictionary dictionary]];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (self) {
    _bucket = dictionary[kFIRStorageMetadataBucket];
    _cacheControl = dictionary[kFIRStorageMetadataCacheControl];
    _contentDisposition = dictionary[kFIRStorageMetadataContentDisposition];
    _contentEncoding = dictionary[kFIRStorageMetadataContentEncoding];
    _contentLanguage = dictionary[kFIRStorageMetadataContentLanguage];
    _contentType = dictionary[kFIRStorageMetadataContentType];
    _customMetadata = dictionary[kFIRStorageMetadataCustomMetadata];
    _size = [dictionary[kFIRStorageMetadataSize] longLongValue];
    _downloadURLs = dictionary[kFIRStorageMetadataDownloadURLs];
    _generation = [dictionary[kFIRStorageMetadataGeneration] longLongValue];
    _metageneration = [dictionary[kFIRStorageMetadataMetageneration] longLongValue];
    _timeCreated = [self dateFromRFC3339String:dictionary[kFIRStorageMetadataTimeCreated]];
    _updated = [self dateFromRFC3339String:dictionary[kFIRStorageMetadataUpdated]];
    // GCS "name" is our path, our "name" is just the last path component of the path
    _path = dictionary[kFIRStorageMetadataName];
    _name = [_path lastPathComponent];
    NSString *downloadTokens = dictionary[kFIRStorageMetadataDownloadTokens];
    if (downloadTokens) {
      NSArray<NSString *> *downloadStringArray = [downloadTokens componentsSeparatedByString:@","];
      NSMutableArray<NSURL *> *downloadURLArray =
          [[NSMutableArray alloc] initWithCapacity:[downloadStringArray count]];
      [downloadStringArray enumerateObjectsUsingBlock:^(NSString *_Nonnull token, NSUInteger idx,
                                                        BOOL *_Nonnull stop) {
        NSURLComponents *components = [[NSURLComponents alloc] init];
        components.scheme = kFIRStorageScheme;
        components.host = kFIRStorageHost;
        NSString *path = [FIRStorageUtils GCSEscapedString:_path];
        NSString *fullPath = [NSString stringWithFormat:kFIRStorageFullPathFormat, _bucket, path];
        components.percentEncodedPath = fullPath;
        components.query = [NSString stringWithFormat:@"alt=media&token=%@", token];

        [downloadURLArray insertObject:[components URL] atIndex:idx];
      }];
      _downloadURLs = downloadURLArray;
    }
  }
  return self;
}

#pragma mark - NSObject overrides

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithDictionary:[self dictionaryRepresentation]];
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[FIRStorageMetadata class]]) {
    return NO;
  }

  BOOL isEqualObject = [self isEqualToFIRStorageMetadata:(FIRStorageMetadata *)object];
  return isEqualObject;
}

- (BOOL)isEqualToFIRStorageMetadata:(FIRStorageMetadata *)metadata {
  return [[self dictionaryRepresentation] isEqualToDictionary:[metadata dictionaryRepresentation]];
}

- (NSUInteger)hash {
  NSUInteger hash = [[self dictionaryRepresentation] hash];
  return hash;
}

- (NSString *)description {
  NSDictionary *metadataDictionary = [self dictionaryRepresentation];
  return [NSString stringWithFormat:@"%@ %p: %@", [self class], self, metadataDictionary];
}

#pragma mark - Public methods

- (NSDictionary *)dictionaryRepresentation {
  NSMutableDictionary *metadataDictionary = [[NSMutableDictionary alloc] initWithCapacity:13];

  if (_bucket) {
    metadataDictionary[kFIRStorageMetadataBucket] = _bucket;
  }

  if (_cacheControl) {
    metadataDictionary[kFIRStorageMetadataCacheControl] = _cacheControl;
  }

  if (_contentDisposition) {
    metadataDictionary[kFIRStorageMetadataContentDisposition] = _contentDisposition;
  }

  if (_contentEncoding) {
    metadataDictionary[kFIRStorageMetadataContentEncoding] = _contentEncoding;
  }

  if (_contentLanguage) {
    metadataDictionary[kFIRStorageMetadataContentLanguage] = _contentLanguage;
  }

  if (_contentType) {
    metadataDictionary[kFIRStorageMetadataContentType] = _contentType;
  }

  if (_customMetadata) {
    metadataDictionary[kFIRStorageMetadataCustomMetadata] = _customMetadata;
  }

  if (_downloadURLs) {
    NSMutableArray *downloadTokens = [[NSMutableArray alloc] init];
    [_downloadURLs
        enumerateObjectsUsingBlock:^(NSURL *_Nonnull URL, NSUInteger idx, BOOL *_Nonnull stop) {
          NSArray *queryItems = [URL.query componentsSeparatedByString:@"&"];
          [queryItems enumerateObjectsUsingBlock:^(NSString *queryString, NSUInteger idx,
                                                   BOOL *_Nonnull stop) {
            NSString *key;
            NSString *value;
            NSScanner *scanner = [NSScanner scannerWithString:queryString];
            [scanner scanUpToString:@"=" intoString:&key];
            [scanner scanString:@"=" intoString:NULL];
            [scanner scanUpToString:@"\n" intoString:&value];
            if ([key isEqual:@"token"]) {
              [downloadTokens addObject:value];
              *stop = YES;
            }
          }];
        }];
    NSString *downloadTokenString = [downloadTokens componentsJoinedByString:@","];
    metadataDictionary[kFIRStorageMetadataDownloadTokens] = downloadTokenString;
  }

  if (_generation) {
    NSString *generationString = [NSString stringWithFormat:@"%lld", _generation];
    metadataDictionary[kFIRStorageMetadataGeneration] = generationString;
  }

  if (_metageneration) {
    NSString *metagenerationString = [NSString stringWithFormat:@"%lld", _metageneration];
    metadataDictionary[kFIRStorageMetadataMetageneration] = metagenerationString;
  }

  if (_timeCreated) {
    metadataDictionary[kFIRStorageMetadataTimeCreated] = [self RFC3339StringFromDate:_timeCreated];
  }

  if (_updated) {
    metadataDictionary[kFIRStorageMetadataUpdated] = [self RFC3339StringFromDate:_updated];
  }

  if (_path) {
    metadataDictionary[kFIRStorageMetadataName] = _path;
  }

  return [metadataDictionary copy];
}

- (BOOL)isFile {
  return _type == FIRStorageMetadataTypeFile;
}

- (BOOL)isFolder {
  return _type == FIRStorageMetadataTypeFolder;
}

- (nullable NSURL *)downloadURL {
  return [_downloadURLs firstObject];
}

#pragma mark - RFC 3339 conversions

static NSDateFormatter *sRFC3339DateFormatter;

static void setupDateFormatterOnce(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sRFC3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

    [sRFC3339DateFormatter setLocale:enUSPOSIXLocale];
    [sRFC3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZZZ"];
    [sRFC3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  });
}

- (nullable NSDate *)dateFromRFC3339String:(NSString *)dateString {
  setupDateFormatterOnce();
  NSDate *rfc3339Date = [sRFC3339DateFormatter dateFromString:dateString];
  return rfc3339Date;
}

- (nullable NSString *)RFC3339StringFromDate:(NSDate *)date {
  setupDateFormatterOnce();
  NSString *rfc3339String = [sRFC3339DateFormatter stringFromDate:date];
  return rfc3339String;
}

@end
