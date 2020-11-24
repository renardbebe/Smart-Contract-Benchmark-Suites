 

pragma solidity ^0.4.18;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TOKENERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    event ApprovedFunds(address target, bool approved);


    function TOKENERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public LockList;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);


     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require (LockList[_from] == false);
        require (LockList[_to] == false);
        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);

    }
    
     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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

}

contract SteabitToken is owned, TOKENERC20 {


     
    function SteabitToken () TOKENERC20(
        40000000000 * 1 ** uint256(decimals),
    "SteabitToken",
    "SBT") public {
    }
    
    
    

     
    function burnFrom(address Account, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[Account] -= _value;             
        totalSupply -= _value;                       
        Burn(Account, _value);
        Transfer(Account, address(0), _value);
        return true;
    }
    
    function UserLock(address Account, bool mode) onlyOwner public {
        LockList[Account] = mode;
    }
    
    function LockMode(address Account) onlyOwner public returns (bool mode){
        return LockList[Account];
    }
    
}