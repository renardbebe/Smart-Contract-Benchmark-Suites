 

pragma solidity ^0.4.18;

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;
    address public publisher;


    function MultiOwners() {
        owners[msg.sender] = true;
        publisher = msg.sender;
    }

    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }

    function isOwner() constant returns (bool) {
        return owners[msg.sender] ? true : false;
    }

    function checkOwner(address maybe_owner) constant returns (bool) {
        return owners[maybe_owner] ? true : false;
    }


    function grant(address _owner) onlyOwner {
        owners[_owner] = true;
        AccessGrant(_owner);
    }

    function revoke(address _owner) onlyOwner {
        require(_owner != publisher);
        require(msg.sender != _owner);

        owners[_owner] = false;
        AccessRevoke(_owner);
    }
}

contract Haltable is MultiOwners {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

contract StagePercentageStep is MultiOwners {
    using SafeMath for uint256;

    string public name;
    uint256 public tokenPriceInETH;
    uint256 public mintCapInETH;
    uint256 public mintCapInUSD;
    uint256 public mintCapInTokens;
    uint256 public hardCapInTokens;
    uint256 public totalWei;
    uint256 public bonusAvailable;
    uint256 public bonusTotalSupply;
    

    struct Round {
        uint256 windowInTokens;
        uint256 windowInETH;
        uint256 accInETH;
        uint256 accInTokens;
        uint256 nextAccInETH;
        uint256 nextAccInTokens;
        uint256 discount;
        uint256 priceInETH;
        uint256 weightPercentage;
    }
    
    Round[] public rounds;
    
    function StagePercentageStep(string _name) {
        name = _name;
    }
    
    function totalEther() public constant returns(uint256) {
        return totalWei.div(1e18);
    }

    function registerRound(uint256 priceDiscount, uint256 weightPercentage) internal {
        uint256 windowInETH;
        uint256 windowInTokens;
        uint256 accInETH = 0;
        uint256 accInTokens = 0;
        uint256 priceInETH;
        
        
        priceInETH = tokenPriceInETH.mul(100-priceDiscount).div(100);
        windowInETH = mintCapInETH.mul(weightPercentage).div(100);
        windowInTokens = windowInETH.mul(1e18).div(priceInETH);

        if(rounds.length > 0) {
            accInTokens = accInTokens.add(rounds[rounds.length-1].nextAccInTokens);
            accInETH = accInETH.add(rounds[rounds.length-1].nextAccInETH);
        }

        rounds.push(Round({
            windowInETH: windowInETH,
            windowInTokens: windowInTokens,
            accInETH: accInETH,
            accInTokens: accInTokens,
            nextAccInETH: accInETH + windowInETH,
            nextAccInTokens: accInTokens + windowInTokens,
            weightPercentage: weightPercentage,
            discount: priceDiscount,
            priceInETH: priceInETH
        }));
        mintCapInTokens = mintCapInTokens.add(windowInTokens);
        hardCapInTokens = mintCapInTokens.mul(120).div(100);
    }
    
     
    function calcAmount(
        uint256 _amount,
        uint256 _totalEthers
    ) public constant returns (uint256 estimate, uint256 amount) {
        Round memory round;
        uint256 totalEthers = _totalEthers;
        amount = _amount;
        
        for(uint256 i; i<rounds.length; i++) {
            round = rounds[i];

            if(!(totalEthers >= round.accInETH && totalEthers < round.nextAccInETH)) {
                continue;
            }
            
            if(totalEthers.add(amount) < round.nextAccInETH) {
                return (estimate + amount.mul(1e18).div(round.priceInETH), 0);
            }

            amount = amount.sub(round.nextAccInETH.sub(totalEthers));
            estimate = estimate + (
                round.nextAccInETH.sub(totalEthers).mul(1e18).div(round.priceInETH)
            );
            totalEthers = round.nextAccInETH;
        }
        return (estimate, amount);
    }    
}

contract SessiaCrowdsale is StagePercentageStep, Haltable {
    using SafeMath for uint256;

     
    uint256 public ethPriceInUSD = 680e2;  
    uint256 public minimalUSD = 680e2;  
    uint256 public minimalWei = minimalUSD.mul(1e18).div(ethPriceInUSD);  

     
    SessiaToken public token;

     
    address public wallet;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public bonusMintingAgent;


    event ETokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event ETransferOddEther(address indexed beneficiary, uint256 value);
    event ESetBonusMintingAgent(address agent);
    event ESetStartTime(uint256 new_startTime);
    event ESetEndTime(uint256 new_endTime);
    event EManualMinting(address indexed beneficiary, uint256 value, uint256 amount);
    event EBonusMinting(address indexed beneficiary, uint256 value);


    modifier validPurchase() {
        bool nonZeroPurchase = msg.value != 0;
        
        require(withinPeriod() && nonZeroPurchase);

        _;        
    }

    function SessiaCrowdsale(
        uint256 _startTime,   
        uint256 _endTime,   
        address _wallet,   
        address _bonusMintingAgent
    )
        public
        StagePercentageStep("Pre-ITO") 
     {
        require(_startTime >= 0);
        require(_endTime > _startTime);

        token = new SessiaToken();
        token.grant(_bonusMintingAgent);
        token.grant(_wallet);

        bonusMintingAgent = _bonusMintingAgent;
        wallet = _wallet;

        startTime = _startTime;
        endTime = _endTime;

        tokenPriceInETH = 1e15;  
        mintCapInUSD = 3000000e2;  
        mintCapInETH = mintCapInUSD.mul(1e18).div(ethPriceInUSD);
    
        registerRound({priceDiscount: 30, weightPercentage: 10});
        registerRound({priceDiscount: 20, weightPercentage: 20});
        registerRound({priceDiscount: 10, weightPercentage: 30});
        registerRound({priceDiscount: 0, weightPercentage: 40});
    
        require(bonusMintingAgent != 0);
        require(wallet != 0x0);
    }

    function withinPeriod() constant public returns (bool) {
        return (now >= startTime && now <= endTime);
    }

     
    function running() constant public returns (bool) {
        return withinPeriod() && !token.mintingFinished();
    }

     
    function setBonusMintingAgent(address agent) public onlyOwner {
        require(agent != address(this));
        token.revoke(bonusMintingAgent);
        token.grant(agent);
        bonusMintingAgent = agent;
        ESetBonusMintingAgent(agent);
    }

     
    function stageName() constant public returns (string) {
        bool beforePeriod = (now < startTime);

        if(beforePeriod) {
            return "Not started";
        }

        if(withinPeriod()) {
            return name;
        } 

        return "Finished";
    }

     
    function() public payable {
        return buyTokens(msg.sender);
    }

     
    function setStartTime(uint256 _at) public onlyOwner {
        require(block.timestamp < _at);  
        require(_at < endTime);

        startTime = _at;
        ESetStartTime(_at);
    }

     
    function setEndTime(uint256 _at) public onlyOwner {
        require(startTime < _at);   

        endTime = _at;
        ESetEndTime(_at);
    }

     
    function bonusMinting(address to, uint256 amount) stopInEmergency public {
        require(msg.sender == bonusMintingAgent || isOwner());
        require(amount <= bonusAvailable);
        require(token.totalSupply() + amount <= hardCapInTokens);

        bonusTotalSupply = bonusTotalSupply.add(amount);
        bonusAvailable = bonusAvailable.sub(amount);
        EBonusMinting(to, amount);
        token.mint(to, amount);
    }

     
    function buyTokens(address contributor) payable stopInEmergency validPurchase public {
        require(contributor != 0x0);
        require(msg.value >= minimalWei);

        uint256 amount;
        uint256 odd_ethers;
        uint256 ethers;
        
        (amount, odd_ethers) = calcAmount(msg.value, totalWei);  
        require(amount + token.totalSupply() + bonusAvailable <= hardCapInTokens);

        ethers = (msg.value.sub(odd_ethers));

        token.mint(contributor, amount);  
        ETokenPurchase(contributor, ethers, amount);
        totalWei = totalWei.add(ethers);

        if(odd_ethers > 0) {
            require(odd_ethers < msg.value);
            ETransferOddEther(contributor, odd_ethers);
            contributor.transfer(odd_ethers);
        }
        bonusAvailable = bonusAvailable.add(amount.mul(20).div(100));

        wallet.transfer(ethers);
    }


     
    function manualMinting(address contributor, uint256 value) onlyOwner stopInEmergency public {
        require(withinPeriod());
        require(contributor != 0x0);
        require(value >= minimalWei);

        uint256 amount;
        uint256 odd_ethers;
        uint256 ethers;
        
        (amount, odd_ethers) = calcAmount(value, totalWei);
        require(amount + token.totalSupply() + bonusAvailable <= hardCapInTokens);

        ethers = value.sub(odd_ethers);

        token.mint(contributor, amount);  
        EManualMinting(contributor, amount, ethers);
        totalWei = totalWei.add(ethers);
        bonusAvailable = bonusAvailable.add(amount.mul(20).div(100));
    }

    function finishCrowdsale() onlyOwner public {
        require(block.timestamp > endTime || (mintCapInETH - totalWei) <= 1e18);
        require(!token.mintingFinished());

        if(bonusAvailable > 0) {
            bonusMinting(wallet, bonusAvailable);
        }
        token.finishMinting();
    }

}

contract SessiaToken is MintableToken, MultiOwners {

    string public constant name = "Sessia Kickers";
    string public constant symbol = "PRE-KICK";
    uint8 public constant decimals = 18;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(!isOwner()) {
            revert();
        }
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if(!isOwner()) {
            revert();
        }
        return super.transfer(to, value);
    }

    function grant(address _owner) public {
        require(publisher == msg.sender);
        return super.grant(_owner);
    }

    function revoke(address _owner) public {
        require(publisher == msg.sender);
        return super.revoke(_owner);
    }

    function mint(address _to, uint256 _amount) public returns (bool) {
        require(publisher == msg.sender);
        return super.mint(_to, _amount);
    }

}