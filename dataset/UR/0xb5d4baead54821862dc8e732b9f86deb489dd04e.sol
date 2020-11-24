 

pragma solidity ^0.4.13;

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

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
    return balanceOf(holder);
  }
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
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

contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint64 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function claim() public {
    require(msg.sender == beneficiary);
    release();
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

contract StarterCoin is MintableToken, LimitedTransferToken {

    string public constant name = "StarterCoin";
    string public constant symbol = "STAC";
    uint8 public constant decimals = 18;

    uint256 public endTimeICO;
    address public bountyWallet;

    function StarterCoin(uint256 _endTimeICO, address _bountyWallet) {
        endTimeICO = _endTimeICO;
        bountyWallet = _bountyWallet;
    }

    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
         
        return (time > endTimeICO) || (holder == bountyWallet) ? balanceOf(holder) : 0;
    }

}

contract StarterCoinCrowdsale is Ownable {
    using SafeMath for uint256;
     
    MintableToken public token;

     
    uint256 public startTime;
    uint256 public endTime;

    uint256[11] public timings;
    uint8[10] public bonuses;

     
    address public wallet89;
    address public wallet10;
    address public wallet1;

     
    uint256 public constant RATE = 4500;

     
    uint256 public weiRaised;

    uint256 public tokenSold;

    uint256 public constant CAP = 154622 ether;
    uint256 public constant TOKEN_CAP = 695797500 * (10 ** uint256(18));  

    TokenTimelock public devTokenTimelock;
    TokenTimelock public foundersTokenTimelock;
    TokenTimelock public teamTokenTimelock;
    TokenTimelock public advisersTokenTimelock;

    uint256 public constant BOUNTY_SUPPLY = 78400000 * (10 ** uint256(18));
    uint256 public constant DEV_SUPPLY = 78400000 * (10 ** uint256(18));
    uint256 public constant FOUNDERS_SUPPLY = 59600000 * (10 ** uint256(18));
    uint256 public constant TEAM_SUPPLY = 39200000 * (10 ** uint256(18));
    uint256 public constant ADVISERS_SUPPLY = 29400000 * (10 ** uint256(18));


    function StarterCoinCrowdsale(
        uint256 [11] _timings,
        uint8 [10] _bonuses,
        address [3] _wallets,
        address bountyWallet,
        address devWallet,
        uint64 devReleaseTime,
        address foundersWallet,
        uint64 foundersReleaseTime,
        address teamWallet,
        uint64 teamReleaseTime,
        address advisersWallet,
        uint64 advisersReleaseTime
        ) {
            require(_timings[0] >= now);

            for(uint i = 1; i < timings.length; i++) {
              require(_timings[i] >= _timings[i-1]);
            }

            timings = _timings;
            bonuses = _bonuses;
            startTime = timings[0];
            endTime = timings[timings.length-1];

            require(devReleaseTime >= endTime);
            require(foundersReleaseTime >= endTime);
            require(teamReleaseTime >= endTime);
            require(advisersReleaseTime >= endTime);

            require(_wallets[0] != 0x0);
            require(_wallets[1] != 0x0);
            require(_wallets[2] != 0x0);

            require(bountyWallet != 0x0);
            require(devWallet != 0x0);
            require(foundersWallet != 0x0);
            require(teamWallet != 0x0);
            require(advisersWallet != 0x0);

            wallet89 = _wallets[0];
            wallet10 = _wallets[1];
            wallet1 = _wallets[2];

            token = new StarterCoin(endTime, bountyWallet);

            token.mint(bountyWallet, BOUNTY_SUPPLY);

            devTokenTimelock = new TokenTimelock(token, devWallet, devReleaseTime);
            token.mint(devTokenTimelock, DEV_SUPPLY);

            foundersTokenTimelock = new TokenTimelock(token, foundersWallet, foundersReleaseTime);
            token.mint(foundersTokenTimelock, FOUNDERS_SUPPLY);

            teamTokenTimelock = new TokenTimelock(token, teamWallet, teamReleaseTime);
            token.mint(teamTokenTimelock, TEAM_SUPPLY);

            advisersTokenTimelock = new TokenTimelock(token, advisersWallet, advisersReleaseTime);
            token.mint(advisersTokenTimelock, ADVISERS_SUPPLY);
        }

         
        event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

         
         
        function createTokenContract() internal returns (MintableToken) {
            return new MintableToken();
        }


         
        function () payable {
            buyTokens(msg.sender);
        }

         
        function buyTokens(address beneficiary) public payable {
            require(beneficiary != 0x0);
            require(msg.value >= 100);  

            uint256 weiAmount = msg.value;

             
            uint256 periodBonus;

            for (uint8 i = 1; i < timings.length; i++) {
              if ( now < timings[i] ) {
                periodBonus = RATE.mul(uint256(bonuses[i-1])).div(100);
                break;
              }
            }

             
            uint256 bulkPurchaseBonus;
            if (weiAmount >= 50 ether) {
            bulkPurchaseBonus = 3600;  
            } else if (weiAmount >= 30 ether) {
            bulkPurchaseBonus = 3150;  
            } else if (weiAmount >= 10 ether) {
            bulkPurchaseBonus = 2250;  
            } else if (weiAmount >= 5 ether) {
            bulkPurchaseBonus = 1350;  
            } else if (weiAmount >= 3 ether) {
            bulkPurchaseBonus = 450;  
            }

            uint256 actualRate = RATE.add(periodBonus).add(bulkPurchaseBonus);

             
            uint256 tokens = weiAmount.mul(actualRate);

             
            weiRaised = weiRaised.add(weiAmount);
            tokenSold = tokenSold.add(tokens);

            require(validPurchase());

            token.mint(beneficiary, tokens);
            TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

            forwardFunds();
        }

         
         
        function forwardFunds() internal {
          uint256 wei89 = msg.value.mul(89).div(100);
          uint256 wei10 = msg.value.div(10);
          uint256 wei1 = msg.value.sub(wei89).sub(wei10);
          wallet89.transfer(wei89);
          wallet10.transfer(wei10);
          wallet1.transfer(wei1);
        }

         
        function addOffChainContribution(address beneficiar, uint256 weiAmount, uint256 tokenAmount, string btcAddress) onlyOwner public {
            require(beneficiar != 0x0);
            require(weiAmount > 0);
            require(tokenAmount > 0);
            weiRaised += weiAmount;
            tokenSold += tokenAmount;
            require(validPurchase());
            token.mint(beneficiar, tokenAmount);
        }


         
         
        function validPurchase() internal constant returns (bool) {
            bool withinCap = weiRaised <= CAP;
            bool withinPeriod = now >= startTime && now <= endTime;
            bool withinTokenCap = tokenSold <= TOKEN_CAP;
            return withinPeriod && withinCap && withinTokenCap;
        }

         
         
        function hasEnded() public constant returns (bool) {
            bool capReached = weiRaised >= CAP;
            return now > endTime || capReached;
        }

    }