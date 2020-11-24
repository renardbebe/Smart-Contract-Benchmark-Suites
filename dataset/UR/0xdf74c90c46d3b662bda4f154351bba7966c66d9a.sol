 

pragma solidity 0.4.23;

 

interface ACOTokenCrowdsale {
    function buyTokens(address beneficiary) external payable;
    function hasEnded() external view returns (bool);
}

 

 

 
 
 
 

 
 
 
 

 
 

pragma solidity 0.4.23;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract TokenDestructible is Ownable {

  constructor() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 
 
 
 
 
 
contract TokenBuy is Pausable, Claimable, TokenDestructible, DSMath {
    using SafeERC20 for ERC20Basic;

     
    ACOTokenCrowdsale public crowdsaleContract;

     
    ERC20Basic public tokenContract;

     
    mapping(address => uint) public balances;

     
    address[] public contributors;

     
    uint public totalContributions;

     
    uint public totalTokensPurchased;

     
    event Purchase(address indexed sender, uint ethAmount, uint tokensPurchased);

     
    event Collection(address indexed recipient, uint amount);

     
    uint constant unlockTime = 1543622400;  

     
     
    modifier whenSaleRunning() {
        require(!crowdsaleContract.hasEnded());
        _;
    }

     
     
    constructor(ACOTokenCrowdsale crowdsale, ERC20Basic token) public {
        require(crowdsale != address(0x0));
        require(token != address(0x0));
        crowdsaleContract = crowdsale;
        tokenContract = token;
    }

     
     
     
     
    function contributorCount() public view returns (uint) {
        return contributors.length;
    }

     
    function() public payable {
        if (msg.value == 0) {
            collectFor(msg.sender);
        } else {
            buy();
        }
    }

     
    function buy() whenNotPaused whenSaleRunning private {
        address buyer = msg.sender;
        totalContributions += msg.value;
        uint tokensPurchased = purchaseTokens();
        totalTokensPurchased = add(totalTokensPurchased, tokensPurchased);

        uint previousBalance = balances[buyer];
        balances[buyer] = add(previousBalance, tokensPurchased);

         
        if (previousBalance == 0) {
            contributors.push(buyer);
        }

        emit Purchase(buyer, msg.value, tokensPurchased);
    }

    function purchaseTokens() private returns (uint tokensPurchased) {
        address me = address(this);
        uint previousBalance = tokenContract.balanceOf(me);
        crowdsaleContract.buyTokens.value(msg.value)(me);
        uint newBalance = tokenContract.balanceOf(me);

        require(newBalance > previousBalance);  
        return newBalance - previousBalance;
    }

     
     
     
    function collectFor(address recipient) private {
        uint tokensOwned = balances[recipient];
        if (tokensOwned == 0) return;

        delete balances[recipient];
        tokenContract.safeTransfer(recipient, tokensOwned);
        emit Collection(recipient, tokensOwned);
    }

     
     
    function collectAll(uint8 max) public returns (uint8 collected) {
        max = uint8(min(max, contributors.length));
        require(max > 0, "can't collect for zero users");

        uint index = contributors.length - 1;
        for(uint offset = 0; offset < max; ++offset) {
            address recipient = contributors[index - offset];

            if (balances[recipient] > 0) {
                collected++;
                collectFor(recipient);
            }
        }

        contributors.length -= offset;
    }

     
    function destroy(address[] tokens) onlyOwner public {
        require(now > unlockTime || (contributorCount() == 0 && paused));

        super.destroy(tokens);
    }
}