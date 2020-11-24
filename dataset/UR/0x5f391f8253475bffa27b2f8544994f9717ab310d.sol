 

pragma solidity ^0.4.15;

 
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

contract ClaimableTokens is Ownable {

    address public claimedTokensWallet;

    function ClaimableTokens(address targetWallet) {
        claimedTokensWallet = targetWallet;
    }

    function claimTokens(address tokenAddress) public onlyOwner {
        require(tokenAddress != 0x0);
        ERC20 claimedToken = ERC20(tokenAddress);
        uint balance = claimedToken.balanceOf(this);
        claimedToken.transfer(claimedTokensWallet, balance);
    }
}

contract CromToken is Ownable, ERC20, ClaimableTokens {
    using SafeMath for uint256;
    string public constant name = "CROM Token";
    string public constant symbol = "CROM";
    uint8 public constant decimals = 0;
    uint256 public constant INITIAL_SUPPLY = 10 ** 7;
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function CromToken() Ownable() ClaimableTokens(msg.sender) {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != 0x0);
        require(balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != 0x0);
        require(balances[from] >= value);
        require(value <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }
}

contract CromIco is Ownable, ClaimableTokens {
    using SafeMath for uint256;

    CromToken public token;

     
    uint public preStartTime;
    uint public startTime;
    uint public endTime;

     
    address public targetWallet;
    bool public targetWalletVerified;

     
    uint256 public constant SOFT_CAP = 8000 ether;
    uint256 public constant HARD_CAP = 56000 ether;

     
    uint256 public constant TOKEN_PRICE = 10 finney;

    uint public constant BONUS_BATCH = 2 * 10 ** 6;
    uint public constant BONUS_PERCENTAGE = 25;
    uint256 public constant MINIMAL_PRE_ICO_INVESTMENT = 10 ether;

     
    uint public constant PRE_DURATION = 14 days;
    uint public constant DURATION = 14 days;

     
    mapping (address => uint256) public balanceOf;

     
    mapping (address => bool) public preIcoMembers;

     
    uint256 public amountRaised;

    uint256 public tokensSold;

    bool public paused;

    enum Stages {
        WalletUnverified,
        BeforeIco,
        Payable,
        AfterIco
    }

    enum PayableStages {
        PreIco,
        PublicIco
    }

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    function CromIco(address tokenAddress, address beneficiaryWallet) Ownable() ClaimableTokens(beneficiaryWallet) {
        token = CromToken(tokenAddress);
        preStartTime = 1510920000;
        startTime = preStartTime + PRE_DURATION;
        endTime = startTime + DURATION;
        targetWallet = beneficiaryWallet;
        targetWalletVerified = false;
        paused = false;
    }

    modifier atStage(Stages stage) {
        require(stage == getCurrentStage());
        _;
    }

     
    function() payable atStage(Stages.Payable) {
        buyTokens();
    }

   
    function buyTokens() internal {
        require(msg.sender != 0x0);
        require(msg.value > 0);
        require(!paused);

        uint256 weiAmount = msg.value;

         
        uint256 tokens = calculateTokensAmount(weiAmount);
        require(tokens > 0);
        require(token.balanceOf(this) >= tokens);

        if (PayableStages.PreIco == getPayableStage()) {
            require(preIcoMembers[msg.sender]);
            require(weiAmount.add(balanceOf[msg.sender]) >= MINIMAL_PRE_ICO_INVESTMENT);
            require(tokensSold.add(tokens) <= BONUS_BATCH);
        }

        amountRaised = amountRaised.add(weiAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(weiAmount);
        tokensSold = tokensSold.add(tokens);
        token.transfer(msg.sender, tokens);

        TokenPurchase(msg.sender, weiAmount, tokens);
    }

    function verifyTargetWallet() public atStage(Stages.WalletUnverified) {
        require(msg.sender == targetWallet);
        targetWalletVerified = true;
    }

     
    function addPreIcoMembers(address[] members) public onlyOwner {
        for (uint i = 0; i < members.length; i++) {
            preIcoMembers[members[i]] = true;
        }
    }

     
    function removePreIcoMembers(address[] members) public onlyOwner {
        for (uint i = 0; i < members.length; i++) {
            preIcoMembers[members[i]] = false;
        }
    }

     
    function isPreIcoActive() public constant returns (bool) {
        bool isPayable = Stages.Payable == getCurrentStage();
        bool isPreIco = PayableStages.PreIco == getPayableStage();
        return isPayable && isPreIco;
    }

     
    function isPublicIcoActive() public constant returns (bool) {
        bool isPayable = Stages.Payable == getCurrentStage();
        bool isPublic = PayableStages.PublicIco == getPayableStage();
        return isPayable && isPublic;
    }

     
    function hasEnded() public constant returns (bool) {
        return Stages.AfterIco == getCurrentStage();
    }

     
    function softCapReached() public constant returns (bool) {
        return amountRaised >= SOFT_CAP;
    }

     
     
    function withdrawFunds() public atStage(Stages.AfterIco) returns(bool) {
        require(!softCapReached());
        require(balanceOf[msg.sender] > 0);

        uint256 balance = balanceOf[msg.sender];

        balanceOf[msg.sender] = 0;
        msg.sender.transfer(balance);
        return true;
    }

     
     
    function finalizeIco() public onlyOwner atStage(Stages.AfterIco) {
        require(softCapReached());
        targetWallet.transfer(this.balance);
    }

    function withdrawUnsoldTokens() public onlyOwner atStage(Stages.AfterIco) {
        token.transfer(targetWallet, token.balanceOf(this));
    }

    function pause() public onlyOwner {
        require(!paused);
        paused = true;
    }

    function resume() public onlyOwner {
        require(paused);
        paused = false;
    }

    function changeTargetWallet(address wallet) public onlyOwner {
        targetWallet = wallet;
        targetWalletVerified = false;
    }

    function calculateTokensAmount(uint256 funds) internal returns (uint256) {
        uint256 tokens = funds.div(TOKEN_PRICE);
        if (tokensSold < BONUS_BATCH) {
            if (tokensSold.add(tokens) > BONUS_BATCH) {
                uint256 bonusBaseTokens = BONUS_BATCH.mul(100).div(125).sub(tokensSold);
                tokens = tokens.add(bonusBaseTokens.mul(BONUS_PERCENTAGE).div(100));
            } else {
                tokens = tokens.mul(BONUS_PERCENTAGE + 100).div(100);
            }
        }
        return tokens;
    }

    function getCurrentStage() internal constant returns (Stages) {
        if (!targetWalletVerified) {
            return Stages.WalletUnverified;
        } else if (now < preStartTime) {
            return Stages.BeforeIco;
        } else if (now < endTime && amountRaised < HARD_CAP) {
            return Stages.Payable;
        } else {
            return Stages.AfterIco;
        }
    }

    function getPayableStage() internal constant returns (PayableStages) {
        if (now < startTime) {
            return PayableStages.PreIco;
        } else {
            return PayableStages.PublicIco;
        }
    }
}