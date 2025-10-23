BOOL swizzleLog=true;

BOOL swizzleImp(NSString* className,NSString* selName,BOOL isInstance,IMP newImp,IMP* oldImpOut)
{
	Class class=NSClassFromString(className);
	if(!class)
	{
		if(swizzleLog)
		{
			trace(@"swizzleImp failure (class lookup): %@ %@",className,selName);
		}
		return false;
	}
	
	SEL sel=NSSelectorFromString(selName);
	
	Method method=(isInstance?class_getInstanceMethod:class_getClassMethod)(class,sel);
	if(!method)
	{
		if(swizzleLog)
		{
			trace(@"swizzleImp failure (method lookup): %@ %@",className,selName);
		}
		return false;
	}
	
	IMP oldImp=method_setImplementation(method,newImp);
	if(oldImpOut)
	{
		*oldImpOut=oldImp;
	}
	
	if(swizzleLog)
	{
		trace(@"swizzleImp success: %@ %@",className,selName);
	}
	
	return true;
}

BOOL addImp(NSString* className,NSString* selName,BOOL isInstance,IMP imp,NSString* types)
{
	Class class=(isInstance?objc_getClass:objc_getMetaClass)(className.UTF8String);
	if(!class)
	{
		if(swizzleLog)
		{
			trace(@"addImp failure (class lookup): %@ %@",className,selName);
		}
		return false;
	}
	
	SEL sel=NSSelectorFromString(selName);
	
	if(!class_addMethod(class,sel,imp,types.UTF8String))
	{
		if(swizzleLog)
		{
			trace(@"addImp failure (add method): %@ %@",className,selName);
		}
		return false;
	}
	
	if(swizzleLog)
	{
		trace(@"addImp success: %@ %@",className,selName);
	}
	
	return true;
}
