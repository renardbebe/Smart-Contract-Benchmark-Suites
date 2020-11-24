 

pragma solidity ^0.4.19;

 
contract Ownable {
	address public owner;														 

	function Ownable() public 
	{
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	 
	function transferOwnership(address newOwner) onlyOwner public{
		if (newOwner != address(0)) {
		owner = newOwner;
		}
	}
	
	function kill() onlyOwner public{
		selfdestruct(owner);
	}
}

 
interface tokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)public; 
}


contract TOSKYTokenERC20 is Ownable{
	
	 
    string public name;															 
    string public symbol;														 
    uint8 public decimals;														 
    uint256 public totalSupply;													 

     
    mapping (address => uint256) public balanceOf;								 
    mapping (address => mapping (address => uint256)) public allowance;			 
	mapping (address => bool) public blackList;	
	 

	
	 
    event Transfer(address indexed from, address indexed to, uint256 value);	 
	 
	
	
	 
    function TOSKYTokenERC20 () public {
		decimals=9;															 
		totalSupply = 2000000000 * 10 ** uint256(decimals);  				 
        balanceOf[owner] = totalSupply;                					 
        name = "TOSKY Share";                                   					 
        symbol = "TOSKY";                               					 
        
    }
	 
	
	 
	
	 
    function _transfer(address _from, address _to, uint _value) internal notInBlackList(_from){
		 
		require(_to != 0x0);						 
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

         
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
		
		 
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
	
	
	 
    function transfer(address _to, uint256 _value) public {
		
        _transfer(msg.sender, _to, _value);
    }	
	
	 

    function transferFrom(address _from, address _to, uint256 _value) public 
	returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     					 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
	 
    function approve(address _spender, uint256 _value) notInBlackList(_spender) public 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
        }
	
	modifier notInBlackList(address _value) {
		require(blackList[_value]==false);
		_;
	}
	
	
	function addToBlackList(address _value) public onlyOwner
	{
		blackList[_value]=true;
	}
	 
	function delFromBlackList(address _value) public onlyOwner
	{
	   blackList[_value]=false;
	}
	
	 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) notInBlackList(_spender) public 
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
     
    function transferOwnershipWithBalance(address newOwner) onlyOwner public{
		if (newOwner != address(0)) {
		    _transfer(owner,newOwner,balanceOf[owner]);
		    owner = newOwner;
		}
	}
    
}