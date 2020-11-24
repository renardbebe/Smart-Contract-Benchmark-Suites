 

pragma solidity ^0.4.23;

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract Token {
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address who) public view returns (uint256);
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  Token public token;

   
  address public wallet;

   
  uint256 public rate = 7142;

   
  uint256 public ethRate = 27500;

   
  uint256 public weiRaised;

   
  uint256 public week = 604800;

   
  uint256 public icoStartTime;

   
  uint256 public privateIcoBonus = 50;
  uint256 public preIcoBonus = 30;
  uint256 public ico1Bonus = 15;
  uint256 public ico2Bonus = 10;
  uint256 public ico3Bonus = 5;
  uint256 public ico4Bonus = 0;

   
  uint256 public privateIcoMin = 1 ether;
  uint256 public preIcoMin = 1 ether;
  uint256 public ico1Min = 1 ether;
  uint256 public ico2Min = 1 ether;
  uint256 public ico3Min = 1 ether;
  uint256 public ico4Min = 1 ether; 

   
  uint256 public privateIcoMax = 350 ether;
  uint256 public preIcoMax = 10000 ether;
  uint256 public ico1Max = 10000 ether;
  uint256 public ico2Max = 10000 ether;
  uint256 public ico3Max = 10000 ether;
  uint256 public ico4Max = 10000 ether;


   
  uint256 public privateIcoCap = uint256(322532).mul(1e8);
  uint256 public preIcoCap = uint256(8094791).mul(1e8);
  uint256 public ico1Cap = uint256(28643106).mul(1e8);
  uint256 public ico2Cap = uint256(17123596).mul(1e8);
  uint256 public ico3Cap = uint256(9807150).mul(1e8);
  uint256 public ico4Cap = uint256(6008825).mul(1e8);

   
  uint256 public privateIcoSold;
  uint256 public preIcoSold;
  uint256 public ico1Sold;
  uint256 public ico2Sold;
  uint256 public ico3Sold;
  uint256 public ico4Sold;

   
  mapping(address => bool) public whitelist; 
   
  mapping(address => bool) public whitelisters;

  modifier isWhitelister() {
    require(whitelisters[msg.sender]);
    _;
  }

  modifier isWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  enum Stages {Pause, PrivateIco, PrivateIcoEnd, PreIco, PreIcoEnd, Ico1, Ico2, Ico3, Ico4, IcoEnd}

  Stages currentStage;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  event WhitelistUpdated(address indexed _account, uint8 _phase);

   
  constructor(address _newOwner, address _wallet, Token _token) public {
    require(_newOwner != address(0));
    require(_wallet != address(0));
    require(_token != address(0));

    owner = _newOwner;
    wallet = _wallet;
    token = _token;

    currentStage = Stages.Pause;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   

  function startPrivateIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.Pause);
    currentStage = Stages.PrivateIco;
    return true;
  }

   

  function endPrivateIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PrivateIco);
    currentStage = Stages.PrivateIcoEnd;
    return true;
  }

   

  function startPreIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PrivateIcoEnd);
    currentStage = Stages.PreIco;
    return true;
  }

   

  function endPreIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PreIco);
    currentStage = Stages.PreIcoEnd;
    return true;
  }

   

  function startIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PreIcoEnd);
    currentStage = Stages.Ico1;
    icoStartTime = now;
    return true;
  }


   

  function getStageName () public view returns (string) {
    if (currentStage == Stages.Pause) return 'Pause';
    if (currentStage == Stages.PrivateIco) return 'Private ICO';
    if (currentStage == Stages.PrivateIcoEnd) return 'Private ICO end';
    if (currentStage == Stages.PreIco) return 'Prte ICO';
    if (currentStage == Stages.PreIcoEnd) return 'Pre ICO end';
    if (currentStage == Stages.Ico1) return 'ICO 1-st week';
    if (currentStage == Stages.Ico2) return 'ICO 2-d week';
    if (currentStage == Stages.Ico3) return 'ICO 3-d week';
    if (currentStage == Stages.Ico4) return 'ICO 4-th week';
    return 'ICO is over';
  }

   
  function buyTokens(address _beneficiary) public payable isWhitelisted {

    uint256 weiAmount = msg.value;
    uint256 time;
    uint256 weeksPassed;

    require(currentStage != Stages.Pause);
    require(currentStage != Stages.PrivateIcoEnd);
    require(currentStage != Stages.PreIcoEnd);
    require(currentStage != Stages.IcoEnd);

    if (currentStage == Stages.Ico1 || currentStage == Stages.Ico2 || currentStage == Stages.Ico3 || currentStage == Stages.Ico4) {
      time = now.sub(icoStartTime);
      weeksPassed = time.div(week);

      if (currentStage == Stages.Ico1) {
        if (weeksPassed == 1) currentStage = Stages.Ico2;
        else if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico2) {
        if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico3) {
        if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico4) {
        if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      }
    }

    if (currentStage != Stages.IcoEnd) {
      _preValidatePurchase(_beneficiary, weiAmount);

       
      uint256 tokens = _getTokenAmount(weiAmount);

       
      weiRaised = weiRaised.add(weiAmount);

      if (currentStage == Stages.PrivateIco) privateIcoSold = privateIcoSold.add(tokens);
      if (currentStage == Stages.PreIco) preIcoSold = preIcoSold.add(tokens);
      if (currentStage == Stages.Ico1) ico1Sold = ico1Sold.add(tokens);
      if (currentStage == Stages.Ico2) ico2Sold = ico2Sold.add(tokens);
      if (currentStage == Stages.Ico3) ico3Sold = ico3Sold.add(tokens);
      if (currentStage == Stages.Ico4) ico4Sold = ico4Sold.add(tokens);

      _processPurchase(_beneficiary, tokens);
      emit TokenPurchase(
        msg.sender,
        _beneficiary,
        weiAmount,
        tokens
      );

      _forwardFunds();
    } else {
      msg.sender.transfer(msg.value);
    }
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);

    if (currentStage == Stages.PrivateIco) {
      require(_weiAmount >= privateIcoMin);
      require(_weiAmount <= privateIcoMax);
    } else if (currentStage == Stages.PreIco) {
      require(_weiAmount >= preIcoMin);
      require(_weiAmount <= preIcoMax);
    } else if (currentStage == Stages.Ico1) {
      require(_weiAmount >= ico1Min);
      require(_weiAmount <= ico1Max);
    } else if (currentStage == Stages.Ico2) {
      require(_weiAmount >= ico2Min);
      require(_weiAmount <= ico2Max);
    } else if (currentStage == Stages.Ico3) {
      require(_weiAmount >= ico3Min);
      require(_weiAmount <= ico3Max);
    } else if (currentStage == Stages.Ico4) {
      require(_weiAmount >= ico4Min);
      require(_weiAmount <= ico4Max);
    }
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(token.transfer(_beneficiary, _tokenAmount));
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    uint256 bonus;
    uint256 cap;

    if (currentStage == Stages.PrivateIco) {
      bonus = privateIcoBonus;
      cap = privateIcoCap.sub(privateIcoSold);
    } else if (currentStage == Stages.PreIco) {
      bonus = preIcoBonus;
      cap = preIcoCap.sub(preIcoSold);
    } else if (currentStage == Stages.Ico1) {
      bonus = ico1Bonus;
      cap = ico1Cap.sub(ico1Sold);
    } else if (currentStage == Stages.Ico2) {
      bonus = ico2Bonus;
      cap = ico2Cap.sub(ico2Sold);
    } else if (currentStage == Stages.Ico3) {
      bonus = ico3Bonus;
      cap = ico3Cap.sub(ico3Sold);
    } else if (currentStage == Stages.Ico4) {
      bonus = ico4Bonus;
      cap = ico4Cap.sub(ico4Sold);
    }
    uint256 tokenAmount = _weiAmount.mul(ethRate).div(rate).div(1e8);
    uint256 bonusTokens = tokenAmount.mul(bonus).div(100);
    tokenAmount = tokenAmount.add(bonusTokens);

    require(tokenAmount <= cap);
    return tokenAmount;
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function withdrawTokens() public onlyOwner returns (bool) {
    uint256 time;
    uint256 weeksPassed;

    if (currentStage == Stages.Ico1 || currentStage == Stages.Ico2 || currentStage == Stages.Ico3 || currentStage == Stages.Ico4) {
      time = now.sub(icoStartTime);
      weeksPassed = time.div(week);

      if (weeksPassed > 3) currentStage = Stages.IcoEnd;
    }
    require(currentStage == Stages.IcoEnd);

    uint256 balance = token.balanceOf(address(this));
    if (balance > 0) {
      require(token.transfer(owner, balance));
    }
  }

   
  function SendTokens(address _to, uint256 _amount) public onlyOwner returns (bool) {
    uint256 time;
    uint256 weeksPassed;

    require(_to != address(0));
    require(currentStage != Stages.Pause);
    require(currentStage != Stages.PrivateIcoEnd);
    require(currentStage != Stages.PreIcoEnd);
    require(currentStage != Stages.IcoEnd);

    if (currentStage == Stages.Ico1 || currentStage == Stages.Ico2 || currentStage == Stages.Ico3 || currentStage == Stages.Ico4) {
      time = now.sub(icoStartTime);
      weeksPassed = time.div(week);

      if (currentStage == Stages.Ico1) {
        if (weeksPassed == 1) currentStage = Stages.Ico2;
        else if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico2) {
        if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico3) {
        if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico4) {
        if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      }
    }

    if (currentStage != Stages.IcoEnd) {
      uint256 cap;
      if (currentStage == Stages.PrivateIco) {
        cap = privateIcoCap.sub(privateIcoSold);
      } else if (currentStage == Stages.PreIco) {
        cap = preIcoCap.sub(preIcoSold);
      } else if (currentStage == Stages.Ico1) {
        cap = ico1Cap.sub(ico1Sold);
      } else if (currentStage == Stages.Ico2) {
        cap = ico2Cap.sub(ico2Sold);
      } else if (currentStage == Stages.Ico3) {
        cap = ico3Cap.sub(ico3Sold);
      } else if (currentStage == Stages.Ico4) {
        cap = ico4Cap.sub(ico4Sold);
      }

      require(_amount <= cap);

      if (currentStage == Stages.PrivateIco) privateIcoSold = privateIcoSold.add(_amount);
      if (currentStage == Stages.PreIco) preIcoSold = preIcoSold.add(_amount);
      if (currentStage == Stages.Ico1) ico1Sold = ico1Sold.add(_amount);
      if (currentStage == Stages.Ico2) ico2Sold = ico2Sold.add(_amount);
      if (currentStage == Stages.Ico3) ico3Sold = ico3Sold.add(_amount);
      if (currentStage == Stages.Ico4) ico4Sold = ico4Sold.add(_amount);
    } else {
      return false;
    }
    require(token.transfer(_to, _amount));
  }

     
     
     
    function updateWhitelist (address _account, uint8 _phase) external isWhitelister returns (bool) {
      require(_account != address(0));
      require(_phase <= 1);
      if (_phase == 1) whitelist[_account] = true;
      else whitelist[_account] = false;
      emit WhitelistUpdated(_account, _phase);
      return true;
    }

     
     
    function addWhitelister (address _address) public onlyOwner returns (bool) {
      whitelisters[_address] = true;
      return true;
    }

     
     
    function removeWhitelister (address _address) public onlyOwner returns (bool) {
      whitelisters[_address] = false;
      return true;
    }

    function setUsdRate (uint256 _usdCents) public onlyOwner returns (bool) {
      ethRate = _usdCents;
      return true;
    }
}