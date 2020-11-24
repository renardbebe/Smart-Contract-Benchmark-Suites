 

pragma solidity ^0.4.23;

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;

  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

}

contract RockzToken {

    using SafeMath for uint;

     
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;

     
    string public name;
    uint8 public decimals;
    string public symbol;

     
    address public centralMinter;

     
    address public owner;

     
    modifier onlyMinter {
        require(msg.sender == centralMinter);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Mint(address indexed _minter, address indexed _to, uint256 _value, bytes _data);
    event Mint(address indexed _to, uint256 _value);
    event Burn(address indexed _who, uint256 _value, bytes _data);
    event Burn(address indexed _who, uint256 _value);

     
    constructor() public {
        totalSupply = 0;
        name = "Rockz Coin";
        decimals = 2;
        symbol = "RKZ";
        owner = msg.sender;
    }

     


     
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _owner, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[_owner] >= _value);
        require(allowances[_owner][msg.sender] >= _value);
        balances[_owner] = balances[_owner].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_owner][msg.sender] = allowances[_owner][msg.sender].sub(_value);
        bytes memory empty;
        emit Transfer(_owner, _to, _value, empty);
        emit Transfer(_owner, _to, _value);
        return true;
    }
     


     

     
    function transfer(address _to, uint _value) public {
        bytes memory empty;

        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, empty);
        emit Transfer(msg.sender, _to, _value);
    }

     
    function transfer(address _to, uint _value, bytes memory _data) public {
         
         
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
    }

     


     
     
    function mint(uint256 _amountToMint, bytes memory _data) public onlyMinter {
        balances[centralMinter] = balances[centralMinter].add(_amountToMint);
        totalSupply = totalSupply.add(_amountToMint);

        emit Mint(centralMinter, centralMinter, _amountToMint, _data);
        emit Mint(centralMinter, _amountToMint);
        emit Transfer(owner, centralMinter, _amountToMint, _data);
        emit Transfer(owner, centralMinter, _amountToMint);
    }

     
    function burn(uint256 _amountToBurn, bytes memory _data) public onlyMinter returns (bool success) {
        require(balances[centralMinter] >= _amountToBurn);
        balances[centralMinter] = balances[msg.sender].sub(_amountToBurn);
        totalSupply = totalSupply.sub(_amountToBurn);
        emit Burn(centralMinter, _amountToBurn, _data);
        emit Burn(centralMinter, _amountToBurn);
        return true;
    }

     

     
     
    function transferMinter(address _newMinter) public onlyOwner {
        require(_newMinter != address(0));
        centralMinter = _newMinter;
    }
     

}