 

pragma solidity ^0.4.24;

 
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


contract Blocksquare {
    function transfer(address _to, uint256 _amount) public returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success);
}

contract Data {
    function isBS(address _member) public constant returns (bool);
    function getCP(address _cp) constant public returns (string, string);
    function canMakeNoFeeTransfer(address _from, address _to) constant public returns (bool);
}

contract Whitelist {
    function isWhitelisted(address _user) public constant returns (bool);
}

contract PropTokenRENT is Ownable {
    using SafeMath for uint256;

    Blocksquare BST;
    Data data;
    Whitelist whitelist;
    mapping(address => mapping(address => uint256)) rentAmountPerToken;

    constructor() public {
        BST = Blocksquare(0x509A38b7a1cC0dcd83Aa9d06214663D9eC7c7F4a);
        data = Data(0x146d589cfe136644bdF4f1958452B5a4Bb9c5A05);
        whitelist = Whitelist(0xCB641F6B46e1f2970dB003C19515018D0338550a);
    }

    function compare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function equal(string _a, string _b) pure internal returns (bool) {
        return compare(_a, _b) == 0;
    }

    modifier canAddRent() {
        (string memory ref, string memory name) = data.getCP(msg.sender);
        require(data.isBS(msg.sender) || (!equal(ref, "") && !equal(name, "")));
        _;
    }

    function addRentToAddressForToken(address _token, address[] _addresses, uint256[] _amount) public canAddRent {
        require(_addresses.length == _amount.length);
        uint256 amountToPay = 0;
        for(uint256 i = 0; i < _addresses.length; i++) {
            rentAmountPerToken[_token][_addresses[i]] = rentAmountPerToken[_token][_addresses[i]].add(_amount[i]);
            amountToPay = amountToPay.add(_amount[i]);
        }
        BST.transferFrom(msg.sender, address(this), amountToPay);
    }

    function claimRentForToken(address _token, address _holdingWallet) public {
        require(whitelist.isWhitelisted(msg.sender) && whitelist.isWhitelisted(_holdingWallet));
        uint256 rent = rentAmountPerToken[_token][msg.sender];
        rentAmountPerToken[_token][msg.sender] = 0;
         
        if(msg.sender != _holdingWallet) {
            require(data.canMakeNoFeeTransfer(msg.sender, _holdingWallet));
            rent = rent.add(rentAmountPerToken[_token][_holdingWallet]);
            rentAmountPerToken[_token][_holdingWallet] = 0;
        }

        BST.transfer(msg.sender, rent);
    }

    function claimBulkRentForTokens(address[] _token, address _holdingWallet) public {
        require(whitelist.isWhitelisted(msg.sender) && whitelist.isWhitelisted(_holdingWallet));
        require(_token.length < 11);
        if(msg.sender != _holdingWallet) {
            require(data.canMakeNoFeeTransfer(msg.sender, _holdingWallet));
        }
        uint256 rent = 0;
        for(uint256 i = 0; i < _token.length; i++) {
            rent = rent.add(rentAmountPerToken[_token[i]][msg.sender]);
            rentAmountPerToken[_token[i]][msg.sender] = 0;

            rent = rent.add(rentAmountPerToken[_token[i]][_holdingWallet]);
            rentAmountPerToken[_token[i]][_holdingWallet] = 0;
        }

        BST.transfer(msg.sender, rent);
    }

    function pendingBSTForToken(address _token, address _user) public constant returns(uint256) {
        return rentAmountPerToken[_token][_user];
    }
}