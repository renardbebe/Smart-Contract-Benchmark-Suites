 

 

pragma solidity ^0.4.6;

contract SafeMath {
   

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract DWalletToken is SafeMath {

     
    string public standard = 'ERC20';
    string public name = 'D-WALLET TOKEN';
    string public symbol = 'DWT';
    uint8 public decimals = 0;
    uint256 public totalSupply;
    address public owner;
     
    uint256 public startTime = 1503752400;
	 
	uint256 public endTime = 1508950800;
     
    bool burned;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	event Burned(uint amount);
	   
    function () payable {
     owner.transfer(msg.value);
   }

     
    function DWalletToken() {
        owner = 0x1C46b45a7d6d28E27A755448e68c03248aefd18b;
        balanceOf[owner] = 10000000000;               
        totalSupply = 10000000000;                    
    }

     
    function transfer(address _to, uint256 _value) returns (bool success){
        require (now < startTime);  
        require(msg.sender == owner && now < startTime + 1 years && safeSub(balanceOf[msg.sender],_value) < 1000000000);  
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);                      
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);                             
        Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (now < startTime && _from!=owner);  
        require(_from == owner && now < startTime + 1 years && safeSub(balanceOf[_from],_value) < 1000000000);
        var _allowance = allowance[_from][msg.sender];
        balanceOf[_from] = safeSub(balanceOf[_from],_value);  
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);      
        allowance[_from][msg.sender] = safeSub(_allowance,_value);
        Transfer(_from, _to, _value);
        return true;
    }


     
    function burn(){
    	 
    	if(!burned && now>endTime){
    		uint difference = safeSub(balanceOf[owner], 1024000000); 
    		balanceOf[owner] = 1024000000;
    		totalSupply = safeSub(totalSupply, difference);
    		burned = true;
    		Burned(difference);
    	}
    }

}