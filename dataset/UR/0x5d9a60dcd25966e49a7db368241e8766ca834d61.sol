 

pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract ApprovedBurnableToken is BurnableToken {

         
        event BurnFrom(address indexed owner,  
                       address indexed burner,  
                       uint256 value            
                );

         
        function burnFrom(address _owner, uint256 _value) public {
                require(_value > 0);
                require(_value <= balances[_owner]);
                require(_value <= allowed[_owner][msg.sender]);
                 
                 

                address burner = msg.sender;
                balances[_owner] = balances[_owner].sub(_value);
                allowed[_owner][burner] = allowed[_owner][burner].sub(_value);
                totalSupply = totalSupply.sub(_value);

                BurnFrom(_owner, burner, _value);
                Burn(_owner, _value);
        }
}

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
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

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
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

contract UnlockedAfterMintingToken is MintableToken {

     
    modifier whenMintingFinished() {
        require(mintingFinished);
        _;
    }

    function transfer(address _to, uint256 _value) public whenMintingFinished returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenMintingFinished returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public whenMintingFinished returns (bool) {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public whenMintingFinished returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public whenMintingFinished returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
}

contract ZakemCoin is UnlockedAfterMintingToken, ApprovedBurnableToken {
         
        uint8 public constant contractVersion = 1;

         
        string public constant name = "ZakemCoin";

         
        string public constant symbol = "FINC";

         
        uint8 public constant decimals = 18;

         

         
}

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }

}

contract ZakemFansCrowdsale is Pausable, RefundableCrowdsale, CappedCrowdsale {
         
        address public foundersWallet;

         
        address public bountiesWallet;

         
        uint256 public purchasedTokensRaised;

         
        uint256 public purchasedTokensRaisedDuringPresale;

         
        uint256 oneTwelfthOfCap;

         
        function ZakemFansCrowdsale (
                uint256 _startTime,
                uint256 _endTime,
                uint256 _rate,
                address _wallet,
                address _bountiesWallet,
                address _foundersWallet,
                uint256 _goal,
                uint256 _cap,
                address _token,
                uint256 _purchasedTokensRaisedDuringPresale
                )
                Crowdsale(_startTime, _endTime, _rate, _wallet)
                RefundableCrowdsale(_goal)
                CappedCrowdsale(_cap)
        {
                require(_goal < _cap);

                bountiesWallet = _bountiesWallet;
                foundersWallet = _foundersWallet;
                token = ZakemCoin(_token);
                weiRaised = 0;

                purchasedTokensRaisedDuringPresale = _purchasedTokensRaisedDuringPresale;
                purchasedTokensRaised = purchasedTokensRaisedDuringPresale;

                oneTwelfthOfCap = _cap / 12;
        }

         
        function createTokenContract() internal returns (MintableToken) {
                return MintableToken(0x0);
        }

         
        function buyTokens(address beneficiary) public payable whenNotPaused {
                require(beneficiary != 0x0);

                uint256 weiAmount = msg.value;

                 
                uint256 purchasedTokens = weiAmount.div(rate);
                require(validPurchase(purchasedTokens));
                purchasedTokens = purchasedTokens.mul(currentBonusRate()).div(100);
                require(purchasedTokens != 0);

                 
                weiRaised = weiRaised.add(weiAmount);
                purchasedTokensRaised = purchasedTokensRaised.add(purchasedTokens);

                 
                token.mint(beneficiary, purchasedTokens);
                TokenPurchase(msg.sender, beneficiary, weiAmount, purchasedTokens);

                mintTokensForFacilitators(purchasedTokens);

                forwardFunds();
        }

         
        function goalReached() public constant returns (bool) {
                return purchasedTokensRaised >= goal;
        }

         
        function hasEnded() public constant returns (bool) {
                bool capReached = purchasedTokensRaised >= cap;
                return Crowdsale.hasEnded() || capReached;
        }

         
        function validPurchase(uint256 purchasedTokens) internal constant returns (bool) {
                 
                 
                bool withinCap = purchasedTokensRaised.add(purchasedTokens) <= cap;
                return Crowdsale.validPurchase() && withinCap;
        }

         
        function mintTokensForFacilitators(uint256 purchasedTokens) internal {
                 
                uint256 fintechfans_tokens = purchasedTokens.mul(4).div(13);
                uint256 bounties_tokens = purchasedTokens.mul(2).div(13);
                uint256 founders_tokens = purchasedTokens.mul(1).div(13);
                token.mint(wallet, fintechfans_tokens);
                token.mint(bountiesWallet, bounties_tokens);
                token.mint(foundersWallet, founders_tokens); 
        }

         
        function currentBonusRate() public constant returns (uint) {
                if(purchasedTokensRaised < (2 * oneTwelfthOfCap)) return 125 ;  
                if(purchasedTokensRaised < (4 * oneTwelfthOfCap)) return 118 ;  
                if(purchasedTokensRaised < (6 * oneTwelfthOfCap)) return 111 ;  
                if(purchasedTokensRaised < (9 * oneTwelfthOfCap)) return 105 ;  
                return 100;
        }
}

contract TheZakemFansCrowdsale is ZakemFansCrowdsale {
    function TheZakemFansCrowdsale()
        ZakemFansCrowdsale(
            1511433000,  
            1511445600,  
            3890,  
            0x99A5450C9019Cde36b4aaFf9b232D0bc16253C95,  
            0x88921f514699906AD47D11F9c5fDbb8B00569484,  
            0x0C669E325CeB58D8a436dc3466D4DFaC9d5Eb2F0,  
            39800000000000000,  
            398000000000000000,  
            0x145ea59782c0468510459f9219e863555b1868a5,  
            0   
            )
    {
    }
}