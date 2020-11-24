 

 
 

pragma solidity ^0.4.17;

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract StandardToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 

contract CharitySpaceToken is StandardToken {

   
  string public name;                    
  uint8 public decimals;                 
  string public symbol;                  

  address public owner;
  address private icoAddress;

  function CharitySpaceToken(address _icoAddress, address _teamAddress, address _advisorsAddress, address _bountyAddress, address _companyAddress) public {
    totalSupply =  20000000 * 10**18;                     
    uint256 publicSaleSupply = 16000000 * 10**18;         
    uint256 teamSupply = 1500000 * 10**18;                
    uint256 advisorsSupply = 700000 * 10**18;             
    uint256 bountySupply = 800000 * 10**18;               
    uint256 companySupply = 1000000 * 10**18;             
    name = "charityTOKEN";
    decimals = 18;
    symbol = "CHT";

    balances[_icoAddress] = publicSaleSupply;
    Transfer(0, _icoAddress, publicSaleSupply);

    balances[_teamAddress] = teamSupply;
    Transfer(0, _teamAddress, teamSupply);

    balances[_advisorsAddress] = advisorsSupply;
    Transfer(0, _advisorsAddress, advisorsSupply);

    balances[_bountyAddress] = bountySupply;
    Transfer(0, _bountyAddress, bountySupply);

    balances[_companyAddress] = companySupply;
    Transfer(0, _companyAddress, companySupply);

    owner = msg.sender;
    icoAddress = _icoAddress;
  }

  function destroyUnsoldTokens() public {
    require(msg.sender == icoAddress || msg.sender == owner);
    uint256 value = balances[icoAddress];
    totalSupply -= value;
    balances[icoAddress] = 0;
  }
}

 

contract CharitySpace {
  
  struct Tier {
    uint256 tokens;
    uint256 tokensSold;
    uint256 price;
  }
  
   
  event ReceivedETH(address addr, uint value);
  event ReceivedBTC(address addr, uint value, string txid);
  event ReceivedBCH(address addr, uint value, string txid);
  event ReceivedLTC(address addr, uint value, string txid);
  
   
  CharitySpaceToken public charitySpaceToken;
  address public owner;
  address public donationsAddress;
  uint public startDate;
  uint public endDate;
  uint public preIcoEndDate;
  uint256 public tokensSold = 0;
  bool public setuped = false;
  bool public started = false;
  bool public live = false;
  uint public preIcoMaxLasts = 7 days;
   
  Tier[] public tiers;
  
   
  bytes32 private btcHash = keccak256('BTC');
  bytes32 private bchHash = keccak256('BCH');
  
   
  modifier onlyBy(address a) {
    require(msg.sender == a); 
    _;
  }
  
  modifier respectTimeFrame() {
    require((now > startDate) && (now < endDate));
    _;
  }
  
  function CharitySpace(address _donationsAddress) public {
    owner = msg.sender;
    donationsAddress = _donationsAddress;  
  }
  
  function setup(address _charitySpaceToken) public onlyBy(owner) {
    require(started == false);
    require(setuped == false);
    charitySpaceToken = CharitySpaceToken(_charitySpaceToken);
    Tier memory preico = Tier(2500000 * 10**18, 0, 0.0007 * 10**18);
    Tier memory tier1 = Tier(3000000 * 10**18, 0, 0.001 * 10**18);
    Tier memory tier2 = Tier(3500000 * 10**18, 0, 0.0015 * 10**18);
    Tier memory tier3 = Tier(7000000 * 10**18, 0, 0.002 * 10**18);
    tiers.push(preico);
    tiers.push(tier1);
    tiers.push(tier2);
    tiers.push(tier3);
    setuped = true;
  }
  
   
  function start() public onlyBy(owner) {
    require(started == false);
    startDate = now;            
    endDate = now + 30 days + 2 hours;  
    preIcoEndDate = now + preIcoMaxLasts;
    live = true;
    started = true;
  }
  
  function end() public onlyBy(owner) {
    require(started == true);
    require(live == true);
    require(now > endDate);
    charitySpaceToken.destroyUnsoldTokens();
    live = false;
    started = true;
  }
  
  function receiveDonation() public payable respectTimeFrame {
    uint256 _value = msg.value;
    uint256 _tokensToTransfer = 0;
    require(_value > 0);
    
    uint256 _tokens = 0;
    if(preIcoEndDate > now) {
      _tokens = _value * 10**18 / tiers[0].price;
      if((tiers[0].tokens - tiers[0].tokensSold) < _tokens) {
        _tokens = (tiers[0].tokens - tiers[0].tokensSold);
        _value -= ((_tokens * tiers[0].price) / 10**18);
      } else {
        _value = 0;
      }
      tiers[0].tokensSold += _tokens;
      _tokensToTransfer += _tokens;
    }
    if(_value > 0) {
      for (uint i = 1; i < tiers.length; ++i) {
        if(_value > 0 && (tiers[i].tokens > tiers[i].tokensSold)) {
          _tokens = _value * 10**18 / tiers[i].price;
          if((tiers[i].tokens - tiers[i].tokensSold) < _tokens) {
            _tokens = (tiers[i].tokens - tiers[i].tokensSold);
            _value -= ((_tokens * tiers[i].price) / 10**18);
          } else {
            _value = 0;
          }
          tiers[i].tokensSold += _tokens;
          _tokensToTransfer += _tokens;
        }
      }
    }
    
    assert(_tokensToTransfer > 0);
    assert(_value == 0);   
    
    tokensSold += _tokensToTransfer;
    
    assert(charitySpaceToken.transfer(msg.sender, _tokensToTransfer));
    assert(donationsAddress.send(msg.value));
    
    ReceivedETH(msg.sender, msg.value);
  }
  
   
   
  function manuallyConfirmDonation(address donatorAddress, uint256 tokens, uint256 altValue, string altCurrency, string altTx) public onlyBy(owner) respectTimeFrame {
    uint256 _remainingTokens = tokens;
    uint256 _tokens = 0;
    
    if(preIcoEndDate > now) {
       if((tiers[0].tokens - tiers[0].tokensSold) < _remainingTokens) {
        _tokens = (tiers[0].tokens - tiers[0].tokensSold);
      } else {
        _tokens = _remainingTokens;
      }
      tiers[0].tokensSold += _tokens;
      _remainingTokens -= _tokens;
    }
    if(_remainingTokens > 0) {
      for (uint i = 1; i < tiers.length; ++i) {
        if(_remainingTokens > 0 && (tiers[i].tokens > tiers[i].tokensSold)) {
          if ((tiers[i].tokens - tiers[i].tokensSold) < _remainingTokens) {
            _tokens = (tiers[i].tokens - tiers[i].tokensSold);
          } else {
            _tokens = _remainingTokens;
          }
          tiers[i].tokensSold += _tokens;
          _remainingTokens -= _tokens;
        }
      }
    }
    
    assert(_remainingTokens == 0);  
    tokensSold += tokens;
    assert(charitySpaceToken.transfer(donatorAddress, tokens));
    
    bytes32 altCurrencyHash = keccak256(altCurrency);
    if(altCurrencyHash == btcHash) {
      ReceivedBTC(donatorAddress, altValue, altTx);
    } else if(altCurrencyHash == bchHash) {
      ReceivedBCH(donatorAddress, altValue, altTx);
    } else {
      ReceivedLTC(donatorAddress, altValue, altTx);
    }
  }
  
  function () public payable respectTimeFrame {
    receiveDonation();
  }
}