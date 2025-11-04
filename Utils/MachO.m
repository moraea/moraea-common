struct load_command* findLoadCommand(char* startPointer,BOOL(^filterBlock)(struct load_command*))
{
	char* pointer=startPointer;
	
	struct mach_header_64* header=(struct mach_header_64*)pointer;
	pointer+=sizeof(struct mach_header_64);
	
	for(unsigned int commandIndex=0;commandIndex<header->ncmds;commandIndex++)
	{
		struct load_command* command=(struct load_command*)pointer;
		if(filterBlock(command))
		{
			return command;
		}
		
		pointer+=command->cmdsize;
	}
	
	return NULL;
}

struct load_command* findLoadCommandOfType(char* startPointer,unsigned int type)
{
	return findLoadCommand(startPointer,^BOOL(struct load_command* command)
	{
		return command->cmd==type;
	});
}

struct segment_command_64* findSegmentCommand(char* startPointer,char* type)
{
	return (struct segment_command_64*)findLoadCommand(startPointer,^BOOL(struct load_command* command)
	{
		if(command->cmd==LC_SEGMENT_64)
		{
			return strcmp(((struct segment_command_64*)command)->segname,type)==0;
		}
		return false;
	});
}

struct section_64* findSectionCommand(char* startPointer,char* segmentType,char* sectionType)
{
	struct segment_command_64* segment=findSegmentCommand(startPointer,segmentType);
	
	struct section_64* section=(struct section_64*)((char*)segment+sizeof(struct segment_command_64));
	for(unsigned int sectionIndex=0;sectionIndex<segment->nsects;sectionIndex++)
	{
		if(strcmp(section->sectname,sectionType)==0)
		{
			return section;
		}
		section++;
	}
	
	return NULL;
}

unsigned long findSymbolOffset(char* startPointer,NSString* targetSymbolName)
{
	char* pointer=startPointer;
	
	struct segment_command_64* textCommand=findSegmentCommand(startPointer,SEG_TEXT);
	struct symtab_command* symtabCommand=(struct symtab_command*)findLoadCommandOfType(startPointer,LC_SYMTAB);
	
	if(!symtabCommand||!textCommand)
	{
		return 0;
	}
	
	char* stringTable=startPointer+symtabCommand->stroff;
	
	unsigned long symbolAddress=0;
	pointer=startPointer+symtabCommand->symoff;
	for(unsigned int symbolIndex=0;symbolIndex<symtabCommand->nsyms;symbolIndex++)
	{
		struct nlist_64* symbolStruct=(struct nlist_64*)pointer;
		NSString* symbolName=[NSString stringWithUTF8String:stringTable+symbolStruct->n_un.n_strx];
		if([symbolName isEqualToString:targetSymbolName])
		{
			symbolAddress=symbolStruct->n_value;
			break;
		}
		
		pointer+=sizeof(struct nlist_64);
	}
	
	unsigned long textDelta=textCommand->vmaddr-textCommand->fileoff;
	unsigned long symbolOffset=symbolAddress-textDelta;
	
	return symbolOffset;
}

// https://en.wikipedia.org/wiki/LEB128#Decode_unsigned_integer

unsigned int readULEB128(char** input)
{
	unsigned int result=0;
	unsigned int shift=0;
	while(true)
	{
		result|=((**input&0x7f)<<shift);
		shift+=7;
		if(!(**input&0x80))
		{
			break;
		}
		*input+=1;
	}
	*input+=1;
	return result;
}

BOOL findLegacySymbolTable(char* pathSearch,struct nlist_64** symbolsOut,int* symbolCountOut,char** stringsOut,long* slideOut)
{
	struct mach_header_64* header=NULL;
	
	int dylibCount=_dyld_image_count();
	for(int index=0;index<dylibCount;index++)
	{
		if(strstr(_dyld_get_image_name(index),pathSearch))
		{
			header=(struct mach_header_64*)_dyld_get_image_header(index);
			break;
		}
	}
	
	if(!header)
	{
		return false;
	}
	
	struct symtab_command* symtabCommand=NULL;
	struct segment_command_64* textCommand=NULL;
	struct segment_command_64* linkeditCommand=NULL;
	
	struct load_command* command=(struct load_command*)(header+1);
	for(int index=0;index<header->ncmds;index++)
	{
		if(command->cmd==LC_SYMTAB)
		{
			symtabCommand=(struct symtab_command*)command;
		}
		
		if(command->cmd==LC_SEGMENT_64)
		{
			struct segment_command_64* segmentCommand=(struct segment_command_64*)command;
			if(!strcmp(segmentCommand->segname,SEG_TEXT))
			{
				textCommand=segmentCommand;
			}
			if(!strcmp(segmentCommand->segname,SEG_LINKEDIT))
			{
				linkeditCommand=segmentCommand;
			}
		}
		
		command=(struct load_command*)(((char*)command)+command->cmdsize);
	}
	
	if(!symtabCommand||!textCommand||!linkeditCommand)
	{
		return false;
	}
	
	long slide=(long)header-textCommand->vmaddr;
	char* symtabBase=(char*)slide+linkeditCommand->vmaddr-linkeditCommand->fileoff;
	
	*symbolsOut=(struct nlist_64*)(symtabBase+symtabCommand->symoff);
	*symbolCountOut=symtabCommand->nsyms;
	*stringsOut=symtabBase+symtabCommand->stroff;
	*slideOut=slide;
	
	return true;
}

char* findLegacySymbol(struct nlist_64* symbols,int symbolCount,char* strings,long slide,char* nameSearch)
{
	for(int index=0;index<symbolCount;index++)
	{
		char* name=strings+symbols[index].n_un.n_strx;
		if(strstr(name,nameSearch))
		{
			return (char*)slide+symbols[index].n_value;
		}
	}
	
	return NULL;
}

/*

TODO: compare performance caching address ranges instead of individual mappings?

*/

NSMutableDictionary<NSNumber*,NSString*>* addressToImageCache=nil;

NSString* getImageWithAddress(void* caller)
{
	NSNumber* key=@((long)caller);
	
	@synchronized(addressToImageCache)
	{
		if(!addressToImageCache)
		{
			addressToImageCache=NSMutableDictionary.alloc.init;
		}
		
		if(!addressToImageCache[key])
		{
			Dl_info info;
			dladdr(caller,&info);
			addressToImageCache[key]=@(info.dli_fname);
		}
		
		return addressToImageCache[key];
	}
}

__attribute__((always_inline)) NSString* getCallingImage()
{
	void* caller=__builtin_extract_return_addr(__builtin_return_address(0));
	
	return getImageWithAddress(caller);
}
