 

pragma solidity 0.5.8;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}


contract ERC20Token is StandardToken {

    string public name;
    string public symbol;
    uint public decimals;
    address public owner;

     
    constructor (
        address benefeciary, 
        string memory _name, 
        string memory _symbol, 
        uint _totalSupply, 
        uint _decimals
    )
        public
    {
        
        decimals = _decimals;
        totalSupply = _totalSupply;
        name = _name;
        owner = benefeciary;
        symbol = _symbol;
        balances[benefeciary] = totalSupply;  
        emit Transfer(address(0), benefeciary, totalSupply);
    }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface token {
  function transferFrom(address, address, uint) external returns (bool);
  function balanceOf(address) external returns (uint);
  function transfer(address, uint) external returns (bool);
}

contract TokenMaker is Ownable {
    uint public fee_in_dc_units = 10e18;
    address public dc_token_address;
    token dcToken;
    mapping (address => address[]) public myTokens;


    function setFee(uint number_of_dc_uints) public onlyOwner {
        fee_in_dc_units = number_of_dc_uints;
    }

    function setDcTokenAddress(address _addr) public onlyOwner {
      dc_token_address = _addr;
      dcToken = token(_addr);
    }

    function makeToken(string memory _name, string memory _symbol, uint _totalSupply, uint _decimals) public {
        require(dcToken.transferFrom(msg.sender, address(this), fee_in_dc_units));

        ERC20Token newToken = new ERC20Token(msg.sender, _name, _symbol, _totalSupply, _decimals);
        myTokens[msg.sender].push(address(newToken));

    }

    function getMyTokens() public view returns (address[] memory) {
      return myTokens[msg.sender];
    }

    function withdrawTokens() public onlyOwner {
      dcToken.transfer(msg.sender, dcToken.balanceOf(address(this)));
    }
}