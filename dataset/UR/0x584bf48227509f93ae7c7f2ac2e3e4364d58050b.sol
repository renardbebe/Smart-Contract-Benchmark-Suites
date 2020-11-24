 

pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract BeatTokenCrowdsale is Ownable {

    enum Stages {
        Deployed,
        PreIco,
        IcoPhase1,
        IcoPhase2,
        IcoPhase3,
        IcoEnded,
        Finalized
    }
    Stages public stage;

    using SafeMath for uint256;

    BeatToken public token;

    uint256 public contractStartTime;
    uint256 public preIcoEndTime;
    uint256 public icoPhase1EndTime;
    uint256 public icoPhase2EndTime;
    uint256 public icoPhase3EndTime;
    uint256 public contractEndTime;

    address public ethTeamWallet;
    address public beatTeamWallet;

    uint256 public ethWeiRaised;
    mapping(address => uint256) public balanceOf;

    uint public constant PRE_ICO_PERIOD = 28 days;
    uint public constant ICO_PHASE1_PERIOD = 28 days;
    uint public constant ICO_PHASE2_PERIOD = 28 days;
    uint public constant ICO_PHASE3_PERIOD = 28 days;

    uint256 public constant PRE_ICO_BONUS_PERCENTAGE = 100;
    uint256 public constant ICO_PHASE1_BONUS_PERCENTAGE = 75;
    uint256 public constant ICO_PHASE2_BONUS_PERCENTAGE = 50;
    uint256 public constant ICO_PHASE3_BONUS_PERCENTAGE = 25;

     
    uint256 public constant PRE_ICO_AMOUNT = 5000 * (10 ** 6) * (10 ** 18);
     
    uint256 public constant ICO_PHASE1_AMOUNT = 7000 * (10 ** 6) * (10 ** 18);
     
    uint256 public constant ICO_PHASE2_AMOUNT = 10500 * (10 ** 6) * (10 ** 18);
     
    uint256 public constant ICO_PHASE3_AMOUNT = 11875 * (10 ** 6) * (10 ** 18);

    uint256 public constant PRE_ICO_LIMIT = PRE_ICO_AMOUNT;
    uint256 public constant ICO_PHASE1_LIMIT = PRE_ICO_LIMIT + ICO_PHASE1_AMOUNT;
    uint256 public constant ICO_PHASE2_LIMIT = ICO_PHASE1_LIMIT + ICO_PHASE2_AMOUNT;
    uint256 public constant ICO_PHASE3_LIMIT = ICO_PHASE2_LIMIT + ICO_PHASE3_AMOUNT;

     
    uint256 public constant HARD_CAP = 230 * (10 ** 9) * (10 ** 18);

    uint256 public ethPriceInEuroCent;

    event BeatTokenPurchased(address indexed purchaser, address indexed beneficiary, uint256 ethWeiAmount, uint256 beatWeiAmount);
    event BeatTokenEthPriceChanged(uint256 newPrice);
    event BeatTokenPreIcoStarted();
    event BeatTokenIcoPhase1Started();
    event BeatTokenIcoPhase2Started();
    event BeatTokenIcoPhase3Started();
    event BeatTokenIcoFinalized();

    function BeatTokenCrowdsale(address _ethTeamWallet, address _beatTeamWallet) public {
        require(_ethTeamWallet != address(0));
        require(_beatTeamWallet != address(0));

        token = new BeatToken(HARD_CAP);
        stage = Stages.Deployed;
        ethTeamWallet = _ethTeamWallet;
        beatTeamWallet = _beatTeamWallet;
        ethPriceInEuroCent = 0;

        contractStartTime = 0;
        preIcoEndTime = 0;
        icoPhase1EndTime = 0;
        icoPhase2EndTime = 0;
        icoPhase3EndTime = 0;
        contractEndTime = 0;
    }

    function setEtherPriceInEuroCent(uint256 _ethPriceInEuroCent) onlyOwner public {
        ethPriceInEuroCent = _ethPriceInEuroCent;
        BeatTokenEthPriceChanged(_ethPriceInEuroCent);
    }

    function start() onlyOwner public {
        require(stage == Stages.Deployed);
        require(ethPriceInEuroCent > 0);

        contractStartTime = now;
        BeatTokenPreIcoStarted();

        stage = Stages.PreIco;
    }

    function finalize() onlyOwner public {
        require(stage != Stages.Deployed);
        require(stage != Stages.Finalized);

        if (preIcoEndTime == 0) {
            preIcoEndTime = now;
        }
        if (icoPhase1EndTime == 0) {
            icoPhase1EndTime = now;
        }
        if (icoPhase2EndTime == 0) {
            icoPhase2EndTime = now;
        }
        if (icoPhase3EndTime == 0) {
            icoPhase3EndTime = now;
        }
        if (contractEndTime == 0) {
            contractEndTime = now;
        }

        uint256 unsoldTokens = HARD_CAP - token.getTotalSupply();
        token.mint(beatTeamWallet, unsoldTokens);

        BeatTokenIcoFinalized();

        stage = Stages.Finalized;
    }

    function() payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable public {
        require(isWithinValidIcoPhase());
        require(ethPriceInEuroCent > 0);
        require(beneficiary != address(0));
        require(msg.value != 0);

        uint256 ethWeiAmount = msg.value;
         
        uint256 beatWeiAmount = calculateBeatWeiAmount(ethWeiAmount);
        require(isWithinTokenAllocLimit(beatWeiAmount));

        determineCurrentStage(beatWeiAmount);

        balanceOf[beneficiary] += beatWeiAmount;
        ethWeiRaised += ethWeiAmount;

        token.mint(beneficiary, beatWeiAmount);
        BeatTokenPurchased(msg.sender, beneficiary, ethWeiAmount, beatWeiAmount);

        ethTeamWallet.transfer(ethWeiAmount);
    }

    function isWithinValidIcoPhase() internal view returns (bool) {
        return (stage == Stages.PreIco || stage == Stages.IcoPhase1 || stage == Stages.IcoPhase2 || stage == Stages.IcoPhase3);
    }

    function calculateBeatWeiAmount(uint256 ethWeiAmount) internal view returns (uint256) {
        uint256 beatWeiAmount = ethWeiAmount.mul(ethPriceInEuroCent);
        uint256 bonusPercentage = 0;

        if (stage == Stages.PreIco) {
            bonusPercentage = PRE_ICO_BONUS_PERCENTAGE;
        } else if (stage == Stages.IcoPhase1) {
            bonusPercentage = ICO_PHASE1_BONUS_PERCENTAGE;
        } else if (stage == Stages.IcoPhase2) {
            bonusPercentage = ICO_PHASE2_BONUS_PERCENTAGE;
        } else if (stage == Stages.IcoPhase3) {
            bonusPercentage = ICO_PHASE3_BONUS_PERCENTAGE;
        }

         
        return beatWeiAmount.mul(100 + bonusPercentage).add(50).div(100);
    }

    function isWithinTokenAllocLimit(uint256 beatWeiAmount) internal view returns (bool) {
        return token.getTotalSupply().add(beatWeiAmount) <= ICO_PHASE3_LIMIT;
    }

    function determineCurrentStage(uint256 beatWeiAmount) internal {
        uint256 newTokenTotalSupply = token.getTotalSupply().add(beatWeiAmount);

        if (stage == Stages.PreIco && (newTokenTotalSupply > PRE_ICO_LIMIT || now >= contractStartTime + PRE_ICO_PERIOD)) {
            preIcoEndTime = now;
            stage = Stages.IcoPhase1;
            BeatTokenIcoPhase1Started();
        } else if (stage == Stages.IcoPhase1 && (newTokenTotalSupply > ICO_PHASE1_LIMIT || now >= preIcoEndTime + ICO_PHASE1_PERIOD)) {
            icoPhase1EndTime = now;
            stage = Stages.IcoPhase2;
            BeatTokenIcoPhase2Started();
        } else if (stage == Stages.IcoPhase2 && (newTokenTotalSupply > ICO_PHASE2_LIMIT || now >= icoPhase1EndTime + ICO_PHASE2_PERIOD)) {
            icoPhase2EndTime = now;
            stage = Stages.IcoPhase3;
            BeatTokenIcoPhase3Started();
        } else if (stage == Stages.IcoPhase3 && (newTokenTotalSupply == ICO_PHASE3_LIMIT || now >= icoPhase2EndTime + ICO_PHASE3_PERIOD)) {
            icoPhase3EndTime = now;
            stage = Stages.IcoEnded;
        }
    }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract BeatToken is CappedToken {

    string public constant name = "BEAT Token";
    string public constant symbol = "BEAT";
    uint8 public constant decimals = 18;

    function BeatToken(uint256 _cap) CappedToken(_cap) public {
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

}