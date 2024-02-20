@import Foundation;
@import MachO;
#define trace NSLog

int main(int argc,char** argv)
{
	NSString* input=[NSString stringWithUTF8String:argv[1]];
	NSString* output=[NSString stringWithUTF8String:argv[2]];
	
	trace(@"kill symtab read %@",input);
	
	NSMutableData* data=[NSMutableData dataWithContentsOfFile:input];
	
	BOOL gotDyld=false;
	BOOL gotLegacy=false;
	
	struct mach_header_64* header=(struct mach_header_64*)data.mutableBytes;
	struct load_command* command=(struct load_command*)(header+1);
	for(int commandIndex=0;commandIndex<header->ncmds;commandIndex++)
	{
		if(command->cmd==LC_DYLD_INFO)
		{
			struct dyld_info_command* info=(struct dyld_info_command*)command;
			
			info->cmd=LC_DYLD_INFO_ONLY;
			
			gotDyld=true;
		}
		
		if(command->cmd==LC_SYMTAB)
		{
			struct symtab_command* info=(struct symtab_command*)command;
			
			info->symoff=0;
			info->nsyms=0;
			// info->stroff=0;
			// info->strsize=0;
			
			gotLegacy=true;
		}
		
		command=(struct load_command*)(((char*)command)+command->cmdsize);
	}
	
	assert(gotDyld&&gotLegacy);
	
	trace(@"kill symtab write %@",output);
	
	[data writeToFile:output atomically:true];
}