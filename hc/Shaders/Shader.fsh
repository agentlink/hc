//
//  Shader.fsh
//  hc
//
//  Created by Dmitry Semeniouta on 26/06/14.
//  Copyright (c) 2014 JetBrains, Inc. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
