 

pragma solidity 		^0.4.8	;							
											
	contract	Ownable		{							
		address	owner	;							
											
		function	Ownable	() {							
			owner	= msg.sender;							
		}									
											
		modifier	onlyOwner	() {							
			require(msg.sender ==		owner	);					
			_;								
		}									
											
		function 	transfertOwnership		(address	newOwner	)	onlyOwner	{		
			owner	=	newOwner	;					
		}									
	}										
											
											
											
	contract	MBS_Portfolio				is	Ownable	{			
											
		string	public	constant	name =	"	MBS_Portfolio		"	;	
		string	public	constant	symbol =	"	MBSP		"	;	
		uint32	public	constant	decimals =		18			;	
		uint	public		totalSupply =		18469005868891900000000000			;	
											
		mapping (address => uint) balances;									
		mapping (address => mapping(address => uint)) allowed;									
											
		function mint(address _to, uint _value) onlyOwner {									
			assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);								
			balances[_to] += _value;								
			totalSupply += _value;								
		}									
											
		function balanceOf(address _owner) constant returns (uint balance) {									
			return balances[_owner];								
		}									
											
		function transfer(address _to, uint _value) returns (bool success) {									
			if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {								
				balances[msg.sender] -= _value; 							
				balances[_to] += _value;							
				return true;							
			}								
			return false;								
		}									
											
		function transferFrom(address _from, address _to, uint _value) returns (bool success) {									
			if( allowed[_from][msg.sender] >= _value &&								
				balances[_from] >= _value 							
				&& balances[_to] + _value >= balances[_to]) {							
				allowed[_from][msg.sender] -= _value;							
				balances[_from] -= _value;							
				balances[_to] += _value;							
				Transfer(_from, _to, _value);							
				return true;							
			}								
			return false;								
		}									
											
		function approve(address _spender, uint _value) returns (bool success) {									
			allowed[msg.sender][_spender] = _value;								
			Approval(msg.sender, _spender, _value);								
			return true;								
		}									
											
		function allowance(address _owner, address _spender) constant returns (uint remaining) {									
			return allowed[_owner][_spender];								
		}									
											
		event Transfer(address indexed _from, address indexed _to, uint _value);									
		event Approval(address indexed _owner, address indexed _spender, uint _value);									
 
											
											
											
	 
											
											
		string	inData_1	=	"	une première phrase			"	;	
											
		function	setData_1	(	string	newData_1	)	public	onlyOwner	{	
			inData_1	=	newData_1	;					
		}									
											
		function	getData_1	()	public	constant	returns	(	string	)	{
			return	inData_1	;						
		}									
											
											
											
	 
											
											
		string	inData_2	=	"	une première phrase			"	;	
											
		function	setData_2	(	string	newData_2	)	public	onlyOwner	{	
			inData_2	=	newData_2	;					
		}									
											
		function	getData_2	()	public	constant	returns	(	string	)	{
			return	inData_2	;						
		}									
											
											
											
	 
											
											
		string	inData_3	=	"	une première phrase			"	;	
											
		function	setData_3	(	string	newData_3	)	public	onlyOwner	{	
			inData_3	=	newData_3	;					
		}									
											
		function	getData_3	()	public	constant	returns	(	string	)	{
			return	inData_3	;						
		}									
											
											
											
	 
											
											
		string	inData_4	=	"	une première phrase			"	;	
											
		function	setData_4	(	string	newData_4	)	public	onlyOwner	{	
			inData_4	=	newData_4	;					
		}									
											
		function	getData_4	()	public	constant	returns	(	string	)	{
			return	inData_4	;						
		}									
											
											
											
	 
											
											
		string	inData_5	=	"	une première phrase			"	;	
											
		function	setData_5	(	string	newData_5	)	public	onlyOwner	{	
			inData_5	=	newData_5	;					
		}									
											
		function	getData_5	()	public	constant	returns	(	string	)	{
			return	inData_5	;						
		}									
											
											
	}