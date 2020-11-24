 

pragma solidity ^0.4.16;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BitexGlobalXBXCoin  {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    address public owner;

     
    mapping (address => uint256) public balanceOf;
	 mapping (address => uint256) public lockAmount;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	 
	
	event Lock(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);
    
     
    event eventForAllTxn(address indexed from, address indexed to, uint256 value, string eventName, string platformTxId);

     
    

   constructor (
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
	string plaformTxId
	) public {
        totalSupply = initialSupply;                         
        balanceOf[msg.sender] = initialSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;
        owner = msg.sender;
        emit eventForAllTxn(msg.sender, msg.sender, totalSupply,"DEPLOY", plaformTxId);
    }

     
    function _transfer(address _from, address _to, uint _value,string plaformTxId) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
	     
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        emit eventForAllTxn(_from, _to, _value,"TRANSFER",plaformTxId);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transferForExchange(address _to, uint256 _value,string plaformTxId) public returns (bool success) {
       require(balanceOf[msg.sender] - lockAmount[msg.sender] >= _value); 
		_transfer(msg.sender, _to, _value,plaformTxId);
        return true;
    }
	
	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
       require(balanceOf[msg.sender] - lockAmount[msg.sender] >= _value); 
		_transfer(msg.sender, _to, _value,"OTHER");
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
		require(balanceOf[_from] - lockAmount[_from] >= _value); 
        allowance[_from][msg.sender] -= _value;
       
       _transfer(_from, _to, _value, "OTHER");
        return true;
    }
	 
	function transferFromForExchange(address _from, address _to, uint256 _value, string plaformTxId) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
		require(balanceOf[_from] - lockAmount[_from] >= _value); 
        allowance[_from][msg.sender] -= _value;
       
       _transfer(_from, _to, _value, plaformTxId);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require(msg.sender==owner);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
	 
	 function lock(address _spender, uint256 _value) public
        returns (bool success) {
		require(msg.sender==owner);
		 require(balanceOf[_spender] >= _value);  
       lockAmount[_spender] += _value;
	   emit Lock(msg.sender, _spender, _value);
        return true;
    }
	
	 
	 function unlock(address _spender, uint256 _value) public
        returns (bool success) {
		require(msg.sender==owner);
		require(balanceOf[_spender] >= _value);  
       lockAmount[_spender] -= _value;
	   emit Lock(msg.sender, _spender, _value);
        return true;
    }
	
	 
  
  
  

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value, string plaformTxId) public returns (bool success) {
        require(msg.sender==owner);
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        emit eventForAllTxn(msg.sender, msg.sender, _value,"BURN", plaformTxId);
        return true;
    }
    
       
    
    function mint(uint256 _value, string plaformTxId) public returns (bool success) {  
    	require(msg.sender==owner);
		require(balanceOf[msg.sender] + _value <= 300000000);      
        balanceOf[msg.sender] += _value;                           
        totalSupply += _value;                                     
         emit eventForAllTxn(msg.sender, msg.sender, _value,"MINT", plaformTxId);
        return true;
    }

    
}