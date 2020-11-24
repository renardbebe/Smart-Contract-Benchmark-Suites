 

pragma solidity ^0.4.15;

 
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
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


 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}


 
contract BitImageToken is StandardToken, BurnableToken, Ownable {

     
    event Timelock(address indexed _holder, uint256 _releaseTime);

    string public name;
    string public symbol;
    uint8 public decimals;
    bool public released;
    address public saleAgent;

    mapping (address => uint256) public timelock;

    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }

    modifier whenReleased() {
        if (timelock[msg.sender] != 0) {
            require(released && now > timelock[msg.sender]);
        } else {
            require(released || msg.sender == saleAgent);
        }
        _;
    }


     
    function BitImageToken() public {
        name = "Bitimage Token";
        symbol = "BIM";
        decimals = 18;
        released = false;
        totalSupply = 10000000000 ether;
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }

     
    function setSaleAgent(address _saleAgent) public onlyOwner {
        require(_saleAgent != address(0));
        require(saleAgent == address(0));
        saleAgent = _saleAgent;
        super.approve(saleAgent, totalSupply);
    }

     
    function release() public onlySaleAgent {
        released = true;
    }

     
    function lock(address _holder, uint256 _releaseTime) public onlySaleAgent {
        require(_holder != address(0));
        require(_releaseTime > now);
        timelock[_holder] = _releaseTime;
        Timelock(_holder, _releaseTime);
    }

     
    function transfer(address _to, uint256 _value) public whenReleased returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenReleased returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public whenReleased returns (bool) {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public whenReleased returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public whenReleased returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
    function burn(uint256 _value) public onlySaleAgent {
        super.burn(_value);
    }

     
    function burnFrom(address _from, uint256 _value) public onlySaleAgent {
        require(_value > 0);
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
    }
}


 
contract BitImageTokenSale is Pausable {
    using SafeMath for uint256;

     
    event TokenPurchase(address indexed _investor, uint256 _weiAmount, uint256 _tokenAmount);

     
    event Refunded(address indexed _investor, uint256 _weiAmount);

    BitImageToken public token;

    address public walletEtherPresale;
    address public walletEhterCrowdsale;

    address public walletTokenTeam;
    address[] public walletTokenAdvisors;
    address public walletTokenBounty;
    address public walletTokenReservation;

    uint256 public startTime;
    uint256 public period;
    uint256 public periodPresale;
    uint256 public periodCrowdsale;
    uint256 public periodWeek;

    uint256 public weiMinInvestment;
    uint256 public weiMaxInvestment;

    uint256 public rate;

    uint256 public softCap;
    uint256 public goal;
    uint256 public goalIncrement;
    uint256 public hardCap;

    uint256 public tokenIcoAllocated;
    uint256 public tokenTeamAllocated;
    uint256 public tokenAdvisorsAllocated;
    uint256 public tokenBountyAllocated;
    uint256 public tokenReservationAllocated;

    uint256 public weiTotalReceived;

    uint256 public tokenTotalSold;

    uint256 public weiTotalRefunded;

    uint256 public bonus;
    uint256 public bonusDicrement;
    uint256 public bonusAfterPresale;

    struct Investor {
        uint256 weiContributed;
        uint256 tokenBuyed;
        bool refunded;
    }

    mapping (address => Investor) private investors;
    address[] private investorsIndex;

    enum State { NEW, PRESALE, CROWDSALE, CLOSED }
    State public state;


     
    function BitImageTokenSale() public {
        walletEtherPresale = 0xE19f0ccc003a36396FE9dA4F344157B2c60A4B8E;
        walletEhterCrowdsale = 0x10e5f0e94A43FA7C9f7F88F42a6a861312aD1d31;
        walletTokenTeam = 0x35425E32fE41f167990DBEa1010132E9669Fa500;
        walletTokenBounty = 0x91325c4a25893d80e26b4dC14b964Cf5a27fECD8;
        walletTokenReservation = 0x4795eC1E7C24B80001eb1F43206F6e075fCAb4fc;
        walletTokenAdvisors = [
            0x2E308F904C831e41329215a4807d9f1a82B67eE2,
            0x331274f61b3C976899D6FeB6f18A966A50E98C8d,
            0x6098b02d10A1f27E39bCA219CeB56355126EC74f,
            0xC14C105430C13e6cBdC8DdB41E88fD88b9325927
        ];
        periodPresale = 4 weeks;
        periodCrowdsale = 6 weeks;
        periodWeek = 1 weeks;
        weiMinInvestment = 0.1 ether;
        weiMaxInvestment = 500 ether;
        rate = 130000;
        softCap = 2000 ether;
        goal = 6000 ether;
        goalIncrement = goal;
        hardCap = 42000 ether;
        bonus = 30;
        bonusDicrement = 5;
        state = State.NEW;
        pause();
    }

     
    function() external payable {
        purchase(msg.sender);
    }

     
    function setToken(address _token) external onlyOwner whenPaused {
        require(state == State.NEW);
        require(_token != address(0));
        require(token == address(0));
        token = BitImageToken(_token);
        tokenIcoAllocated = token.totalSupply().mul(62).div(100);
        tokenTeamAllocated = token.totalSupply().mul(18).div(100);
        tokenAdvisorsAllocated = token.totalSupply().mul(4).div(100);
        tokenBountyAllocated = token.totalSupply().mul(6).div(100);
        tokenReservationAllocated = token.totalSupply().mul(10).div(100);
        require(token.totalSupply() == tokenIcoAllocated.add(tokenTeamAllocated).add(tokenAdvisorsAllocated).add(tokenBountyAllocated).add(tokenReservationAllocated));
    }

     
    function start(uint256 _startTime) external onlyOwner whenPaused {
        require(_startTime >= now);
        require(token != address(0));
        if (state == State.NEW) {
            state = State.PRESALE;
            period = periodPresale;
        } else if (state == State.PRESALE && weiTotalReceived >= softCap) {
            state = State.CROWDSALE;
            period = periodCrowdsale;
            bonusAfterPresale = bonus.sub(bonusDicrement);
            bonus = bonusAfterPresale;
        } else {
            revert();
        }
        startTime = _startTime;
        unpause();
    }

     
    function finalize() external onlyOwner {
        require(weiTotalReceived >= softCap);
        require(now > startTime.add(period) || weiTotalReceived >= hardCap);

        if (state == State.PRESALE) {
            require(this.balance > 0);
            walletEtherPresale.transfer(this.balance);
            pause();
        } else if (state == State.CROWDSALE) {
            uint256 tokenTotalUnsold = tokenIcoAllocated.sub(tokenTotalSold);
            tokenReservationAllocated = tokenReservationAllocated.add(tokenTotalUnsold);

            require(token.transferFrom(token.owner(), walletTokenBounty, tokenBountyAllocated));
            require(token.transferFrom(token.owner(), walletTokenReservation, tokenReservationAllocated));
            require(token.transferFrom(token.owner(), walletTokenTeam, tokenTeamAllocated));
            token.lock(walletTokenReservation, now + 0.5 years);
            token.lock(walletTokenTeam, now + 1 years);
            uint256 tokenAdvisor = tokenAdvisorsAllocated.div(walletTokenAdvisors.length);
            for (uint256 i = 0; i < walletTokenAdvisors.length; i++) {
                require(token.transferFrom(token.owner(), walletTokenAdvisors[i], tokenAdvisor));
                token.lock(walletTokenAdvisors[i], now + 0.5 years);
            }

            token.release();
            state = State.CLOSED;
        } else {
            revert();
        }
    }

     
    function refund() external whenNotPaused {
        require(state == State.PRESALE);
        require(now > startTime.add(period));
        require(weiTotalReceived < softCap);

        require(this.balance > 0);

        Investor storage investor = investors[msg.sender];

        require(investor.weiContributed > 0);
        require(!investor.refunded);

        msg.sender.transfer(investor.weiContributed);
        token.burnFrom(msg.sender, investor.tokenBuyed);
        investor.refunded = true;
        weiTotalRefunded = weiTotalRefunded.add(investor.weiContributed);

        Refunded(msg.sender, investor.weiContributed);
    }

    function purchase(address _investor) private whenNotPaused {
        require(state == State.PRESALE || state == State.CROWDSALE);
        require(now >= startTime && now <= startTime.add(period));

        if (state == State.CROWDSALE) {
            uint256 timeFromStart = now.sub(startTime);
            if (timeFromStart > periodWeek) {
                uint256 currentWeek = timeFromStart.div(1 weeks);
                uint256 bonusWeek = bonusAfterPresale.sub(bonusDicrement.mul(currentWeek));
                if (bonus > bonusWeek) {
                    bonus = bonusWeek;
                }
                currentWeek++;
                periodWeek = currentWeek.mul(1 weeks);
            }
        }

        uint256 weiAmount = msg.value;
        require(weiAmount >= weiMinInvestment && weiAmount <= weiMaxInvestment);

        uint256 tokenAmount = weiAmount.mul(rate);
        uint256 tokenBonusAmount = tokenAmount.mul(bonus).div(100);
        tokenAmount = tokenAmount.add(tokenBonusAmount);

        weiTotalReceived = weiTotalReceived.add(weiAmount);
        tokenTotalSold = tokenTotalSold.add(tokenAmount);
        require(tokenTotalSold <= tokenIcoAllocated);

        require(token.transferFrom(token.owner(), _investor, tokenAmount));

        Investor storage investor = investors[_investor];
        if (investor.weiContributed == 0) {
            investorsIndex.push(_investor);
        }
        investor.tokenBuyed = investor.tokenBuyed.add(tokenAmount);
        investor.weiContributed = investor.weiContributed.add(weiAmount);

        if (state == State.CROWDSALE) {
            walletEhterCrowdsale.transfer(weiAmount);
        }
        TokenPurchase(_investor, weiAmount, tokenAmount);

        if (weiTotalReceived >= goal) {
            if (state == State.PRESALE) {
                startTime = now;
                period = 1 weeks;
            }
            uint256 delta = weiTotalReceived.sub(goal);
            goal = goal.add(goalIncrement).add(delta);
            bonus = bonus.sub(bonusDicrement);
        }
    }
}