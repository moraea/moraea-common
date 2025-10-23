#import "Utils.h"

int main(int argc,char** argv)
{
	if(argc!=3)
	{
		trace(@"tool to convert MH_BUNDLE to MH_DYLIB for wrapping/linking\nusage: %s <dylib> <install path>",argv[0]);
		return 1;
	}
	
	NSString* path=[NSString stringWithUTF8String:argv[1]];
	NSString* install=[NSString stringWithUTF8String:argv[2]];
	
	trace(@"read %@",path);
	
	NSMutableData* data=[NSMutableData dataWithContentsOfFile:path];
	assert(data);
	
	struct mach_header_64* header=(struct mach_header_64*)data.mutableBytes;
	if(header->magic!=MH_MAGIC_64)
	{
		trace(@"magic not %x (maybe a fat binary?)",MH_MAGIC_64);
		exit(1);
	}
	
	trace(@"update filetype %d to %d",header->filetype,MH_DYLIB);
	
	header->filetype=MH_DYLIB;
	
	int idCommandSize=sizeof(struct dylib_command)+install.length+8-install.length%8;
	assert(idCommandSize%8==0);
	
	trace(@"add LC_ID_DYLIB name %@ size %d",install,idCommandSize);
	
	struct dylib_command* idCommand=(struct dylib_command*)((char*)(header+1)+header->sizeofcmds);
	memset(idCommand,0,idCommandSize);
	idCommand->cmd=LC_ID_DYLIB;
	idCommand->cmdsize=idCommandSize;
	idCommand->dylib.name.offset=sizeof(struct dylib_command);
	
	char* name=(char*)(idCommand+1);
	memcpy(name,install.UTF8String,install.length);
	
	header->ncmds+=1;
	header->sizeofcmds+=idCommandSize;
	
	int firstSectionOffset=INT_MAX;
	char* firstSectionName=NULL;
	struct load_command* command=(struct load_command*)(header+1);
	for(int index=0;index<header->ncmds;index++)
	{
		if(command->cmd==LC_SEGMENT_64)
		{
			struct segment_command_64* segmentCommand=(struct segment_command_64*)command;
			struct section_64* sections=(struct section_64*)(segmentCommand+1);
			
			for(int index=0;index<segmentCommand->nsects;index++)
			{
				if(sections[index].offset!=0&&sections[index].offset<firstSectionOffset)
				{
					firstSectionOffset=sections[index].offset;
					firstSectionName=sections[index].sectname;
				}
			}
		}
		
		command=(struct load_command*)(((char*)command)+command->cmdsize);
	}
	
	int headerSize=sizeof(struct mach_header_64)+header->sizeofcmds;
	assert(headerSize==(char*)command-(char*)header);
	
	if(headerSize>=firstSectionOffset)
	{
		trace(@"header end %d overruns %s at %d, can't proceed.. 😭",headerSize,firstSectionName,firstSectionOffset);
		exit(1);
	}
	
	trace(@"write %@",path);
	
	assert([data writeToFile:path atomically:false]);
}
