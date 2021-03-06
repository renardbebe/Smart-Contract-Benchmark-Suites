 

pragma solidity ^0.4.25;
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
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
 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function mint(address account, uint256 value) public;
    function burn(address account, uint256 value) public;
    function burnFrom(address account, uint256 value) public;
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
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
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
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

   
  function mint(address account, uint256 value) public {
    require(account != 0);
    totalSupply_ = totalSupply_.add(value);
    balances[account] = balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function burn(address account, uint256 value) public {
    require(account != 0);
    require(value <= balances[account]);

    totalSupply_ = totalSupply_.sub(value);
    balances[account] = balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function burnFrom(address account, uint256 value) public {
    require(value <= allowed[account][msg.sender]);

     
     
    allowed[account][msg.sender] = allowed[account][msg.sender].sub(
      value);
    burn(account, value);
  }
}

 
contract CyBetToken is StandardToken, Ownable {
    string public constant name = "CyBet";
    string public constant symbol = "CYBT";
    uint public constant decimals = 18;
    uint256 public constant tokenReserve = 210000000*10**18;

    constructor() public {
      balances[owner] = balances[owner].add(tokenReserve);
      totalSupply_ = totalSupply_.add(tokenReserve);
    }
}

 
contract Configurable {
    using SafeMath for uint256;
    uint256 public constant cap = 60000000*10**18;
    uint256 public constant basePrice = 1000*10**18;  
    uint256 public tokensSold = 0;
    uint256 public remainingTokens = 0;
}
 
contract Crowdsale is Configurable{
     
     address public admin;
     address private owner;
     CyBetToken public coinContract;
     enum Stages {
        none,
        icoStart,
        icoEnd
    }

    Stages currentStage;

     
    constructor(CyBetToken _coinContract) public {
        admin = msg.sender;
        coinContract = _coinContract;
        owner = coinContract.owner();
        currentStage = Stages.none;
        remainingTokens = cap;
    }

     
    event Invest(address investor, uint value, uint tokens);

     
    function () public payable {
        require(currentStage == Stages.icoStart);
        require(msg.value > 0);
        require(remainingTokens > 0);


        uint256 weiAmount = msg.value; 
        uint256 tokens = weiAmount.mul(basePrice).div(1 ether);  

        require(remainingTokens >= tokens);

        tokensSold = tokensSold.add(tokens);  
        remainingTokens = cap.sub(tokensSold);

        coinContract.transfer(msg.sender, tokens);
        admin.transfer(weiAmount); 

        emit Invest(msg.sender, msg.value, tokens);
    }
     
    function startIco() external {
        require(msg.sender == admin);
        require(currentStage != Stages.icoEnd);
        currentStage = Stages.icoStart;
    }
     
    function endIco() internal {
        require(msg.sender == admin);
        currentStage = Stages.icoEnd;
         
        coinContract.transfer(coinContract.owner(), coinContract.balanceOf(this));
    }
     
    function finalizeIco() external {
        require(msg.sender == admin);
        require(currentStage != Stages.icoEnd);
        endIco();
    }
}