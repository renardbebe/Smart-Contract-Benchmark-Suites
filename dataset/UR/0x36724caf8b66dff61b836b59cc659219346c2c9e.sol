 

pragma solidity ^0.4.16;

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

     
    mapping (address => bool) public notaioAccounts;

    modifier onlyNotaio {
         
        require(isNotaio(msg.sender));
        _;
    }

     
     
    function isNotaio(address target) public view returns (bool status) {
        return notaioAccounts[target];
    }

     
     
    function setNotaio(address target) onlyOwner public {
        notaioAccounts[target] = true;
    }

     
     
    function unsetNotaio(address target) onlyOwner public {
        notaioAccounts[target] = false;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name = "Rocati";
    string public symbol = "Ʀ";
    uint8 public decimals = 18;
    uint256 public totalSupply = 50000000 * 10 ** uint256(decimals);

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20() public {
        balanceOf[msg.sender] = totalSupply;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
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

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= allowance[_from][msg.sender]);
         
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(balanceOf[msg.sender] >= _value);
         
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
}

 
 
 

contract Rocati is owned, TokenERC20 {
     
    function Rocati() TokenERC20() public {}

     
     
     
    function transferNewCoin(address target, uint256 newAmount) onlyOwner public {
         
        require(isNotaio(target));
        require(balanceOf[target] + newAmount > balanceOf[target]);
         
        balanceOf[target] += newAmount;
        totalSupply += newAmount;
        Transfer(0, this, newAmount);
        Transfer(this, target, newAmount);
    }
}