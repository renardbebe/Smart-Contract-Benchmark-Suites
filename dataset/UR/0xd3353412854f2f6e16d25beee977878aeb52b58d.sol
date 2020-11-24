 

pragma solidity ^0.4.16;

 
contract ERC20 {
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 
 

contract SimpleSale is Ownable,Pausable {

    address public multisig = 0xc862705dDA23A2BAB54a6444B08a397CD4DfCD1c;
    address public cs;
    uint256 public totalCollected;
    bool    public saleFinished;
    bool    public freeForAll = true;
    uint256 public startTime = 1505998800;
    uint256 public stopTime = 1508590800;

    mapping (address => uint256) public deposits;
    mapping (address => bool) public authorised;  

     
    modifier onlyCSorOwner() {
        require((msg.sender == owner) || (msg.sender==cs));
        _;
    }

     
    modifier onlyAuthorised() {
        require (authorised[msg.sender] || freeForAll);
        require (msg.value > 0);
        require (now >= startTime);
        require (now <= stopTime);
        require (!saleFinished);
        require(!paused);
        _;
    }

     
    function setPeriod(uint256 start, uint256 stop) onlyOwner {
        startTime = start;
        stopTime = stop;
    }
    
     
    function authoriseAccount(address whom) onlyCSorOwner {
        authorised[whom] = true;
    }

     
    function authoriseManyAccounts(address[] many) onlyCSorOwner {
        for (uint256 i = 0; i < many.length; i++) {
            authorised[many[i]] = true;
        }
    }

     
    function blockAccount(address whom) onlyCSorOwner {
        authorised[whom] = false;
    }

     
    function setCS(address newCS) onlyOwner {
        cs = newCS;
    }
    
    function requireAuthorisation(bool state) {
        freeForAll = !state;
    }

     
    function stopSale() onlyOwner {
        saleFinished = true;
    }
    

     
    function () payable onlyAuthorised {
        multisig.transfer(msg.value);
        deposits[msg.sender] += msg.value;
        totalCollected += msg.value;
    }

     
    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer(owner, amount);
    }

}