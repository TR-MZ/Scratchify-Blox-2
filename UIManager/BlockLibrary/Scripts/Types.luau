export type Block = {
	Name: string,
	Description: string,
	Type: string,
	Elements : {{contentType: string, content: string}},
	Code: string,
	Id: BlockId
	-- TODO
}


export type BlockPack = {
	Name: string,
	Description: string,
	PackId: string,
	IconColor: string, 
	ContentBlockIds: {BlockId}
}

export type BlockId = string

return nil
