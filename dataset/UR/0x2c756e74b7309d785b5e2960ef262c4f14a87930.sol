 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    constructor() public {
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

 
contract Pausable is owned {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused {
        require(paused == false);
        _;
    }

     
    modifier whenPaused {
        require(paused == true);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract StandardToken is Pausable {
     
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    uint256 public currentSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor(
        uint256 initialSupply,
        uint256 maxSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        currentSupply = initialSupply;   
        totalSupply = maxSupply;
        balanceOf[msg.sender] = currentSupply;                     
        name = tokenName;                                          
        symbol = tokenSymbol;                                      
    }

     
    function _transfer(address _from, address _to, uint _value) internal { 
        require(_to != 0x0);                                
        require(balanceOf[_from] >= _value);                
        require(balanceOf[_to] + _value > balanceOf[_to]);  

        uint previousBalances = balanceOf[_from] + balanceOf[_to];  
        balanceOf[_from] -= _value;                                 
        balanceOf[_to] += _value;                                   
        emit Transfer(_from, _to, _value);

         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function Supplies() view public 
        returns (uint256 total, uint256 current) {
        return (totalSupply, currentSupply);
    }

     
     
     
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        currentSupply -= _value;                     
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        currentSupply -= _value;                             
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 

contract AdvancedToken is owned, StandardToken {
    
    mapping (address => bool) public frozenAccount;

     
    constructor(
        uint256 initialSupply,
        uint256 maxSupply,
        string tokenName,
        string tokenSymbol
    ) StandardToken(initialSupply, maxSupply, tokenName, tokenSymbol) public {}

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require (totalSupply >= currentSupply + mintedAmount);
        balanceOf[target] += mintedAmount;
        currentSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
    event FrozenFunds(address target, bool frozen);

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        emit Transfer(_from, _to, _value);
    }

     
     
    function freezeAccount(address target) onlyOwner public {
        frozenAccount[target] = true;
        emit FrozenFunds(target, true);
    }

     
     
    function unfreezeAccount(address target) onlyOwner public {
        frozenAccount[target] = false;
        emit FrozenFunds(target, false);
    }

    function () payable public {
    }
}