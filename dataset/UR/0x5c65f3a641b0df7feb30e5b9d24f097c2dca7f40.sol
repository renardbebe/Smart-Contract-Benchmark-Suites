 

pragma solidity 		^0.4.8	;							
										
contract	MiniPoolEdit_2		{							
										
	address	owner	;							
										
	function	MiniPoolEdit_2		()	public	{				
		owner	= msg.sender;							
	}									
										
	modifier	onlyOwner	() {							
		require(msg.sender ==		owner	);					
		_;								
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_1	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_1	(	string	newMiniPoolEdit_1	)	public	onlyOwner	{	
		inMiniPoolEdit_1	=	newMiniPoolEdit_1	;					
	}									
										
	function	getMiniPoolEdit_1	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_1	;						
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_2	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_2	(	string	newMiniPoolEdit_2	)	public	onlyOwner	{	
		inMiniPoolEdit_2	=	newMiniPoolEdit_2	;					
	}									
										
	function	getMiniPoolEdit_2	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_2	;						
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_3	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_3	(	string	newMiniPoolEdit_3	)	public	onlyOwner	{	
		inMiniPoolEdit_3	=	newMiniPoolEdit_3	;					
	}									
										
	function	getMiniPoolEdit_3	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_3	;						
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_4	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_4	(	string	newMiniPoolEdit_4	)	public	onlyOwner	{	
		inMiniPoolEdit_4	=	newMiniPoolEdit_4	;					
	}									
										
	function	getMiniPoolEdit_4	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_4	;						
	}									
										
										
										
										
 
										
										
	string	inMiniPoolEdit_5	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_5	(	string	newMiniPoolEdit_5	)	public	onlyOwner	{	
		inMiniPoolEdit_5	=	newMiniPoolEdit_5	;					
	}									
										
	function	getMiniPoolEdit_5	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_5	;						
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_6	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_6	(	string	newMiniPoolEdit_6	)	public	onlyOwner	{	
		inMiniPoolEdit_6	=	newMiniPoolEdit_6	;					
	}									
										
	function	getMiniPoolEdit_6	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_6	;						
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_7	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_7	(	string	newMiniPoolEdit_7	)	public	onlyOwner	{	
		inMiniPoolEdit_7	=	newMiniPoolEdit_7	;					
	}									
										
	function	getMiniPoolEdit_7	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_7	;						
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_8	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_8	(	string	newMiniPoolEdit_8	)	public	onlyOwner	{	
		inMiniPoolEdit_8	=	newMiniPoolEdit_8	;					
	}									
										
	function	getMiniPoolEdit_8	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_8	;						
	}									
										
										
										
 
										
										
	string	inMiniPoolEdit_9	=	"	une première phrase			"	;	
										
	function	setMiniPoolEdit_9	(	string	newMiniPoolEdit_9	)	public	onlyOwner	{	
		inMiniPoolEdit_9	=	newMiniPoolEdit_9	;					
	}									
										
	function	getMiniPoolEdit_9	()	public	constant	returns	(	string	)	{
		return	inMiniPoolEdit_9	;						
	}									
										
										
}