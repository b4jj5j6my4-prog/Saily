//
//  AppFileShare.h
//  Sileo
//
//  Created by admin on 7/5/2024.
//  Copyright © 2024 Sileo Team. All rights reserved.
//

#ifndef AppFileShare_h
#define AppFileShare_h

BOOL IsAppAvailable(NSString* bundleId);

BOOL ShareFileToApp(NSString* bundleId, NSString* path);

#endif /* AppFileShare_h */
