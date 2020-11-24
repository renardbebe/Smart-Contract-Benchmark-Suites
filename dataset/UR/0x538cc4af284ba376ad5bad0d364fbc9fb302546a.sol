 

 

pragma solidity ^0.5.2;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EtherPornStars is Ownable {
  using SafeMath for uint256;
  address payable public ownerAddress;
  bool public commFree;
  uint customComm;
  uint vidComm;
  uint tipComm;
     
  uint8 constant playerMessageMaxLength = 64;
  mapping(address => userAccount) public user;
  mapping (uint => address payable) public star;
  mapping (uint => uint) public referrer;
  event VideoBought(uint _buyerId, uint _videoId, uint _value, uint _refstarId);
  event Funded(uint _buyerId, uint _starId, string _message, uint _value, uint _refstarId);
  event Tipped(uint _buyerId, uint _starId, uint _value);
  event PrivateShow(uint _buyerId, uint _starId, uint _value);
  event SubscriptionBought(uint _buyerId, uint _starId, uint _tier, uint _value);
  event StoreItemBought(uint _buyerId, uint _starId, uint _itemId, uint _value, uint _refstarId);
  event CustomVidBought(uint _buyerId, uint _starId,  uint _cid, uint _value);
  event PremiumBought(uint _buyerId, uint _value);
  struct userAccount {
    uint[] vidsOwned;
    uint[3][] subscriptions;
    uint epsPremium;
  }
  
  constructor() public {
      commFree = true;
      customComm = 10;
      vidComm = 10;
      tipComm = 5;
      ownerAddress = msg.sender;
  }

  function tipStar(uint _buyerId, uint _starId) public payable {
      require(msg.value >= 10000000000000000);
      uint _commission = msg.value.div(tipComm);
      uint _starShare = msg.value-_commission;
      address payable starAddress = star[_starId];
      require(starAddress != address(0));
      starAddress.transfer(_starShare);
      ownerAddress.transfer(_commission);
      emit Tipped(_buyerId, _starId, msg.value);
  }
  
    function fundStar(uint _buyerId, uint _starId, string memory _message) public payable {
      bytes memory _messageBytes = bytes(_message);
      require(msg.value >= 10000000000000000);
      require(_messageBytes.length <= playerMessageMaxLength, "Too long");
      uint _commission = msg.value.div(tipComm);
      address payable _referrerAddress;
      uint _referralShare;
      if (referrer[_starId] != 0) {
          _referrerAddress = star[referrer[_starId]];
          _referralShare = msg.value.div(5);
      }
      uint _starShare = msg.value - _commission - _referralShare;
      address payable _starAddress = star[_starId];
      require(_starAddress != address(0));
      _starAddress.transfer(_starShare);
      _referrerAddress.transfer(_referralShare);
      ownerAddress.transfer(_commission);
      emit Funded(_buyerId, _starId, _message, msg.value, referrer[_starId]);
  }
  
    function buyPrivateShow(uint _buyerId, uint _starId) public payable {
      require(msg.value >= 10000000000000000);
      uint _commission = msg.value.div(vidComm);
      uint _starShare = msg.value-_commission;
      address payable starAddress = star[_starId];
      require(starAddress != address(0));
      starAddress.transfer(_starShare);
      ownerAddress.transfer(_commission);
      emit PrivateShow(_buyerId, _starId, msg.value);
  }
  
  function buySub(uint _buyerId, uint _starId, uint _tier) public payable {
    require(msg.value >= 10000000000000000);
    require(_tier > 0 && _buyerId > 0);
    uint _commission = msg.value.div(vidComm);
    uint _starShare = msg.value-_commission;
    address payable _starAddress = star[_starId];
    require(_starAddress != address(0));
    _starAddress.transfer(_starShare);
    ownerAddress.transfer(_commission);
    user[msg.sender].subscriptions.push([_starId,_tier, msg.value]);
    emit SubscriptionBought(_buyerId, _starId, _tier, msg.value);
  }
  
  function buyVid(uint _buyerId, uint _videoId, uint _starId) public payable {
    require(msg.value >= 10000000000000000);
    uint _commission = msg.value.div(vidComm);
    if(commFree){
        _commission = 0;
    }
    address payable _referrerAddress;
    uint _referralShare;
    if (referrer[_starId] != 0) {
          _referrerAddress = star[referrer[_starId]];
          _referralShare = msg.value.div(5);
      }
    uint _starShare = msg.value- _commission - _referralShare;
    address payable _starAddress = star[_starId];
    require(_starAddress != address(0));
    _starAddress.transfer(_starShare);
    _referrerAddress.transfer(_referralShare);
    ownerAddress.transfer(_commission);
    user[msg.sender].vidsOwned.push(_videoId);
    emit VideoBought(_buyerId, _videoId, msg.value, referrer[_starId]);
  }

  function buyStoreItem(uint _buyerId, uint _itemId, uint _starId) public payable {
    require(msg.value >= 10000000000000000);
    require(_itemId > 0 && _buyerId > 0);
    uint _commission = msg.value.div(vidComm);
    if(commFree){
        _commission = 0;
    }
    uint _referralShare;
    address payable _referrerAddress;
    if (referrer[_starId] != 0) {
          _referrerAddress = star[referrer[_starId]];
          _referralShare = msg.value.div(5);
      }
    uint _starShare = msg.value- _commission-_referralShare;
    address payable _starAddress = star[_starId];
    require(_starAddress != address(0));
    _starAddress.transfer(_starShare);
    _referrerAddress.transfer(_referralShare);
    ownerAddress.transfer(_commission);
    emit StoreItemBought(_buyerId, _starId, _itemId,  msg.value, referrer[_starId]);
  }
  
  function buyPremium(uint _buyerId) public payable {
    require(msg.value >= 10000000000000000);
    ownerAddress.transfer(msg.value);
    emit PremiumBought(_buyerId, msg.value);
  }
  
    function buyCustomVid(uint _buyerId, uint _starId, uint _cid) public payable {
    require(msg.value >= 10000000000000000);
    uint _commission = msg.value.div(customComm);
    if(commFree){
        _commission = 0;
    }
    uint _starShare = msg.value - _commission;
    address payable _starAddress = star[_starId];
    require(_starAddress != address(0));
    _starAddress.transfer(_starShare);
    ownerAddress.transfer(_commission);
    emit CustomVidBought(_buyerId, _starId, _cid, msg.value);
  }
  
  function addStar(uint _starId, address payable _starAddress) public onlyOwner {
    star[_starId] = _starAddress;
  }

  function addReferrer(uint _starId, uint _referrerId) public onlyOwner {
    referrer[_starId] = _referrerId;
  }
  
  function commission(bool _commFree, uint _customcomm, uint _vidcomm, uint _tipcomm) public onlyOwner {
    commFree = _commFree;
    customComm = _customcomm;
    vidComm = _vidcomm;
    tipComm = _tipcomm;
  }
}