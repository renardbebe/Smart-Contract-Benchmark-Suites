 

pragma solidity 0.4.23;


 
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


 
contract MintableTokenIface {
    function mint(address to, uint256 amount) public returns (bool);
}


 
contract TempusCrowdsale {
    using SafeMath for uint256;

     
    mapping(address => bool) public owners;

     
    MintableTokenIface public token;

     
    address[] public wallets;

     
    uint256 public currentRoundId;

     
    uint256 public tokensCap;

     
    uint256 public tokensIssued;

     
    uint256 public weiRaised;

     
    uint256 public minInvestment = 100000000000000000;

     
    struct Round {
        uint256 startTime;
        uint256 endTime;
        uint256 weiRaised;
        uint256 tokensIssued;
        uint256 tokensCap;
        uint256 tokenPrice;
    }

    Round[5] public rounds;

     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

     
    event WalletAdded(address indexed wallet);

     
    event WalletRemoved(address indexed wallet);

     
    event OwnerAdded(address indexed newOwner);

     
    event OwnerRemoved(address indexed removedOwner);

     
    event SwitchedToNextRound(uint256 id);

    constructor(MintableTokenIface _token) public {
        token = _token;
        tokensCap = 100000000000000000;
        rounds[0] = Round(now, now.add(30 * 1 days), 0, 0, 20000000000000000, 50000000);
        rounds[1] = Round(now.add(30 * 1 days).add(1), now.add(60 * 1 days), 0, 0, 20000000000000000, 100000000);
        rounds[2] = Round(now.add(60 * 1 days).add(1), now.add(90 * 1 days), 0, 0, 20000000000000000, 200000000);
        rounds[3] = Round(now.add(90 * 1 days).add(1), now.add(120 * 1 days), 0, 0, 20000000000000000, 400000000);
        rounds[4] = Round(now.add(120 * 1 days).add(1), 1599999999, 0, 0, 20000000000000000, 800000000);
        currentRoundId = 0;
        owners[msg.sender] = true;
    }

    function() external payable {
        require(msg.sender != address(0));
        require(msg.value >= minInvestment);
        if (now > rounds[currentRoundId].endTime) {
            switchToNextRound();
        }
        uint256 tokenPrice = rounds[currentRoundId].tokenPrice;
        uint256 tokens = msg.value.div(tokenPrice);
        token.mint(msg.sender, tokens);
        emit TokenPurchase(msg.sender, msg.value, tokens);
        tokensIssued = tokensIssued.add(tokens);
        rounds[currentRoundId].tokensIssued = rounds[currentRoundId].tokensIssued.add(tokens);
        weiRaised = weiRaised.add(msg.value);
        rounds[currentRoundId].weiRaised = rounds[currentRoundId].weiRaised.add(msg.value);
        if (rounds[currentRoundId].tokensIssued >= rounds[currentRoundId].tokensCap) {
            switchToNextRound();
        }
        forwardFunds();
    }

     
    function switchToNextRound() public {
        uint256 prevRoundId = currentRoundId;
        uint256 nextRoundId = currentRoundId + 1;
        require(nextRoundId < rounds.length);
        rounds[prevRoundId].endTime = now;
        rounds[nextRoundId].startTime = now + 1;
        rounds[nextRoundId].endTime = now + 30;
        if (nextRoundId == rounds.length - 1) {
            rounds[nextRoundId].tokensCap = tokensCap.sub(tokensIssued);
        } else {
            rounds[nextRoundId].tokensCap = tokensCap.sub(tokensIssued).div(5);
        }
        currentRoundId = nextRoundId;
        emit SwitchedToNextRound(currentRoundId);
    }

     
    function addWallet(address _address) public onlyOwner {
        require(_address != address(0));
        for (uint256 i = 0; i < wallets.length; i++) {
            require(_address != wallets[i]);
        }
        wallets.push(_address);
        emit WalletAdded(_address);
    }

     
    function delWallet(uint256 index) public onlyOwner {
        require(index < wallets.length);
        address walletToRemove = wallets[index];
        for (uint256 i = index; i < wallets.length - 1; i++) {
            wallets[i] = wallets[i + 1];
        }
        wallets.length--;
        emit WalletRemoved(walletToRemove);
    }

     
    function addOwner(address _address) public onlyOwner {
        owners[_address] = true;
        emit OwnerAdded(_address);
    }

     
    function delOwner(address _address) public onlyOwner {
        owners[_address] = false;
        emit OwnerRemoved(_address);
    }

     
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

     
    function forwardFunds() internal {
        uint256 value = msg.value.div(wallets.length);
        uint256 rest = msg.value.sub(value.mul(wallets.length));
        for (uint256 i = 0; i < wallets.length - 1; i++) {
            wallets[i].transfer(value);
        }
        wallets[wallets.length - 1].transfer(value + rest);
    }
}