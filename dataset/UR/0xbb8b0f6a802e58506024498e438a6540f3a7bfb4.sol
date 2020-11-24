 

pragma solidity ^0.4.19;


 
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


 
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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


contract PresaleFirst is Whitelist, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public constant maxcap = 1500 ether;
    uint256 public constant exceed = 300 ether;
    uint256 public constant minimum = 0.5 ether;
    uint256 public constant rate = 11500;

    uint256 public startNumber;
    uint256 public endNumber;
    uint256 public weiRaised;
    address public wallet;
    ERC20 public token;

    function PresaleFirst (
        uint256 _startNumber,
        uint256 _endNumber,
        address _wallet,
        address _token
        ) public {
        require(_wallet != address(0));
        require(_token != address(0));

        startNumber = _startNumber;
        endNumber = _endNumber;
        wallet = _wallet;
        token = ERC20(_token);
        weiRaised = 0;
    }

 
 
 

    mapping (address => uint256) public buyers;
    address[] private keys;

    function getKeyLength() external constant returns (uint256) {
        return keys.length;
    }

    function () external payable {
        collect(msg.sender);
    }

    function collect(address _buyer) public payable onlyWhitelisted whenNotPaused {
        require(_buyer != address(0));
        require(weiRaised <= maxcap);
        require(preValidation());
        require(buyers[_buyer] < exceed);

         
        if(buyers[_buyer] == 0) {
            keys.push(_buyer);
        }

        uint256 purchase = getPurchaseAmount(_buyer);
        uint256 refund = (msg.value).sub(purchase);

         
        _buyer.transfer(refund);

         
        uint256 tokenAmount = purchase.mul(rate);
        weiRaised = weiRaised.add(purchase);

         
        buyers[_buyer] = buyers[_buyer].add(purchase);
        emit BuyTokens(_buyer, purchase, tokenAmount);
    }

 
 
 

    function preValidation() private constant returns (bool) {
         
        bool a = msg.value >= minimum;

         
        bool b = block.number >= startNumber && block.number <= endNumber;

        return a && b;
    }

    function getPurchaseAmount(address _buyer) private constant returns (uint256) {
        return checkOverMaxcap(checkOverExceed(_buyer));
    }

     
    function checkOverExceed(address _buyer) private constant returns (uint256) {
        if(msg.value >= exceed) {
            return exceed;
        } else if(msg.value.add(buyers[_buyer]) >= exceed) {
            return exceed.sub(buyers[_buyer]);
        } else {
            return msg.value;
        }
    }

     
    function checkOverMaxcap(uint256 amount) private constant returns (uint256) {
        if((amount + weiRaised) >= maxcap) {
            return (maxcap.sub(weiRaised));
        } else {
            return amount;
        }
    }

 
 
 

    bool finalized = false;

    function finalize() public onlyOwner {
        require(!finalized);
        require(weiRaised >= maxcap || block.number >= endNumber);

         
        withdrawEther();
        withdrawToken();

        finalized = true;
    }

 
 
 

    function release(address addr) public onlyOwner {
        require(!finalized);

        token.safeTransfer(addr, buyers[addr].mul(rate));
        emit Release(addr, buyers[addr].mul(rate));

        buyers[addr] = 0;
    }

    function releaseMany(uint256 start, uint256 end) external onlyOwner {
        for(uint256 i = start; i < end; i++) {
            release(keys[i]);
        }
    }

 
 
 

    function refund(address addr) public onlyOwner {
        require(!finalized);

        addr.transfer(buyers[addr]);
        emit Refund(addr, buyers[addr]);

        buyers[addr] = 0;
    }

    function refundMany(uint256 start, uint256 end) external onlyOwner {
        for(uint256 i = start; i < end; i++) {
            refund(keys[i]);
        }
    }

 
 
 

    function withdrawToken() public onlyOwner {
        token.safeTransfer(wallet, token.balanceOf(this));
        emit Withdraw(wallet, token.balanceOf(this));
    }

    function withdrawEther() public onlyOwner {
        wallet.transfer(address(this).balance);
        emit Withdraw(wallet, address(this).balance);
    }

 
 
 

    event Release(address indexed _to, uint256 _amount);
    event Withdraw(address indexed _from, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);
    event BuyTokens(address indexed buyer, uint256 price, uint256 tokens);
}