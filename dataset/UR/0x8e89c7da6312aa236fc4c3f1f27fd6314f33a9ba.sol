 

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

contract AidCoin is MintableToken, BurnableToken {
    string public name = "AidCoin";
    string public symbol = "AID";
    uint256 public decimals = 18;
    uint256 public maxSupply = 100000000 * (10 ** decimals);

    function AidCoin() public {

    }

    modifier canTransfer(address _from, uint _value) {
        require(mintingFinished);
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract AidCoinPresale is Ownable, Crowdsale {
    using SafeMath for uint256;

     
    uint256 public tokenCap = 10000000 * (10 ** 18);

     
    uint256 public soldTokens;

     
    address public teamWallet;
     
    address public advisorWallet;
     
    address public aidPoolWallet;
     
    address public companyWallet;
     
    address public bountyWallet;

     
    uint256 public teamTokens 		= 	10000000 * (10 ** 18);
    uint256 public advisorTokens 	= 	10000000 * (10 ** 18);
    uint256 public aidPoolTokens 	= 	10000000 * (10 ** 18);
    uint256 public companyTokens 	= 	27000000 * (10 ** 18);
    uint256 public bountyTokens 	= 	3000000 * (10 ** 18);

    uint256 public claimedAirdropTokens;
    mapping (address => bool) public claimedAirdrop;

     
    TokenTimelock public teamTimeLock;
     
    TokenTimelock public advisorTimeLock;
     
    TokenTimelock public companyTimeLock;

    modifier beforeEnd() {
        require(now < endTime);
        _;
    }

    function AidCoinPresale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        address _teamWallet,
        address _advisorWallet,
        address _aidPoolWallet,
        address _companyWallet,
        address _bountyWallet
    ) public
    Crowdsale (_startTime, _endTime, _rate, _wallet)
    {

        require(_teamWallet != 0x0);
        require(_advisorWallet != 0x0);
        require(_aidPoolWallet != 0x0);
        require(_companyWallet != 0x0);
        require(_bountyWallet != 0x0);

        teamWallet = _teamWallet;
        advisorWallet = _advisorWallet;
        aidPoolWallet = _aidPoolWallet;
        companyWallet = _companyWallet;
        bountyWallet = _bountyWallet;

         
        token.mint(aidPoolWallet, aidPoolTokens);

         
        teamTimeLock = new TokenTimelock(token, teamWallet, uint64(now + 1 years));
        token.mint(address(teamTimeLock), teamTokens);

         
        companyTimeLock = new TokenTimelock(token, companyWallet, uint64(now + 1 years));
        token.mint(address(companyTimeLock), companyTokens);

         
        uint256 initialAdvisorTokens = advisorTokens.mul(20).div(100);
        token.mint(advisorWallet, initialAdvisorTokens);
        uint256 lockedAdvisorTokens = advisorTokens.sub(initialAdvisorTokens);
        advisorTimeLock = new TokenTimelock(token, advisorWallet, uint64(now + 180 days));
        token.mint(address(advisorTimeLock), lockedAdvisorTokens);
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new AidCoin();
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

         
        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

         
        uint256 newTotalSold = soldTokens.add(tokens);

         
        require(newTotalSold <= tokenCap);

         
        weiRaised = weiRaised.add(weiAmount);
        soldTokens = newTotalSold;

         
        token.mint(beneficiary, tokens);
        TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens
        );

        forwardFunds();
    }

     
    function airdrop(address[] users) public onlyOwner beforeEnd {
        require(users.length > 0);

        uint256 amount = 5 * (10 ** 18);

        uint len = users.length;
        for (uint i = 0; i < len; i++) {
            address to = users[i];
            if (!claimedAirdrop[to]) {
                claimedAirdropTokens = claimedAirdropTokens.add(amount);
                require(claimedAirdropTokens <= bountyTokens);

                claimedAirdrop[to] = true;
                token.mint(to, amount);
            }
        }
    }

     
    function closeTokenSale(address _icoContract) public onlyOwner {
        require(hasEnded());
        require(_icoContract != 0x0);

         
        uint256 unclaimedAirdropTokens = bountyTokens.sub(claimedAirdropTokens);
        if (unclaimedAirdropTokens > 0) {
            token.mint(bountyWallet, unclaimedAirdropTokens);
        }

         
        token.transferOwnership(_icoContract);
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = soldTokens >= tokenCap;
        return super.hasEnded() || capReached;
    }

     
    function hasStarted() public constant returns (bool) {
        return now >= startTime && now < endTime;
    }
}