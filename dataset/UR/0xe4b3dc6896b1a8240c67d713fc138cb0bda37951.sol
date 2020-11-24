 

pragma solidity ^0.4.21;

contract owned {
    address public owner;
    function owned() public {owner = msg.sender;}
    modifier onlyOwner { require(msg.sender == owner); _;}
    function transferOwnership(address newOwner) onlyOwner public {owner = newOwner;}
}

contract EmtCrowdfund is owned {
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
    uint256 public tokenPrice;

    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);

    function EmtCrowdfund(
        uint256 initialSupply,
        uint256 _tokenPrice,
        string tokenName,
        string tokenSymbol
    ) public {
        tokenPrice = _tokenPrice / 10 ** uint256(decimals);
        totalSupply = initialSupply * 10 ** uint256(decimals);
        name = tokenName;
        symbol = tokenSymbol;
    }

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

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

     
    function setPrices(uint256 _tokenPrice) onlyOwner public {
        tokenPrice = _tokenPrice;
    }

    function() payable public{
        buy();
    }

     
    function buy() payable public {
        uint amount = msg.value / tokenPrice;
        require (totalSupply >= amount);
        require(!frozenAccount[msg.sender]);
        totalSupply -= amount;
        balanceOf[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

     
    function manualTransfer(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require (totalSupply >= _value);
        require(!frozenAccount[_to]);
        totalSupply -= _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

     
    function withdrawAll() onlyOwner public {
        owner.transfer(address(this).balance);
    }
}