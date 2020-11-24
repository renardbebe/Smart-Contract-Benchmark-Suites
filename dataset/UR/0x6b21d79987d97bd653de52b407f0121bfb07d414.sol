 

pragma solidity ^0.4.15;

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

contract McFlyToken is MintableToken {

    string public constant name = 'McFly';
    string public constant symbol = 'MFL';
    uint8 public constant decimals = 18;

    mapping(address=>bool) whitelist;

    event Burn(address indexed from, uint256 value);
    event AllowTransfer(address from);

    modifier canTransfer() {
        require(mintingFinished || whitelist[msg.sender]);
        _;        
    }

    function allowTransfer(address from) onlyOwner {
        AllowTransfer(from);
        whitelist[from] = true;
    }

    function transferFrom(address from, address to, uint256 value) canTransfer returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) canTransfer returns (bool) {
        return super.transfer(to, value);
    }

    function burn(address from) onlyOwner returns (bool) {
        Transfer(from, 0x0, balances[from]);
        Burn(from, balances[from]);

        balances[0x0] += balances[from];
        balances[from] = 0;
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

contract McFlyCrowdsale is MultiOwners, Haltable {
    using SafeMath for uint256;

     
    uint256 public minimalWeiTLP1 = 1e17;  
    uint256 public priceTLP1 = 1e14;  

     
    uint256 public minimalWeiTLP2 = 2e17;  
    uint256 public priceTLP2 = 2e14;  

     
    uint256 public totalETH;

     
    McFlyToken public token;

     
    address public wallet;

     
    uint256 public startTimeTLP1;
    uint256 public endTimeTLP1;
    uint256 daysTLP1 = 12 days;

     
    uint256 public startTimeTLP2;
    uint256 public endTimeTLP2;
    uint256 daysTLP2 = 24 days;

     
    uint256 fundPercents = 15;
    uint256 teamPercents = 10;
    uint256 reservedPercents = 10;
    uint256 bountyOnlinePercents = 2;
    uint256 bountyOfflinePercents = 3;
    uint256 advisoryPercents = 5;
    
     
     
    uint256 public hardCapInTokens = 1800e24;  

     
    uint256 public mintCapInTokens = hardCapInTokens.mul(70).div(100);  

     
    uint256 public fundTokens = hardCapInTokens.mul(fundPercents).div(100);  
    uint256 public fundTotalSupply;
    address public fundMintingAgent;

     
     
     
    uint256 public wavesTokens = 100e24;  
    address public wavesAgent;

     
    uint256 teamVestingPeriodInSeconds = 31 days;
    uint256 teamVestingPeriodsCount = 12;
    uint256 _teamTokens;
    uint256 public teamTotalSupply;
    address public teamWallet;

     
     
    uint256 _bountyOnlineTokens;
    address public bountyOnlineWallet;

     
    uint256 _bountyOfflineTokens;
    address public bountyOfflineWallet;

     
    uint256 _advisoryTokens;
    address public advisoryWallet;

     
    uint256 _reservedTokens;
    address public reservedWallet;


    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TransferOddEther(address indexed beneficiary, uint256 value);
    event FundMinting(address indexed beneficiary, uint256 value);
    event TeamVesting(address indexed beneficiary, uint256 period, uint256 value);
    event SetFundMintingAgent(address new_agent);
    event SetStartTimeTLP1(uint256 new_startTimeTLP1);
    event SetStartTimeTLP2(uint256 new_startTimeTLP2);


    modifier validPurchase() {
        bool nonZeroPurchase = msg.value != 0;
        
        require(withinPeriod() && nonZeroPurchase);

        _;        
    }

    function McFlyCrowdsale(
        uint256 _startTimeTLP1,
        uint256 _startTimeTLP2,
        address _wallet,
        address _wavesAgent,
        address _fundMintingAgent,
        address _teamWallet,
        address _bountyOnlineWallet,
        address _bountyOfflineWallet,
        address _advisoryWallet,
        address _reservedWallet
    ) {
        require(_startTimeTLP1 >= block.timestamp);
        require(_startTimeTLP2 > _startTimeTLP1);
        require(_wallet != 0x0);
        require(_wavesAgent != 0x0);
        require(_fundMintingAgent != 0x0);
        require(_teamWallet != 0x0);
        require(_bountyOnlineWallet != 0x0);
        require(_bountyOfflineWallet != 0x0);
        require(_advisoryWallet != 0x0);
        require(_reservedWallet != 0x0);

        token = new McFlyToken();

        startTimeTLP1 = _startTimeTLP1; 
        endTimeTLP1 = startTimeTLP1.add(daysTLP1);

        require(endTimeTLP1 < _startTimeTLP2);

        startTimeTLP2 = _startTimeTLP2; 
        endTimeTLP2 = startTimeTLP2.add(daysTLP2);

        wavesAgent = _wavesAgent;
        fundMintingAgent = _fundMintingAgent;

        wallet = _wallet;
        teamWallet = _teamWallet;
        bountyOnlineWallet = _bountyOnlineWallet;
        bountyOfflineWallet = _bountyOfflineWallet;
        advisoryWallet = _advisoryWallet;
        reservedWallet = _reservedWallet;

        totalETH = wavesTokens.mul(priceTLP1.mul(65).div(100)).div(1e18);  
        token.mint(wavesAgent, wavesTokens);
        token.allowTransfer(wavesAgent);
    }

    function withinPeriod() constant public returns (bool) {
        bool withinPeriodTLP1 = (now >= startTimeTLP1 && now <= endTimeTLP1);
        bool withinPeriodTLP2 = (now >= startTimeTLP2 && now <= endTimeTLP2);
        return withinPeriodTLP1 || withinPeriodTLP2;
    }

     
    function running() constant public returns (bool) {
        return withinPeriod() && !token.mintingFinished();
    }

    function teamTokens() constant public returns (uint256) {
        if(_teamTokens > 0) {
            return _teamTokens;
        }
        return token.totalSupply().mul(teamPercents).div(70);
    }

    function bountyOnlineTokens() constant public returns (uint256) {
        if(_bountyOnlineTokens > 0) {
            return _bountyOnlineTokens;
        }
        return token.totalSupply().mul(bountyOnlinePercents).div(70);
    }

    function bountyOfflineTokens() constant public returns (uint256) {
        if(_bountyOfflineTokens > 0) {
            return _bountyOfflineTokens;
        }
        return token.totalSupply().mul(bountyOfflinePercents).div(70);
    }

    function advisoryTokens() constant public returns (uint256) {
        if(_advisoryTokens > 0) {
            return _advisoryTokens;
        }
        return token.totalSupply().mul(advisoryPercents).div(70);
    }

    function reservedTokens() constant public returns (uint256) {
        if(_reservedTokens > 0) {
            return _reservedTokens;
        }
        return token.totalSupply().mul(reservedPercents).div(70);
    }

     
    function stageName() constant public returns (string) {
        bool beforePeriodTLP1 = (now < startTimeTLP1);
        bool withinPeriodTLP1 = (now >= startTimeTLP1 && now <= endTimeTLP1);
        bool betweenPeriodTLP1andTLP2 = (now >= endTimeTLP1 && now <= startTimeTLP2);
        bool withinPeriodTLP2 = (now >= startTimeTLP2 && now <= endTimeTLP2);

        if(beforePeriodTLP1) {
            return 'Not started';
        }

        if(withinPeriodTLP1) {
            return 'TLP1.1';
        } 

        if(betweenPeriodTLP1andTLP2) {
            return 'Between TLP1.1 and TLP1.2';
        }

        if(withinPeriodTLP2) {
            return 'TLP1.2';
        }

        return 'Finished';
    }

     
    function() payable {
        return buyTokens(msg.sender);
    }

     
    function setFundMintingAgent(address agent) onlyOwner {
        fundMintingAgent = agent;
        SetFundMintingAgent(agent);
    }

     
    function setStartTimeTLP2(uint256 _at) onlyOwner {
        require(block.timestamp < startTimeTLP2);  
        require(block.timestamp < _at);  
        require(endTimeTLP1 < _at);  

        startTimeTLP2 = _at;
        endTimeTLP2 = startTimeTLP2.add(daysTLP2);
        SetStartTimeTLP2(_at);
    }

     
    function setStartTimeTLP1(uint256 _at) onlyOwner {
        require(block.timestamp < startTimeTLP1);  
        require(block.timestamp < _at);  

        startTimeTLP1 = _at;
        endTimeTLP1 = startTimeTLP1.add(daysTLP1);
        SetStartTimeTLP1(_at);
    }

     
    function fundMinting(address to, uint256 amount) stopInEmergency {
        require(msg.sender == fundMintingAgent || isOwner());
        require(block.timestamp <= startTimeTLP2);
        require(fundTotalSupply + amount <= fundTokens);
        require(token.totalSupply() + amount <= mintCapInTokens);

        fundTotalSupply = fundTotalSupply.add(amount);
        FundMinting(to, amount);
        token.mint(to, amount);
    }

     
    function calcAmountAt(
        uint256 amount,
        uint256 at,
        uint256 _totalSupply
    ) public constant returns (uint256, uint256) {
        uint256 estimate;
        uint256 discount;
        uint256 price;

        if(at >= startTimeTLP1 && at <= endTimeTLP1) {
             
            require(amount >= minimalWeiTLP1);

            price = priceTLP1;

            if(at < startTimeTLP1 + 3 days) {
                discount = 65;  

            } else if(at < startTimeTLP1 + 6 days) {
                discount = 70;  

            } else if(at < startTimeTLP1 + 9 days) {
                discount = 85;  

            } else if(at < startTimeTLP1 + 12 days) {
                discount = 100;  

            } else {
                revert();
            }

        } else if(at >= startTimeTLP2 && at <= endTimeTLP2) {
             
            require(amount >= minimalWeiTLP2);

            price = priceTLP2;

            if(at < startTimeTLP2 + 3 days) {
                discount = 60;  

            } else if(at < startTimeTLP2 + 6 days) {
                discount = 70;  

            } else if(at < startTimeTLP2 + 9 days) {
                discount = 80;  

            } else if(at < startTimeTLP2 + 12 days) {
                discount = 90;  

            } else if(at < startTimeTLP2 + 15 days) {
                discount = 100;  

            } else if(at < startTimeTLP2 + 18 days) {
                discount = 110;  

            } else if(at < startTimeTLP2 + 21 days) {
                discount = 120;  

            } else if(at < startTimeTLP2 + 24 days) {
                discount = 130;  

            } else {
                revert();
            }
        } else {
            revert();
        }

        price = price.mul(discount).div(100);
        estimate = _totalSupply.add(amount.mul(1e18).div(price));

        if(estimate > mintCapInTokens) {
            return (
                mintCapInTokens.sub(_totalSupply),
                estimate.sub(mintCapInTokens).mul(price).div(1e18)
            );
        }
        return (estimate.sub(_totalSupply), 0);
    }

     
    function buyTokens(address contributor) payable stopInEmergency validPurchase public {
        uint256 amount;
        uint256 odd_ethers;
        uint256 ethers;
        
        (amount, odd_ethers) = calcAmountAt(msg.value, block.timestamp, token.totalSupply());
  
        require(contributor != 0x0) ;
        require(amount + token.totalSupply() <= mintCapInTokens);

        ethers = (msg.value - odd_ethers);

        token.mint(contributor, amount);  
        TokenPurchase(contributor, ethers, amount);
        totalETH += ethers;

        if(odd_ethers > 0) {
            require(odd_ethers < msg.value);
            TransferOddEther(contributor, odd_ethers);
            contributor.transfer(odd_ethers);
        }

        wallet.transfer(ethers);
    }

    function teamWithdraw() public {
        require(token.mintingFinished());
        require(msg.sender == teamWallet || isOwner());

        uint256 currentPeriod = (block.timestamp).sub(endTimeTLP2).div(teamVestingPeriodInSeconds);
        if(currentPeriod > teamVestingPeriodsCount) {
            currentPeriod = teamVestingPeriodsCount;
        }
        uint256 tokenAvailable = _teamTokens.mul(currentPeriod).div(teamVestingPeriodsCount).sub(teamTotalSupply);

        require(teamTotalSupply + tokenAvailable <= _teamTokens);

        teamTotalSupply = teamTotalSupply.add(tokenAvailable);

        TeamVesting(teamWallet, currentPeriod, tokenAvailable);
        token.transfer(teamWallet, tokenAvailable);

    }

    function finishCrowdsale() onlyOwner public {
        require(now > endTimeTLP2 || mintCapInTokens == token.totalSupply());
        require(!token.mintingFinished());

        uint256 _totalSupply = token.totalSupply();

         
        _teamTokens = _totalSupply.mul(teamPercents).div(70);  
        token.mint(this, _teamTokens);  

        _reservedTokens = _totalSupply.mul(reservedPercents).div(70);  
        token.mint(reservedWallet, _reservedTokens);

        _advisoryTokens = _totalSupply.mul(advisoryPercents).div(70);  
        token.mint(advisoryWallet, _advisoryTokens);

        _bountyOfflineTokens = _totalSupply.mul(bountyOfflinePercents).div(70);  
        token.mint(bountyOfflineWallet, _bountyOfflineTokens);

        _bountyOnlineTokens = _totalSupply.mul(bountyOnlinePercents).div(70);  
        token.mint(bountyOnlineWallet, _bountyOnlineTokens);

        token.finishMinting();
   }

}