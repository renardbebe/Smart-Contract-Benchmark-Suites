 

pragma solidity ^0.4.19;

 
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
  function() public payable { }
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

contract ESCBAirdropper is Ownable {
    using SafeMath for uint256;
    uint256 public airdropTokens;
    uint256 public totalClaimed;
    uint256 public amountOfTokens;
    mapping (address => bool) public tokensReceived;
    mapping (address => bool) public craneList;
    mapping (address => bool) public airdropAgent;
    ERC20 public token;
    bool public craneEnabled = false;

    modifier onlyAirdropAgent() {
        require(airdropAgent[msg.sender]);
         _;
    }

    modifier whenCraneEnabled() {
        require(craneEnabled);
         _;
    }

    function ESCBAirdropper(uint256 _amount, address _tokenAddress) public {
        totalClaimed = 0;
        amountOfTokens = _amount;
        token = ERC20(_tokenAddress);
    }

     
    function airdrop(address[] _recipients) public onlyAirdropAgent {
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(!tokensReceived[_recipients[i]]);  
            require(token.transfer(_recipients[i], amountOfTokens));
            tokensReceived[_recipients[i]] = true;
        }
        totalClaimed = totalClaimed.add(amountOfTokens * _recipients.length);
    }

     
    function airdropDynamic(address[] _recipients, uint256[] _amount) public onlyAirdropAgent {
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(!tokensReceived[_recipients[i]]);  
            require(token.transfer(_recipients[i], _amount[i]));
            tokensReceived[_recipients[i]] = true;
            totalClaimed = totalClaimed.add(_amount[i]);
        }
    }

     
    function setAirdropAgent(address _agentAddress, bool state) public onlyOwner {
        airdropAgent[_agentAddress] = state;
    }

     
    function reset() public onlyOwner {
        require(token.transfer(owner, remainingTokens()));
    }

     
    function changeTokenAddress(address _tokenAddress) public onlyOwner {
        token = ERC20(_tokenAddress);
    }

     
    function changeTokenAmount(uint256 _amount) public onlyOwner {
        amountOfTokens = _amount;
    }

     
    function changeCraneStatus(bool _status) public onlyOwner {
        craneEnabled = _status;
    }

     
    function remainingTokens() public view returns (uint256) {
        return token.balanceOf(this);
    }

     
    function addAddressToCraneList(address[] _recipients) public onlyAirdropAgent {
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(!tokensReceived[_recipients[i]]);  
            require(!craneList[_recipients[i]]);
            craneList[_recipients[i]] = true;
        }
    }

     
    function getFreeTokens() public
      whenCraneEnabled
    {
        require(craneList[msg.sender]);
        require(!tokensReceived[msg.sender]);  
        require(token.transfer(msg.sender, amountOfTokens));
        tokensReceived[msg.sender] = true;
        totalClaimed = totalClaimed.add(amountOfTokens);
    }

}