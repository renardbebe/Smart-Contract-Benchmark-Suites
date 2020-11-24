 

pragma solidity ^0.4.24;

 
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
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



contract Token {
    function balanceOf(address _owner) public constant returns (uint256);
}

contract FactoryData is Ownable {
    using SafeMath for uint256;
    struct CP {
        string refNumber;
        string name;
        mapping(address => bool) factories;
    }

    uint256 blocksquareFee = 20;
    uint256 networkReserveFundFee = 50;
    uint256 cpFee = 15;
    uint256 firstBuyersFee = 15;

     
    mapping(address => mapping(address => bool)) whitelisted;
    mapping(string => address) countryFactory;
    mapping(address => bool) memberOfBS;
    mapping(address => uint256) requiredBST;
    mapping(address => CP) CPs;
    mapping(address => address) noFeeTransfersAccounts;
    mapping(address => bool) prestigeAddress;
    Token BST;

     
    constructor() public {
        memberOfBS[msg.sender] = true;
        owner = msg.sender;
        BST = Token(0x509A38b7a1cC0dcd83Aa9d06214663D9eC7c7F4a);
    }

     
    function addFactory(string _country, address _factory) public onlyOwner {
        countryFactory[_country] = _factory;
    }

     
    function addMemberToBS(address _member) public onlyOwner {
        memberOfBS[_member] = true;
    }

     
    function createCP(address _cp, string _refNumber, string _name) public onlyOwner {
        CP memory cp = CP(_refNumber, _name);
        CPs[_cp] = cp;
    }

     
    function addFactoryToCP(address _cp, address _factory) public onlyOwner {
        CP storage cp = CPs[_cp];
        cp.factories[_factory] = true;
    }

     
    function removeCP(address _cp, address _factory) public onlyOwner {
        CP storage cp = CPs[_cp];
        cp.factories[_factory] = false;
    }

     
    function addNoFeeAddress(address[] _from, address[] _to) public onlyOwner {
        require(_from.length == _to.length);
        for (uint256 i = 0; i < _from.length; i++) {
            noFeeTransfersAccounts[_from[i]] = _to[i];
            noFeeTransfersAccounts[_to[i]] = _from[i];
        }
    }

     
    function changeBSTRequirement(address _factory, uint256 _amount) public onlyOwner {
        requiredBST[_factory] = _amount * 10 ** 18;
    }

     
    function addToWhitelist(address _factory, address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_factory][_addresses[i]] = true;
        }
    }

     
    function removeFromWhitelist(address _factory, address _user) public onlyOwner {
        whitelisted[_factory][_user] = false;
    }

    function changeFees(uint256 _network, uint256 _blocksquare, uint256 _cp, uint256 _firstBuyers) public onlyOwner {
        require(_network.add(_blocksquare).add(_cp).add(_firstBuyers) == 100);
        blocksquareFee = _network;
        networkReserveFundFee = _blocksquare;
        cpFee = _cp;
        firstBuyersFee = _firstBuyers;
    }

    function changePrestige(address _owner) public onlyOwner {
        prestigeAddress[_owner] = !prestigeAddress[_owner];
    }

     
    function isWhitelisted(address _factory, address _user) public constant returns (bool) {
        return whitelisted[_factory][_user];
    }

     
    function getFactoryForCountry(string _country) public constant returns (address) {
        return countryFactory[_country];
    }

     
    function isBS(address _member) public constant returns (bool) {
        return memberOfBS[_member];
    }

     
    function hasEnoughBST(address _factory, address _address) constant public returns (bool) {
        return BST.balanceOf(_address) >= requiredBST[_factory];
    }

     
    function amountOfBSTRequired(address _factory) constant public returns (uint256) {
        return requiredBST[_factory];
    }

     
    function canCPCreateInFactory(address _cp, address _factory) constant public returns (bool) {
        return CPs[_cp].factories[_factory];
    }

     
    function getCP(address _cp) constant public returns (string, string) {
        return (CPs[_cp].refNumber, CPs[_cp].name);
    }

     
    function canMakeNoFeeTransfer(address _from, address _to) constant public returns (bool) {
        return noFeeTransfersAccounts[_from] == _to;
    }

    function getNetworkFee() public constant returns (uint256) {
        return networkReserveFundFee;
    }

    function getBlocksquareFee() public constant returns (uint256) {
        return blocksquareFee;
    }

    function getCPFee() public constant returns (uint256) {
        return cpFee;
    }

    function getFirstBuyersFee() public constant returns (uint256) {
        return firstBuyersFee;
    }

    function hasPrestige(address _owner) public constant returns(bool) {
        return prestigeAddress[_owner];
    }
}