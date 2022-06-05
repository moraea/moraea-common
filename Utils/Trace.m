// TODO: reimplement print-to-file
// TODO: reimplement indentation and custom prefixes
// and then update other code to use it

BOOL traceLog=false;
BOOL tracePrint=true;
NSString* tracePrefix=@"Moraea";

#define TRACE_LOG_LIMIT 800

void trace(NSString* format,...)
{
	va_list argList;
	va_start(argList,format);
	NSString* message=[NSString.alloc initWithFormat:format arguments:argList];
	va_end(argList);
	
	if(traceLog)
	{
		// workaround NSLog character limit
		
		if(message.length>TRACE_LOG_LIMIT)
		{
			for(long offset=0;offset<message.length;offset+=TRACE_LOG_LIMIT)
			{
				NSRange range=NSMakeRange(offset,MIN(TRACE_LOG_LIMIT,message.length-offset));
				NSString* chunk=[message substringWithRange:range];
				NSLog(@"%@ (chunked): %@",tracePrefix,chunk);
			}
		}
		else
		{
			NSLog(@"%@: %@",tracePrefix,message);
		}
	}
	
	if(tracePrint)
	{
		printf("\e[35m%s\e[0m\n",message.UTF8String);
		fflush(stdout);
	}
	
	message.release;
}