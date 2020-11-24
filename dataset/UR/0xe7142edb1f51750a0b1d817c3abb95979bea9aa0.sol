 

pragma solidity ^0.4.11;

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
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
    if (paused) throw;
    _;
  }

   
  modifier whenPaused {
    if (!paused) throw;
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



 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}



 
contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    if(rentrancy_lock == false) {
      rentrancy_lock = true;
      _;
      rentrancy_lock = false;
    } else {
      throw;
    }
  }

}

contract EtchReward is Pausable, BasicToken, ReentrancyGuard {

     
     
     
     
     

     
     
     
    string public constant name   = "Etch Reward Token";
    string public constant symbol = "ETCHR";
    uint public constant decimals = 18;

     
     
     
    address public constant BENEFICIARY = 0x651A3731f717a17777c9D8d6f152Aa9284978Ea3;

     
    uint public constant PRICE = 8;

     
    uint public constant AVG_BLOCKS_24H = 5023;   
    uint public constant AVG_BLOCKS_02W = 70325;  

    uint public constant MAX_ETHER_24H = 40 ether;
    uint public constant ETHER_CAP     = 2660 ether;

    uint public totalEther = 0;
    uint public blockStart = 0;
    uint public block24h   = 0;
    uint public block02w   = 0;

     
    address public icoContract = 0x0;

     
     
     
    mapping(address => bool) contributors;


     
    function EtchReward(uint _blockStart) {
        blockStart  = _blockStart;
        block24h = blockStart + AVG_BLOCKS_24H;
        block02w = blockStart + AVG_BLOCKS_02W;
    }

     
     
     
    function transfer(address, uint) {
        throw;
    }

     
     
     
    function () payable {
        buy();
    }

     
     
     
    modifier onlyContributors() {
        if(contributors[msg.sender] != true) {
            throw;
        }
        _;
    }

    modifier onlyIcoContract() {
        if(icoContract == 0x0 || msg.sender != icoContract) {
            throw;
        }
        _;
    }

     
     
     
     
    function addContributor(address _who) public onlyOwner {
        contributors[_who] = true;
    }

     
    function isContributor(address _who) public constant returns(bool) {
        return contributors[_who];
    }

     
     
     
    function setIcoContract(address _contract) public onlyOwner {
        icoContract = _contract;
    }

     
     
     
    function migrate(address _contributor) public
    onlyIcoContract
    whenNotPaused {

        if(getBlock() < block02w) {
            throw;
        }
        totalSupply = totalSupply.sub(balances[_contributor]);
        balances[_contributor] = 0;
    }

    function buy() payable
    nonReentrant
    onlyContributors
    whenNotPaused {

        address _recipient = msg.sender;
        uint blockNow = getBlock();

         
        if(blockNow < blockStart || block02w <= blockNow) {
            throw;
        }

        if (blockNow < block24h) {

             
            if (balances[_recipient] > 0) {
                throw;
            }

             
            if (msg.value > MAX_ETHER_24H) {
                throw;
            }
        }

         
        if (totalEther.add(msg.value) > ETHER_CAP) {
            throw;
        }

        uint tokens = msg.value.mul(PRICE);
        totalSupply = totalSupply.add(tokens);

        balances[_recipient] = balances[_recipient].add(tokens);
        totalEther.add(msg.value);

        if (!BENEFICIARY.send(msg.value)) {
            throw;
        }
    }

    function getBlock() public constant returns (uint) {
        return block.number;
    }

}