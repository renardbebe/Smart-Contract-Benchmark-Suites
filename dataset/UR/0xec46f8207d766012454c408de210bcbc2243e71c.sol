 

pragma solidity ^0.4.18;

contract Ownable {

  address public owner = msg.sender;
  address private newOwner = address(0);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));      
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender != address(0));
    require(msg.sender == newOwner);

    owner = newOwner;
    newOwner = address(0);
  }

}

 
library SafeMath {

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

}


 
contract ERC20 {

   
  uint256 public totalSupply;

   
  function balanceOf(address _owner) public constant returns (uint256 balance);

   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract ERC20Token is ERC20 {

  using SafeMath for uint256;

  mapping (address => uint256) balances;
  
  mapping (address => mapping (address => uint256)) allowed;

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
  
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] +=_value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0);

    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    balances[_to] += _value;
    
    Transfer(_from, _to, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

}

contract NitroToken is ERC20Token, Ownable {
    
  string public constant name = "Nitro";
  string public constant symbol = "NOX";
  uint8 public constant decimals = 18;

  function NitroToken(uint256 _totalSupply) public {
    totalSupply = _totalSupply;
    balances[owner] = _totalSupply;
    Transfer(address(0), owner, _totalSupply);
  }
  
  function acceptOwnership() public {
    address oldOwner = owner;
    super.acceptOwnership();
    balances[owner] = balances[oldOwner];
    balances[oldOwner] = 0;
    Transfer(oldOwner, owner, balances[owner]);
  }

}

contract Declaration {
  
  enum TokenTypes { crowdsale, interactive, icandy, consultant, team, reserve }
  mapping(uint => uint256) public balances;
  
  uint256 public preSaleStart = 1511020800;
  uint256 public preSaleEnd = 1511452800;
    
  uint256 public saleStart = 1512057600;
  uint256 public saleStartFirstDayEnd = saleStart + 1 days;
  uint256 public saleStartSecondDayEnd = saleStart + 3 days;
  uint256 public saleEnd = 1514304000;
  
  uint256 public teamFrozenTokens = 4800000 * 1 ether;
  uint256 public teamUnfreezeDate = saleEnd + 182 days;

  uint256 public presaleMinValue = 5 ether;
 
  uint256 public preSaleRate = 1040;
  uint256 public saleRate = 800;
  uint256 public saleRateFirstDay = 1000;
  uint256 public saleRateSecondDay = 920;

  NitroToken public token;

  function Declaration() public {
    balances[uint8(TokenTypes.crowdsale)] = 60000000 * 1 ether;
    balances[uint8(TokenTypes.interactive)] = 6000000 * 1 ether;
    balances[uint8(TokenTypes.icandy)] = 3000000 * 1 ether;
    balances[uint8(TokenTypes.consultant)] = 1200000 * 1 ether;
    balances[uint8(TokenTypes.team)] = 7200000 * 1 ether;
    balances[uint8(TokenTypes.reserve)] = 42600000 * 1 ether;
    token = new NitroToken(120000000 * 1 ether);
  }
  
  modifier withinPeriod(){
    require(isPresale() || isSale());
    _;
  }
  
  function isPresale() public constant returns (bool){
    return now>=preSaleStart && now<=preSaleEnd;
  }

  function isSale()  public constant returns (bool){
    return now >= saleStart && now <= saleEnd;
  }
  
  function rate() public constant returns (uint256) {
    if (isPresale()) {
      return preSaleRate;
    } else if (now>=saleStart && now<=(saleStartFirstDayEnd)){
      return saleRateFirstDay;
    } else if (now>(saleStartFirstDayEnd) && now<=(saleStartSecondDayEnd)){
      return saleRateSecondDay;
    }
    return saleRate;
  }
  
}

contract Crowdsale is Declaration, Ownable{
    
    using SafeMath for uint256;

    address public wallet;
    
    uint256 public weiLimit = 6 ether;
    uint256 public satLimit = 30000000;

    mapping(address => bool) users;
    mapping(address => uint256) weiOwed;
    mapping(address => uint256) satOwed;
    mapping(address => uint256) weiTokensOwed;
    mapping(address => uint256) satTokensOwed;
    
    uint256 public weiRaised;
    uint256 public satRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    function Crowdsale(address _wallet) Declaration public {
        wallet = _wallet;    
    }
    
    function () public payable {
        buy();
    }

    function weiFreeze(address _addr, uint256 _value) internal {
        uint256 amount = _value * rate();
        balances[0] = balances[0].sub(amount);
        weiOwed[_addr] += _value;
        weiTokensOwed[_addr] += amount;
    }

    function weiTransfer(address _addr, uint256 _value) internal {
        uint256 amount = _value * rate();
        balances[0] = balances[0].sub(amount);
        token.transfer(_addr, amount);
        weiRaised += _value;
        TokenPurchase(_addr, _addr, _value, amount);
    }

    function buy() withinPeriod public payable returns (bool){
        if (isPresale()) {
          require(msg.value >= presaleMinValue);
        }else{
          require(msg.value > 0);
        }
        if (weiOwed[msg.sender]>0) {
          weiFreeze(msg.sender, msg.value);
        } else if (msg.value>weiLimit && !users[msg.sender]) {
          weiFreeze(msg.sender, msg.value.sub(weiLimit));
          weiTransfer(msg.sender, weiLimit);
        } else {
          weiTransfer(msg.sender, msg.value);
        }
        return true;
    }
    
    function _verify(address _addr) onlyOwner internal {
        users[_addr] = true;
        
        weiRaised += weiOwed[_addr];
        satRaised += satOwed[_addr];

        token.transfer(_addr, weiTokensOwed[_addr] + satTokensOwed[_addr]);
        
        TokenPurchase(_addr, _addr, 0, weiTokensOwed[_addr] + satTokensOwed[_addr]);

        weiOwed[_addr]=0;
        satOwed[_addr]=0;
        weiTokensOwed[_addr]=0;
        satTokensOwed[_addr]=0;
    }

    function verify(address _addr) public returns(bool){
        _verify(_addr);
        return true;
    }
    
    function isVerified(address _addr) public constant returns(bool){
      return users[_addr];
    }
    
    function getWeiTokensOwed(address _addr) public constant returns (uint256){
        return weiTokensOwed[_addr];
    }

    function getSatTokensOwed(address _addr) public constant returns (uint256){
        return satTokensOwed[_addr];
    }

    function owedTokens(address _addr) public constant returns (uint256){
        return weiTokensOwed[_addr] + satTokensOwed[_addr];
    }
    
    function getSatOwed(address _addr) public constant returns (uint256){
        return satOwed[_addr];
    }
    
    function getWeiOwed(address _addr) public constant returns (uint256){
        return weiOwed[_addr];
    }
    
    function satFreeze(address _addr, uint256 _wei, uint _sat) private {
        uint256 amount = _wei * rate();
        balances[0] = balances[0].sub(amount);
        
        satOwed[_addr] += _sat;
        satTokensOwed[_addr] += amount;    
    }

    function satTransfer(address _addr, uint256 _wei, uint _sat) private {
        uint256 amount = _wei * rate();
        balances[0] = balances[0].sub(amount);
        
        token.transfer(_addr, amount);
        TokenPurchase(_addr, _addr, _wei, amount);
        satRaised += _sat;
    }

    function buyForBtc(
        address _addr,
        uint256 _sat,
        uint256 _satOwed,
        uint256 _wei,
        uint256 _weiOwed
    ) onlyOwner withinPeriod public {
        require(_addr != address(0));
        
        satFreeze(_addr, _weiOwed, _satOwed);
        satTransfer(_addr, _wei, _sat);
    }
    
    function refundWei(address _addr, uint256 _amount) onlyOwner public returns (bool){
        _addr.transfer(_amount);
        balances[0] += weiTokensOwed[_addr];
        weiTokensOwed[_addr] = 0;
        weiOwed[_addr] = 0;
        return true;
    }
  
    function refundedSat(address _addr) onlyOwner public returns (bool){
        balances[0] += satTokensOwed[_addr];
        satTokensOwed[_addr] = 0;
        satOwed[_addr] = 0;
        return true;
    }
    
    function sendOtherTokens(
        uint8 _index,
        address _addr,
        uint256 _amount
    ) onlyOwner public {
        require(_addr!=address(0));

        if (_index==uint8(TokenTypes.team) && now<teamUnfreezeDate) {
            uint256 limit = balances[uint8(TokenTypes.team)].sub(teamFrozenTokens);
            require(_amount<=limit);
        }
        
        token.transfer(_addr, _amount);
        balances[_index] = balances[_index].sub(_amount);
        TokenPurchase(owner, _addr, 0, _amount);
    }
    
    function rsrvToSale(uint256 _amount) onlyOwner public {
        balances[uint8(TokenTypes.reserve)] = balances[uint8(TokenTypes.reserve)].sub(_amount);
        balances[0] += _amount;
    }
    
    function forwardFunds(uint256 amount) onlyOwner public {
        wallet.transfer(amount);
    }
    
    function setTokenOwner(address _addr) onlyOwner public {
        token.transferOwnership(_addr);
    }

}