 

pragma solidity ^0.4.23;
 
 
 
contract WhiteListedBasic {
    function addWhiteListed(address[] addrs) external;
    function removeWhiteListed(address addr) external;
    function isWhiteListed(address addr) external view returns (bool);
}
contract OperatableBasic {
    function setMinter (address addr) external;
    function setWhiteLister (address addr) external;
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

contract Operatable is Claimable, OperatableBasic {
    address public minter;
    address public whiteLister;
    address public launcher;

    event NewMinter(address newMinter);
    event NewWhiteLister(address newwhiteLister);

    modifier canOperate() {
        require(msg.sender == minter || msg.sender == whiteLister || msg.sender == owner);
        _;
    }

    constructor() public {
        minter = owner;
        whiteLister = owner;
        launcher = owner;
    }

    function setMinter (address addr) external onlyOwner {
        minter = addr;
        emit NewMinter(minter);
    }

    function setWhiteLister (address addr) external onlyOwner {
        whiteLister = addr;
        emit NewWhiteLister(whiteLister);
    }

    modifier ownerOrMinter()  {
        require ((msg.sender == minter) || (msg.sender == owner));
        _;
    }

    modifier onlyLauncher()  {
        require (msg.sender == launcher);
        _;
    }

    modifier onlyWhiteLister()  {
        require (msg.sender == whiteLister);
        _;
    }
}
contract WhiteListed is Operatable, WhiteListedBasic {


    uint public count;
    mapping (address => bool) public whiteList;

    event Whitelisted(address indexed addr, uint whitelistedCount, bool isWhitelisted);

    function addWhiteListed(address[] addrs) external canOperate {
        uint c = count;
        for (uint i = 0; i < addrs.length; i++) {
            if (!whiteList[addrs[i]]) {
                whiteList[addrs[i]] = true;
                c++;
                emit Whitelisted(addrs[i], count, true);
            }
        }
        count = c;
    }

    function removeWhiteListed(address addr) external canOperate {
        require(whiteList[addr]);
        whiteList[addr] = false;
        count--;
        emit Whitelisted(addr, count, false);
    }

    function isWhiteListed(address addr) external view returns (bool) {
        return whiteList[addr];
    }
}