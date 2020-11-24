 

pragma solidity 0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract BikeCrowdsale is Ownable, StandardToken {
    string public constant name = "Blockchain based Bike Token";  
    string public constant symbol = "BBT";  
    uint8 public constant decimals = 18;

    using SafeMath for uint256;

    struct Investor {
        uint256 weiDonated;
        uint256 tokensGiven;
        uint256 freeTokens;
    }

    mapping(address => Investor) participants;

    uint256 public totalSupply= 5*10**9 * 10**18;  
    uint256 public hardCap = 1000000 * 10**18;  
    uint256 public minimalGoal = 1000 * 10**18;  
    uint256 public weiToToken = 5000;  
    uint256 public totalSoldTokens = 0;
    uint256 public openingTime = 1537372800;  
    uint256 public closingTime = 1568044800;  

    uint256 public totalCollected;  

    bool public ICOstatus = true;  
    bool public hardcapReached = false;  
    bool public minimalgoalReached = false;  
    bool public isRefundable = true;  

    address public forSale;  
    address public ecoSystemFund;  
    address public founders;  
    address public team;  
    address public advisers;  
    address public bounty;  
    address public affiliate;  

    address private crowdsale;
 
     


  constructor(
     
    ) public {

    require(hardCap > minimalGoal);
    require(openingTime < closingTime);
     
    crowdsale = address(this);

    forSale = 0xf6ACFDba39D8F786D0D2781A1D20C82E47adF8b7;
    ecoSystemFund = 0x5A77aAE15258a2a4445C701d63dbE74016F7e629;
    founders = 0xA80A449514541aeEcd3e17BECcC74a86e3de6bfA;
    team = 0x309d62B8eaDF717b76296326CA35bB8f2D996B1a;
    advisers = 0xc4319217ca328F7518c463D6D3e78f68acc5B076;
    bounty = 0x3605e4E99efFaB70D0C84aA2beA530683824246f;
    affiliate = 0x1709365100eD9B7c417E0dF0fdc32027af1DAff1;

     

    balances[team] = totalSupply * 28 / 100;
    balances[founders] = totalSupply * 12 / 100;
    balances[bounty] = totalSupply * 1 / 100;
    balances[affiliate] = totalSupply * 1 / 100;
    balances[advisers] = totalSupply * 1 / 100;
    balances[ecoSystemFund] = totalSupply * 5 / 100;
    balances[forSale] = totalSupply * 52 / 100;

    emit Transfer(0x0, team, balances[team]);
    emit Transfer(0x0, founders, balances[founders]);
    emit Transfer(0x0, bounty, balances[bounty]);
    emit Transfer(0x0, affiliate, balances[affiliate]);
    emit Transfer(0x0, advisers, balances[advisers]);
    emit Transfer(0x0, ecoSystemFund, balances[ecoSystemFund]);
    emit Transfer(0x0, forSale, balances[forSale]);
  }


   
   


  function () external payable {

    require(msg.value >= 0.1 ether);  
    require(now >= openingTime);
    require(now <= closingTime);
    require(hardCap > totalCollected);
    require(isICOActive());
    require(!hardcapReached);

    sellTokens(msg.sender, msg.value);  
  }


  function sellTokens(address _recepient, uint256 _value) private
  {
    require(_recepient != 0x0);  
    require(now >= openingTime && now <= closingTime);

     

     
     
    uint256 newTotalCollected = totalCollected + _value;  

    if (hardCap <= newTotalCollected) {
        hardcapReached = true;  
        ICOstatus = false;   
        isRefundable = false;  
        minimalgoalReached = true;
    }

    totalCollected = totalCollected + _value;  

    if (minimalGoal <= newTotalCollected) {
        minimalgoalReached = true;  
        isRefundable = false;  
    }

    uint256 tokensSold = _value * weiToToken;  
    uint256 bonusTokens = 0;
    bonusTokens = getBonusTokens(tokensSold);
    if (bonusTokens > 0) {
        tokensSold += bonusTokens;
    }

        require(balances[forSale] > tokensSold);
        balances[forSale] -= tokensSold;
        balances[_recepient] += tokensSold;
        emit Transfer(forSale, _recepient, tokensSold);

    participants[_recepient].weiDonated += _value;
    participants[_recepient].tokensGiven += tokensSold;

    totalSoldTokens += tokensSold;     
  }


  function isICOActive() private returns (bool) {
    if (now >= openingTime  && now <= closingTime && !hardcapReached) {
        ICOstatus = true;
    } else {
        ICOstatus = false;
    }
    return ICOstatus;
  }


  function refund() public {
    require(now >= openingTime);
    require(now <= closingTime);
    require(isRefundable);

    uint256 weiDonated = participants[msg.sender].weiDonated;
    uint256 tokensGiven = participants[msg.sender].tokensGiven;

    require(weiDonated > 0);
    require(tokensGiven > 0);

    require(forSale != msg.sender);
    require(balances[msg.sender] >= tokensGiven); 

    balances[forSale] += tokensGiven;
    balances[msg.sender] -= tokensGiven;
    emit Transfer(msg.sender, forSale, tokensGiven);

     
    msg.sender.transfer(weiDonated);     

    participants[msg.sender].weiDonated = 0;     
    participants[msg.sender].tokensGiven = 0;    
    participants[msg.sender].freeTokens = 0;  
 
     
    totalSoldTokens -= tokensGiven;
    totalCollected -= weiDonated;
  }


  function transferICOFundingToWallet(uint256 _value) public onlyOwner() {
        forSale.transfer(_value);  
  }

  function getBonusTokens(uint256 _tokensSold) view public returns (uint256) {

    uint256 bonusTokens = 0;
    uint256 bonusBeginTime = openingTime;  
     
    if (now >= bonusBeginTime && now <= bonusBeginTime+86400*7) {
        bonusTokens = _tokensSold * 20 / 100;
    } else if (now > bonusBeginTime+86400*7 && now <= bonusBeginTime+86400*14) {
        bonusTokens = _tokensSold * 15 / 100;
    } else if (now > bonusBeginTime+86400*14 && now <= bonusBeginTime+86400*21) {
        bonusTokens = _tokensSold * 10 / 100;
    } else if (now > bonusBeginTime+86400*21 && now <= bonusBeginTime+86400*30) {
        bonusTokens = _tokensSold * 5 / 100;
    }

    uint256 newTotalSoldTokens = _tokensSold + bonusTokens;
    uint256 hardCapTokens = hardCap * weiToToken;
    if (hardCapTokens < newTotalSoldTokens) {
        bonusTokens = 0;
    }

    return bonusTokens;
  }

    function getCrowdsaleStatus() view public onlyOwner() returns (bool,bool,bool,bool) {
        return (ICOstatus,isRefundable,minimalgoalReached,hardcapReached);
    }

  function getCurrentTime() view public onlyOwner() returns (uint256) {
    return now;
  }

  function sendFreeTokens(address _to, uint256 _value) public onlyOwner() {
    require(_to != 0x0);  
    require(participants[_to].freeTokens <= 1000);  
    require(_value <= 100);  
    require(_value > 0);
    require(forSale != _to);
    require(balances[forSale] > _value);

    participants[_to].freeTokens += _value;
    participants[_to].tokensGiven += _value;
    totalSoldTokens += _value;     

    balances[forSale] -= _value;
    balances[_to] += _value;

    emit Transfer(forSale, _to, _value);
  }

   
  function getFreeTokensAmountOfUser(address _to) view public onlyOwner() returns (uint256) {
    require(_to != 0x0);  
    uint256 _tokens = 0;
    _tokens = participants[_to].freeTokens;
    return _tokens;
  }

  function getBalanceOfAccount(address _to) view public onlyOwner() returns (uint256, uint256) {
    return (participants[_to].weiDonated, participants[_to].tokensGiven);
  }

    function transferFundsTokens(address _from, address _to, uint256 _value) public onlyOwner() {
        require(_from == team || _from == founders || _from == bounty || _from == affiliate || _from == advisers || _from == ecoSystemFund || _from == forSale);
        require(_to == team || _to == founders || _to == bounty || _to == affiliate || _to == advisers || _to == ecoSystemFund || _to == forSale);
        require(_value > 0);
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }
}