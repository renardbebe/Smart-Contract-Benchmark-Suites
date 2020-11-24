 

pragma solidity ^0.4.10;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

pragma solidity ^0.4.10;

 
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


pragma solidity ^0.4.21;

 
contract ERC20Basic is Ownable {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  bool transferable = false;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  modifier canTransfer() {
      if (msg.sender != owner) {
          require(transferable);
      }
      _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
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
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


contract PapushaToken is BurnableToken {

    string public constant name = "Papusha Rocket Token";
    string public constant symbol = "PRT";
    uint32 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 100000000 * 1 ether;

    function PapushaToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(address(0), msg.sender, INITIAL_SUPPLY);
        transferable = false;
    }

    modifier saleIsOn() {
        require(transferable == false);
        _;
    }

    function refund(address _from, uint256 _value) onlyOwner saleIsOn public returns(bool) {
        balances[_from] = balances[_from].sub(_value);
        balances[owner] = balances[owner].add(_value);
        Transfer(_from, owner, _value);
        return true;
    }

    function stopSale() onlyOwner saleIsOn public returns(bool) {
        transferable = true;
        return true;
    }

}

pragma solidity ^0.4.21;

contract Presale is Ownable {

    using SafeMath for uint;

    address public multisig;
    uint256 public rate;
    PapushaToken public token;  
    Crowdsale public crowdsale;  
    uint256 public hardcap;
    uint256 public weiRaised;

    uint256 public saleSupply = 60000000 * 1 ether;

    function Presale(address _multisig) public {
        multisig = _multisig;
        rate = 250000000000000;
        token = new PapushaToken();
        hardcap = 5000 * 1 ether;
    }

    modifier isUnderHardcap {
        require(weiRaised < hardcap);
        _;
    }

    function startCrowdsale() onlyOwner public returns(bool) {
        crowdsale = new Crowdsale(multisig, token, saleSupply);
        token.transfer(address(crowdsale), token.balanceOf(this));
        token.transferOwnership(address(crowdsale));
        crowdsale.transferOwnership(owner);
        return true;
    }

    function createTokens() isUnderHardcap payable public {
        uint256 weiAmount = msg.value;
        require(weiAmount <= hardcap - weiRaised);
        weiRaised = weiRaised.add(weiAmount);
        uint256 tokens = weiAmount.div(rate);
        require(saleSupply >= tokens);
        saleSupply = saleSupply.sub(tokens);
        token.transfer(msg.sender, tokens);
        forwardFunds(msg.value);
    }

    function forwardFunds(uint256 _value) private {
        multisig.transfer(_value);
    }

    function setPrice(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    function setMultisig(address _multisig) onlyOwner public {
        multisig = _multisig;
    }

    function() external payable {
        createTokens();
    }

}

pragma solidity ^0.4.10;

contract Crowdsale is Ownable {

    using SafeMath for uint;

    address public multisig;
    uint256 public rate;
    PapushaToken public token;  
    uint256 public saleSupply;
    uint256 public saledSupply;
    bool public saleStopped;
    bool public sendToTeam;

    uint256 public RESERVED_SUPPLY = 40000000 * 1 ether;
    uint256 public BONUS_SUPPLY = 20000000 * 1 ether;

    function Crowdsale(address _multisig, PapushaToken _token, uint _saleSupply) public {
        multisig = _multisig;
        token = _token;
        saleSupply = _saleSupply;
        saleStopped = false;
        sendToTeam = false;
    }

    modifier saleNoStopped() {
        require(saleStopped == false);
        _;
    }

    function stopSale() onlyOwner public returns(bool) {
        if (saleSupply > 0) {
            token.burn(saleSupply);
            saleSupply = 0;
        }
        saleStopped = true;
        return token.stopSale();
    }

    function createTokens() payable public {
        if (saledSupply < BONUS_SUPPLY) {
            rate = 360000000000000;
        } else {
            rate = 410000000000000;
        }
        uint256 tokens = msg.value.div(rate);
        require(saleSupply >= tokens);
        saleSupply = saleSupply.sub(tokens);
        saledSupply = saledSupply.add(tokens);
        token.transfer(msg.sender, tokens);
        forwardFunds(msg.value);
    }

    function adminSendTokens(address _to, uint256 _value) onlyOwner saleNoStopped public returns(bool) {
        require(saleSupply >= _value);
        saleSupply = saleSupply.sub(_value);
        saledSupply = saledSupply.add(_value);
        return token.transfer(_to, _value);
    }

    function adminRefundTokens(address _from, uint256 _value) onlyOwner saleNoStopped public returns(bool) {
        saleSupply = saleSupply.add(_value);
        saledSupply = saledSupply.sub(_value);
        return token.refund(_from, _value);
    }

    function refundTeamTokens() onlyOwner public returns(bool) {
        require(sendToTeam == false);
        sendToTeam = true;
        return token.transfer(msg.sender, RESERVED_SUPPLY);
    }

    function forwardFunds(uint256 _value) private {
        multisig.transfer(_value);
    }

    function setPrice(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    function setMultisig(address _multisig) onlyOwner public {
        multisig = _multisig;
    }

    function() external payable {
        createTokens();
    }

}