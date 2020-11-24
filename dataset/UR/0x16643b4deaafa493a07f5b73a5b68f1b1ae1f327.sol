 

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



contract Curatable is Ownable {
  address public curator;


  event CurationRightsTransferred(address indexed previousCurator, address indexed newCurator);


   
  function Curatable() public {
    owner = msg.sender;
    curator = owner;
  }


   
  modifier onlyCurator() {
    require(msg.sender == curator);
    _;
  }


   
  function transferCurationRights(address newCurator) public onlyOwner {
    require(newCurator != address(0));
    CurationRightsTransferred(curator, newCurator);
    curator = newCurator;
  }

}

contract Whitelist is Curatable {
    mapping (address => bool) public whitelist;


    function Whitelist() public {
    }


    function addInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && !whitelist[investor]);
        whitelist[investor] = true;
    }


    function removeInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && whitelist[investor]);
        whitelist[investor] = false;
    }


    function isWhitelisted(address investor) constant external returns (bool result) {
        return whitelist[investor];
    }

}