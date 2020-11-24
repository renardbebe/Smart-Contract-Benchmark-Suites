 

 

pragma solidity ^0.5.12;
 



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
  address payable public owner;
  address payable public coowner;
  uint256 public globalLimit = 3000000;
  address public token = 0xB120f6b27934C265EA1620e4C213e03039eC7604;

   
  mapping(address => uint256) public distributedBalances;
  
   
  mapping(address => uint256) public personalLimit;
  
  constructor() public {
    owner = msg.sender;
    coowner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyTeam() {
    require(msg.sender == coowner || msg.sender == owner);
    _;
  }

  function transferOwnership(address payable _newOwner) onlyOwner public {
    coowner = _newOwner;
  }

  function changeToken(address _newToken) onlyOwner public {
    token = _newToken;
  }


  function changeGlobalLimit(uint _newGlobalLimit) onlyTeam public {
    globalLimit = _newGlobalLimit;
  }

  function setPersonalLimit(address wallet, uint256 _newPersonalLimit) onlyTeam public {
    personalLimit[wallet] = _newPersonalLimit;
  }

}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Airdropper2 is Ownable {
    using SafeMath for uint256;
    function multisend(address[] calldata wallets, uint256[] calldata values) external onlyTeam returns (uint256) {
        
        uint256 limit = globalLimit;
        uint256 tokensToIssue = 0;
        address wallet = address(0);
        
        for (uint i = 0; i < wallets.length; i++) {

            tokensToIssue = values[i];
            wallet = wallets[i];

           if(tokensToIssue > 0 && wallet != address(0)) { 
               
                if(personalLimit[wallet] > globalLimit) {
                    limit = personalLimit[wallet];
                }

                if(distributedBalances[wallet].add(tokensToIssue) > limit) {
                    tokensToIssue = limit.sub(distributedBalances[wallet]);
                }

                if(limit > distributedBalances[wallet]) {
                    distributedBalances[wallet] = distributedBalances[wallet].add(tokensToIssue);
                    ERC20(token).transfer(wallet, tokensToIssue);
                }
           }
        }
    }
    
    function simplesend(address[] calldata wallets) external onlyTeam returns (uint256) {
        
        uint256 tokensToIssue = globalLimit;
        address wallet = address(0);
        
        for (uint i = 0; i < wallets.length; i++) {
            
            wallet = wallets[i];
           if(wallet != address(0)) {
               
                if(distributedBalances[wallet] == 0) {
                    distributedBalances[wallet] = distributedBalances[wallet].add(tokensToIssue);
                    ERC20(token).transfer(wallet, tokensToIssue);
                }
           }
        }
    }


    function evacuateTokens(ERC20 _tokenInstance, uint256 _tokens) external onlyOwner returns (bool success) {
        _tokenInstance.transfer(owner, _tokens);
        return true;
    }

    function _evacuateEther() onlyOwner external {
        owner.transfer(address(this).balance);
    }
}