 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

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

contract OperatableBasic {
    function setPrimaryOperator (address addr) public;
    function setSecondaryOperator (address addr) public;
    function isPrimaryOperator(address addr) public view returns (bool);
    function isSecondaryOperator(address addr) public view returns (bool);
}

contract Operatable is Ownable, OperatableBasic {
    address public primaryOperator;
    address public secondaryOperator;

    modifier canOperate() {
        require(msg.sender == primaryOperator || msg.sender == secondaryOperator || msg.sender == owner);
        _;
    }

    function Operatable() public {
        primaryOperator = owner;
        secondaryOperator = owner;
    }

    function setPrimaryOperator (address addr) public onlyOwner {
        primaryOperator = addr;
    }

    function setSecondaryOperator (address addr) public onlyOwner {
        secondaryOperator = addr;
    }

    function isPrimaryOperator(address addr) public view returns (bool) {
        return (addr == primaryOperator);
    }

    function isSecondaryOperator(address addr) public view returns (bool) {
        return (addr == secondaryOperator);
    }
}

contract WhiteListedBasic is OperatableBasic {
    function addWhiteListed(address[] addrs, uint[] batches, uint[] weiAllocation) external;
    function getAllocated(address addr) public view returns (uint);
    function getBatchNumber(address addr) public view returns (uint);
    function getWhiteListCount() public view returns (uint);
    function isWhiteListed(address addr) public view returns (bool);
    function removeWhiteListed(address addr) public;
    function setAllocation(address[] addrs, uint[] allocation) public;
    function setBatchNumber(address[] addrs, uint[] batch) public;
}

contract WhiteListed is Operatable, WhiteListedBasic {

    struct Batch {
        bool isWhitelisted;
        uint weiAllocated;
        uint batchNumber;
    }

    uint public count;
    mapping (address => Batch) public batchMap;

    event Whitelisted(address indexed addr, uint whitelistedCount, bool isWhitelisted, uint indexed batch, uint weiAllocation);

    function addWhiteListed(address[] addrs, uint[] batches, uint[] weiAllocation) external canOperate {
        require(addrs.length == batches.length);
        require(addrs.length == weiAllocation.length);
        for (uint i = 0; i < addrs.length; i++) {
            Batch storage batch = batchMap[addrs[i]];
            if (batch.isWhitelisted != true) {
                batch.isWhitelisted = true;
                batch.weiAllocated = weiAllocation[i];
                batch.batchNumber = batches[i];
                count++;
                Whitelisted(addrs[i], count, true, batches[i], weiAllocation[i]);
            }
        }
    }

    function getAllocated(address addr) public view returns (uint) {
        return batchMap[addr].weiAllocated;
    }

    function getBatchNumber(address addr) public view returns (uint) {
        return batchMap[addr].batchNumber;
    }

    function getWhiteListCount() public view returns (uint) {
        return count;
    }

    function isWhiteListed(address addr) public view returns (bool) {
        return batchMap[addr].isWhitelisted;
    }

    function removeWhiteListed(address addr) public canOperate {
        Batch storage batch = batchMap[addr];
        require(batch.isWhitelisted == true); 
        batch.isWhitelisted = false;
        count--;
        Whitelisted(addr, count, false, batch.batchNumber, batch.weiAllocated);
    }

    function setAllocation(address[] addrs, uint[] weiAllocation) public canOperate {
        require(addrs.length == weiAllocation.length);
        for (uint i = 0; i < addrs.length; i++) {
            if (batchMap[addrs[i]].isWhitelisted == true) {
                batchMap[addrs[i]].weiAllocated = weiAllocation[i];
            }
        }
    }

    function setBatchNumber(address[] addrs, uint[] batch) public canOperate {
        require(addrs.length == batch.length);
        for (uint i = 0; i < addrs.length; i++) {
            if (batchMap[addrs[i]].isWhitelisted == true) {
                batchMap[addrs[i]].batchNumber = batch[i];
            }
        }
    }
}