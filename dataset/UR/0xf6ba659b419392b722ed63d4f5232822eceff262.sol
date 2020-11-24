 

pragma solidity 0.5.8;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract Ownable {
  address payable public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor () public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalTokenSupply;

   
  function totalSupply() public view returns (uint256) {
    return totalTokenSupply;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value, string reason);

   
  function burn(uint256 _value, string memory _reason) public {
    require(_value <= balances[msg.sender]);
	   
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalTokenSupply = totalTokenSupply.sub(_value);
    emit Burn(burner, _value, _reason);
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
    require(_from != address(0));
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));

	allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(_spender != address(0));

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract DACXToken is StandardToken, BurnableToken, Ownable {
    using SafeMath for uint;

    string constant public symbol = "DACX";
    string constant public name = "DACX Token";

    uint8 constant public decimals = 18;

     
    uint constant unlockTime = 1593561600;  

     
    
     
    address company = 0x12Fc4aD0532Ef06006C6b85be4D377dD1287a991;
    
     
    address angel = 0xfd961aDDEb5198B2a7d9DEfabC405f2FBa38E88b;
    
     
    address team = 0xd3544D8569EFc16cAA1EF22D77B37d3fe98CA617;

     
    address locked = 0x612D44Aea422093aEB56049eDb53a213a3F4689F;

     
    address crowdsale = 0x939276d1dA91B9327a3BA4E896Fb624C97Eedf4E;
    
     
    address bounty = 0x40e70bD19b1b1d792E4f850ea78691Ccd42B84Ea;


     
    uint constant lockedTokens     = 1966966964e17;  
    uint constant angelTokens      =  393393393e17;  
    uint constant teamTokens       = 1180180180e17;  
    uint constant crowdsaleTokens  = 3933933930e17;  
    uint constant bountyTokens     =  393393393e17;  


    constructor () public {

        totalTokenSupply = 0;

         
        setInitialTokens(locked, lockedTokens);
        setInitialTokens(angel, angelTokens);
        setInitialTokens(team, teamTokens);
        setInitialTokens(crowdsale, crowdsaleTokens);
        setInitialTokens(bounty, bountyTokens);

    }

    function setInitialTokens(address _address, uint _amount) internal {
        totalTokenSupply = totalTokenSupply.add(_amount);
        balances[_address] = _amount;
        emit Transfer(address(0x0), _address, _amount);
    }

    function checkPermissions(address _from) internal view returns (bool) {

        if (_from == locked && now < unlockTime) {
            return false;
        } else {
            return true;
        }

    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(msg.sender));
        bool ret = super.transfer(_to, _value);
        return ret;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(_from));
        bool ret = super.transferFrom(_from, _to, _value);
        return ret;
    }

    function () external payable {
	    require(msg.data.length == 0);
        require(msg.value >= 1e16);
        owner.transfer(msg.value);
    }

}