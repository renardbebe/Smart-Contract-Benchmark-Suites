 

pragma solidity ^0.4.25;

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

contract Infireum  is owned {
    string public name;
    string public symbol;
    uint8 public decimals = 8; 
    uint256 public totalSupply;
    mapping (address => bool) public frozenAccount;
    
     
    event FrozenFunds(address target, bool frozen);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);


    constructor() public {
        totalSupply = 10000000000 * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;              
        name = "Infireum";                                 
        symbol = "IFR";                            
    }

    function _transfer(address _from, address _to, uint _value) internal {
  
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);                     
        require(!frozenAccount[_to]);  
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
            emit FrozenFunds(target, freeze);
    }
  
}