 

pragma solidity ^0.4.15;

contract Addresses {

     
    address public bounty;
    
     
    address public successFee;

     
    address public addr1;

     
    address public addr2;

     
    address public addr3;

     
    address public addr4;


  function Addresses() {

       
      bounty = 0x0064952457905eBFB9c0292200A74B1d7414F081;
                  
    
      
       
      successFee = 0xdA39e0Ce2adf93129D04F53176c7Bfaaae8B051a;
                  
     

     
      addr1 = 0x300b848558DC06E32658fFB8D59C859D0812CA6C;

       
      addr2 = 0x4388AD192b0DaaDBBaa86Be0AE7499b8D44C5f75;

       
      addr3 = 0x40C9E2D0807289b4c24B0e2c34277BDd7FaCfd87;

       
      addr4 = 0x4E3B219684b9570D0d81Cc13E5c0aAcafe2323B1;
      

      
  }

}
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  function approve(address _owner, address _spender, uint256 _value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    
  address public owner;
 
  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}

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

  function mod(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a % b;
    return c;
  }
  
}

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;

   
  uint256 ico_finish = 1508284740;

  modifier isFreeze() {
    if(now < ico_finish) {
      revert();
    }
    _;
  }

  function transfer(address _to, uint256 _value) isFreeze returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;

   
  uint256 ico_finish = 1508025540;

  modifier isFreeze() {
    if(now < ico_finish) {
      revert();
    }
    _;
  }
 
  function transferFrom(address _from, address _to, uint256 _value) isFreeze returns (bool) {
    var _allowance = allowed[_from][msg.sender];
 
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) returns (bool) {
 
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function approve(address _owner, address _spender, uint256 _value) returns (bool) {
 
    allowed[_owner][_spender] = _value;
    Approval(_owner, _spender, _value);
    return true;
  }
 
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}

contract MintableToken is StandardToken, Ownable {

  using SafeMath for uint256;

  event Mint(address indexed to, uint256 amount);

  event MintFinished();

  event ShowInfo(uint256 _info, string _message);

  function setTotalSupply(uint256 _amount) public onlyOwner returns(uint256) {
    totalSupply = _amount;
    return totalSupply;
  }

  function getTotalTokenCount() public constant returns(uint256) {
    return totalSupply;
  }
  
  function mint(address _address, uint256 _tokens) public {

    Mint(_address, _tokens);

    balances[_address] = balances[_address].add(_tokens);
  }

  function burnTokens(address _address) public {
    balances[_address] = 0;
    totalSupply = 0;
  }

}

contract SingleTokenCoin is MintableToken {
    
    string public constant name = "Start mining";
    
    string public constant symbol = "STM";
    
    uint32 public constant decimals = 2;
    
}

 
 
 
 
 
 

 
 
 
 
 
 

contract WrapperOraclize {
    function update(string datasource, string arg) payable;
    function update(uint timestamp, string datasource, string arg) payable;
    function getWrapperBalance() constant returns(uint256);
    function getWrapperData() constant returns(bytes32);
    function getPrice(string datasource) constant returns(uint256);
    function() external payable;
}

contract Crowdsale is Ownable {

  string public ETHUSD;

  event ShowPrice(string price);

    using SafeMath for uint256;

    SingleTokenCoin public token = new SingleTokenCoin();

    Addresses private addresses = new Addresses();

    WrapperOraclize private wrapper = WrapperOraclize(0xfC484c66daE464CC6055d7a4782Ec8761dc9842F);

    uint256 private ico_start;
    uint256 private ico_finish;

    uint256 private rate;

    uint256 private decimals;

    uint256 private tax;

     
    uint256 private firstBonusPhase;
    uint256 private firstExtraBonus;

    uint256 private secondBonusPhase;
    uint256 private secondExtraBonus;

    uint256 private thirdBonusPhase;
    uint256 private thirdExtraBonus;

    uint256 private fourBonusPhase;
    uint256 private fourExtraBonus;

     
    bool private firstWithdrowPhase;
    bool private secondWithdrowPhase;
    bool private thirdWithdrowPhase;
    bool private fourWithdrowPhase;

    uint256 private firstWithdrowAmount;
    uint256 private secondWithdrowAmount;
    uint256 private thirdWithdrowAmount;
    uint256 private fourWithdrowAmount;

    uint256 private totalETH;

    uint256 private totalAmount;

    bool private initialize = false;
    
    bool public mintingFinished = false;

     
    mapping(address => uint256) private ico_buyers_eth;

     
    mapping(address => uint256) private ico_buyers_token;

    address[] private investors;

    mapping(address => bytes32) private privilegedWallets;
    mapping(address => uint256) private manualAddresses;

    address[] private manualAddressesCount;

    address[] private privilegedWalletsCount;

    bytes32 private g = "granted";

    bytes32 private r = "revorked";

    uint256 private soldTokens;
    uint256 private mincup;

    uint256 private minPrice;

    event ShowInfo(uint256 _info);
    event ShowInfoStr(string _info);
    event ShowInfoBool(bool _info);

    function Crowdsale() {

       
      rate = 3546099290780141;  

      decimals = 35460992907801;  

      tax = 36000000000000000;  

       

       
      ico_start = 1505746800;

       
      ico_finish = 1508284740;

      totalAmount = 1020000000;

       
      mincup = 50000000;
      
      mintingFinished = false;

      setTotalSupply();

       
      firstBonusPhase = ico_start.add(24 hours);
      firstExtraBonus = 25;

      secondBonusPhase = ico_start.add(168 hours);
      secondExtraBonus = 15;

      thirdBonusPhase = ico_start.add(336 hours);
      thirdExtraBonus = 10;

      fourBonusPhase = ico_start.add(480 hours);
      fourExtraBonus = 5;

       
      firstWithdrowPhase = false;
      secondWithdrowPhase = false;
      thirdWithdrowPhase = false;
      fourWithdrowPhase = false;

      firstWithdrowAmount = 50000000;
      secondWithdrowAmount = 200000000;
      thirdWithdrowAmount = 500000000;
      fourWithdrowAmount = 1020000000;

      totalETH = 0;

      soldTokens = 0;

      privilegedWalletsCount.push(msg.sender);
      privilegedWallets[msg.sender] = g;

    }

      modifier canMint() {
        require(!mintingFinished);
        _;
      }

    function() external payable {
      mint();
    }

  function bytesToUInt(bytes32 v) constant returns (uint ret) {
        if (v == 0x0) {
            revert();
        }

        uint digit;

        for (uint i = 0; i < 32; i++) {
            digit = uint((uint(v) / (2 ** (8 * (31 - i)))) & 0xff);
            if (digit == 0 || digit == 46) {
                break;
            }
            else if (digit < 48 || digit > 57) {
                revert();
            }
            ret *= 10;
            ret += (digit - 48);
        }
        return ret;
    }

  function calculateRate() public payable returns(uint256) {
    bytes32 result = getWrapperData();
    uint256 usd = bytesToUInt(result);

    uint256 price = 1 ether / usd;  

    return price;
  }

    function calculateWithdrow() private {
      if (!firstWithdrowPhase && soldTokens >= firstWithdrowAmount && soldTokens < secondWithdrowAmount) {
        sendToOwners(this.balance);
      } else {
        if (!secondWithdrowPhase && soldTokens >= secondWithdrowAmount && soldTokens < thirdWithdrowAmount) {
          sendToOwners(this.balance);
        } else {
          if (!thirdWithdrowPhase && soldTokens >= thirdWithdrowAmount && soldTokens < fourWithdrowAmount) {
            sendToOwners(this.balance);
          } else {
            if (!fourWithdrowPhase && soldTokens >= fourWithdrowAmount) {
              sendToOwners(this.balance);
            }
          }
        }
      }
    }

    modifier isInitialize() {
      require(!initialize);
      _;
    }

    function setTotalSupply() private isInitialize onlyOwner returns(uint256) {
      initialize = true;
      return token.setTotalSupply(totalAmount);
    }

    function sendToAddress(address _address, uint256 _tokens) canMint public {

      if (grantedWallets(msg.sender) == false) {
        revert();      
      }

      ShowInfo(_tokens);

      uint256 currentTokens = _tokens;

      uint256 timeBonus = calculateBonusForHours(currentTokens);

      uint256 allTokens = currentTokens.add(timeBonus);   

      token.approve(_address, this, allTokens);      

      saveInfoAboutInvestors(_address, 0, allTokens, true);         

      token.mint(_address, allTokens);

      soldTokens = soldTokens + allTokens;
      calculateWithdrow();
    }

    modifier isRefund() {
      if (msg.value < tax) {
        refund(msg.value);
        revert();
      }
      _;
    }

    function grantedWallets(address _address) private returns(bool) {
      if (privilegedWallets[_address] == g) {
        return true;
      }
      return false;
    }

    modifier isICOFinished() {
      if (now > ico_finish) {
        finishMinting();
        refund(msg.value);
        revert();
      }
      _;
    }

    function getTokens() public constant returns(uint256) {
      token.getTotalTokenCount();
    }

    function setPrivelegedWallet(address _address) public onlyOwner returns(bool) {
      if (privilegedWalletsCount.length == 2) {
        revert();
      }

      if (privilegedWallets[_address] != g && privilegedWallets[_address] != r) {
        privilegedWalletsCount.push(_address);
      }

      privilegedWallets[_address] = g;

      return true;
    }

    function setTransferOwnership(address _address) public onlyOwner {

      removePrivelegedWallet(msg.sender);
      setPrivelegedWallet(_address);

      transferOwnership(_address);
    }

    function removePrivelegedWallet(address _address) public onlyOwner {
      if (privilegedWallets[_address] == g) {
        privilegedWallets[_address] = r;
        delete privilegedWalletsCount[0];
      } else {
        revert();
      }
    }

     
    function setICODate(uint256 _time) public onlyOwner {
      ico_start = _time;
      ShowInfo(_time);
    }

    function getICODate() public constant returns(uint256) {
      return ico_start;
    }

    function mint() public isRefund canMint isICOFinished payable {

      rate = calculateRate();

      decimals = rate / 100;  

      uint256 remainder = msg.value.mod(decimals);

      uint256 eth = msg.value.sub(remainder);

      if (remainder != 0) {
        refund(remainder);
      }

      totalETH = totalETH + eth;

      uint currentRate = rate / 100;  

      uint256 tokens = eth.div(currentRate);
      uint256 timeBonus = calculateBonusForHours(tokens);

      uint256 allTokens = tokens.add(timeBonus) + 100;  

      saveInfoAboutInvestors(msg.sender, eth, allTokens, false);

      token.mint(msg.sender, allTokens);

      soldTokens = soldTokens + allTokens;
      calculateWithdrow();
    }

    function saveInfoAboutInvestors(address _address, uint256 _amount, uint256 _tokens, bool _isManual) private {

      if (!_isManual) {
        if (ico_buyers_token[_address] == 0) {
          investors.push(_address);
        }

         
        ico_buyers_eth[_address] = ico_buyers_eth[_address].add(_amount);

         
        ico_buyers_token[_address] = ico_buyers_token[_address].add(_tokens);
      
      } else {
        if(manualAddresses[_address] == 0) {
          manualAddressesCount.push(_address);
        }

        manualAddresses[_address] = manualAddresses[_address].add(_tokens);
      }
    }

    function getManualByAddress(address _address) public constant returns(uint256) {
      return manualAddresses[_address];
    }

    function getManualInvestorsCount() public constant returns(uint256) {
      return manualAddressesCount.length;
    }

    function getManualAddress(uint _index) public constant returns(address) {
      return manualAddressesCount[_index];
    }

    function finishMinting() public onlyOwner {
      if(mintingFinished) {
        revert();
      }

      ShowInfoBool(mintingFinished);
      mintingFinished = true;
      ShowInfoBool(mintingFinished);
      
      if (soldTokens < mincup) {
        if(investors.length != 0) {
          for (uint256 i=0; i < investors.length; i++) {
            address addr = investors[i];          
            token.burnTokens(addr);
          }
        }
        
        if(manualAddressesCount.length != 0) {
          for (uint256 j=0; j < manualAddressesCount.length; j++) {
            address manualAddr = manualAddressesCount[j];
            token.burnTokens(manualAddr);
          }
        }
      }
    }

    function getFinishStatus() public constant returns(bool) {
      return mintingFinished;
    }

    function manualRefund() public {
      if (mintingFinished) {
        if(ico_buyers_eth[msg.sender] != 0) {
          uint256 amount = ico_buyers_eth[msg.sender];
          msg.sender.transfer(amount);
          ico_buyers_eth[msg.sender] = 0;
        } else {
          revert();
        }
      } else {
        revert();
      }
      
    }

    function refund(uint256 _amount) private {
      msg.sender.transfer(_amount);
    }

    function refund(address _address, uint256 _amount) private {
      _address.transfer(_amount);
    }

    function getTokensManual(address _address) public constant returns(uint256) {
      return manualAddresses[_address];
    }

    function calculateBonusForHours(uint256 _tokens) private returns(uint256) {

       
      if (now >= ico_start && now <= firstBonusPhase ) {
        return _tokens.mul(firstExtraBonus).div(100);
      }

       
      if (now > firstBonusPhase && now <= secondBonusPhase ) {
        return _tokens.mul(secondExtraBonus).div(100);
      }

       
      if (now > secondBonusPhase && now <= thirdBonusPhase ) {
        return _tokens.mul(thirdExtraBonus).div(100);
      }

       
      if (now > thirdBonusPhase && now <= fourBonusPhase ) {
        return _tokens.mul(fourExtraBonus).div(100);
      }

      return 0;
    }

    function sendToOwners(uint256 _amount) private {
      uint256 twoPercent = _amount.mul(2).div(100);
      uint256 fivePercent = _amount.mul(5).div(100);
      uint256 nineThreePercent = _amount.mul(93).div(100);

 

       
      addresses.addr1().transfer(nineThreePercent);
      addresses.addr2().transfer(nineThreePercent);
      addresses.addr3().transfer(nineThreePercent);
      addresses.addr4().transfer(nineThreePercent);

      if (!firstWithdrowPhase) {
        addresses.addr1().transfer(nineThreePercent);
        firstWithdrowPhase = true;
      } else {
        if (!secondWithdrowPhase) {
          addresses.addr2().transfer(nineThreePercent);   
          secondWithdrowPhase = true;       
        } else {
          if (!thirdWithdrowPhase) {
            addresses.addr3().transfer(nineThreePercent);
            thirdWithdrowPhase = true;                
          } else {
            if (!fourWithdrowPhase) {
              addresses.addr4().transfer(nineThreePercent);
              fourWithdrowPhase = true;                      
            }
          }
        }
      }


       
      addresses.successFee().transfer(fivePercent);
      
       
      addresses.bounty().transfer(twoPercent);
      
    }

    function getBalanceContract() public constant returns(uint256) {
      return this.balance;
    }

    function getSoldToken() public constant returns(uint256) {
      return soldTokens;
    }

    function getInvestorsTokens(address _address) public constant returns(uint256) {
      return ico_buyers_token[_address];
    }

    function getInvestorsETH(address _address) public constant returns(uint256) {
      return ico_buyers_eth[_address];
    }

    function getInvestors() public constant returns(uint256) {
      return investors.length;
    }

    function getInvestorByValue(address _address) public constant returns(uint256) {
      return ico_buyers_eth[_address];
    }

     
    function transfer(address _from, address _to, uint256 _amount) public returns(bool) {
      return token.transferFrom(_from, _to, _amount);
    }

    function getInvestorByIndex(uint256 _index) public constant returns(address) {
      return investors[_index];
    }

    function getLeftToken() public constant returns(uint256) {
      if(token.totalSupply() != 0) {
        return token.totalSupply() - soldTokens;
      } else {
        return soldTokens;
      }
    }

    function getTotalToken() public constant returns(uint256) {
      return token.totalSupply();
    }

    function getTotalETH() public constant returns(uint256) {
      return totalETH;
    }

    function getCurrentPrice() public constant returns(uint256) {
      
      uint256 secondDiscount = calculateBonusForHours(rate);

      uint256 investorDiscount = rate.sub(secondDiscount);

      return investorDiscount * 10;  
    }

    function getContractAddress() public constant returns(address) {
      return this;
    }

    function getOwner() public constant returns(address) {
      return owner;
    }

    function sendOracleData() public payable {
        if (msg.value != 0) {
            wrapper.transfer(msg.value);
        }
      
      wrapper.update("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
    }

    function getQueryPrice(string datasource) constant returns(uint256) {
      return wrapper.getPrice(datasource);
    }

    function checkWrapperBalance() public constant returns(uint256) {
      return wrapper.getWrapperBalance();
    }

    function getWrapperData() constant returns(bytes32) {
      return wrapper.getWrapperData();
    }
}