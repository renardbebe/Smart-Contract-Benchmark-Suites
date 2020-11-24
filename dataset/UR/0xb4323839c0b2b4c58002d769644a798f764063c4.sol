 

pragma solidity ^0.4.24;

 

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract BookingPoC is Ownable {

  using SafeMath for uint256;
  using ECRecovery for bytes32;

   
  address public offerSigner;

   
  uint256 public endBookings;

   
   
   
  struct Booking {
    address guest;
    bytes32 bookingHash;
    uint256 payed;
    bool isEther;
  }
  struct RoomType {
    uint256 totalRooms;
    mapping(uint256 => mapping(uint256 => Booking)) nights;
  }
  mapping(string => RoomType) rooms;

   
  struct Refund {
    uint256 beforeTime;
    uint8 dividedBy;
  }
  Refund[] public refunds;

   
  uint256 public totalNights;

   
  ERC20 public lifToken;

  event BookingCanceled(
    string roomType, uint256[] nights, uint256 room,
    address newGuest, bytes32 bookingHash
  );

  event BookingChanged(
    string roomType, uint256[] nights, uint256 room,
    address newGuest, bytes32 bookingHash
  );

  event BookingDone(
    string roomType, uint256[] nights, uint256 room,
    address guest, bytes32 bookingHash
  );

  event RoomsAdded(string roomType, uint256 newRooms);

   
  constructor(
    address _offerSigner, address _lifToken,
    uint256 _totalNights, uint256 _endBookings
  ) public {
    require(_offerSigner != address(0));
    require(_lifToken != address(0));
    require(_totalNights > 0);
    require(_endBookings > now);
    offerSigner = _offerSigner;
    lifToken = ERC20(_lifToken);
    totalNights = _totalNights;
    endBookings = _endBookings;
  }

   
  function edit(address _offerSigner, address _lifToken) onlyOwner public {
    require(_offerSigner != address(0));
    require(_lifToken != address(0));
    offerSigner = _offerSigner;
    lifToken = ERC20(_lifToken);
  }

   
  function addRefund(uint256 _beforeTime, uint8 _dividedBy) onlyOwner public {
    if (refunds.length > 0)
      require(refunds[refunds.length-1].beforeTime > _beforeTime);
    refunds.push(Refund(_beforeTime, _dividedBy));
  }

   
  function changeRefund(
    uint8 _refundIndex, uint256 _beforeTime, uint8 _dividedBy
  ) onlyOwner public {
    if (_refundIndex > 0)
      require(refunds[_refundIndex-1].beforeTime > _beforeTime);
    refunds[_refundIndex].beforeTime = _beforeTime;
    refunds[_refundIndex].dividedBy = _dividedBy;
  }

   
  function addRooms(string roomType, uint256 amount) onlyOwner public {
    rooms[roomType].totalRooms = rooms[roomType].totalRooms.add(amount);
    emit RoomsAdded(roomType, amount);
  }

   
  function bookRoom(
    string roomType, uint256[] _nights, uint256 room,
    address guest, bytes32 bookingHash, uint256 weiPerNight, bool isEther
  ) internal {
    for (uint i = 0; i < _nights.length; i ++) {
      rooms[roomType].nights[_nights[i]][room].guest = guest;
      rooms[roomType].nights[_nights[i]][room].bookingHash = bookingHash;
      rooms[roomType].nights[_nights[i]][room].payed = weiPerNight;
      rooms[roomType].nights[_nights[i]][room].isEther = isEther;
    }
    emit BookingDone(roomType, _nights, room, guest, bookingHash);
  }

  event log(uint256 msg);

   
  function cancelBooking(
    string roomType, uint256[] _nights,
    uint256 room, bytes32 bookingHash, bool isEther
  ) public {

     
    uint256 totalPayed = 0;
    for (uint i = 0; i < _nights.length; i ++) {
      require(rooms[roomType].nights[_nights[i]][room].guest == msg.sender);
      require(rooms[roomType].nights[_nights[i]][room].isEther == isEther);
      require(rooms[roomType].nights[_nights[i]][room].bookingHash == bookingHash);
      totalPayed = totalPayed.add(
        rooms[roomType].nights[_nights[i]][room].payed
      );
      delete rooms[roomType].nights[_nights[i]][room];
    }

     
    uint256 refundAmount = 0;
    for (i = 0; i < refunds.length; i ++) {
      if (now < endBookings.sub(refunds[i].beforeTime)){
        refundAmount = totalPayed.div(refunds[i].dividedBy);
        break;
      }
    }

     
    if (isEther)
      msg.sender.transfer(refundAmount);
    else
      lifToken.transfer(msg.sender, refundAmount);

    emit BookingCanceled(roomType, _nights, room, msg.sender, bookingHash);
  }

   
  function withdraw() public onlyOwner {
    require(now > endBookings);
    lifToken.transfer(owner, lifToken.balanceOf(address(this)));
    owner.transfer(address(this).balance);
  }

   
  function bookWithEth(
    uint256 pricePerNight,
    uint256 offerTimestamp,
    bytes offerSignature,
    string roomType,
    uint256[] _nights,
    bytes32 bookingHash
  ) public payable {
     
    require(offerTimestamp < now);
    require(now < endBookings);

     
    require(pricePerNight.mul(_nights.length) <= msg.value);

     
    uint256 available = firstRoomAvailable(roomType, _nights);
    require(available > 0);

     
    bytes32 priceSigned = keccak256(abi.encodePacked(
      roomType, pricePerNight, offerTimestamp, "eth", bookingHash
    )).toEthSignedMessageHash();
    require(offerSigner == priceSigned.recover(offerSignature));

     
    bookRoom(
      roomType, _nights, available, msg.sender,
      bookingHash, pricePerNight, true
    );
  }

   
  function bookWithLif(
    uint256 pricePerNight,
    uint256 offerTimestamp,
    bytes offerSignature,
    string roomType,
    uint256[] _nights,
    bytes32 bookingHash
  ) public {
     
    require(offerTimestamp < now);

     
    uint256 lifTokenAllowance = lifToken.allowance(msg.sender, address(this));
    require(pricePerNight.mul(_nights.length) <= lifTokenAllowance);

     
    uint256 available = firstRoomAvailable(roomType, _nights);
    require(available > 0);

     
    bytes32 priceSigned = keccak256(abi.encodePacked(
      roomType, pricePerNight, offerTimestamp, "lif", bookingHash
    )).toEthSignedMessageHash();
    require(offerSigner == priceSigned.recover(offerSignature));

     
    bookRoom(
      roomType, _nights, available, msg.sender,
      bookingHash, pricePerNight, false
    );

     
    lifToken.transferFrom(msg.sender, address(this), lifTokenAllowance);
  }

   
  function totalRooms(string roomType) view public returns (uint256) {
    return rooms[roomType].totalRooms;
  }

   
  function getBooking(
    string roomType, uint256 room, uint256 night
  ) view public returns (address, uint256, bytes32, bool) {
    return (
      rooms[roomType].nights[night][room].guest,
      rooms[roomType].nights[night][room].payed,
      rooms[roomType].nights[night][room].bookingHash,
      rooms[roomType].nights[night][room].isEther
    );
  }

   
  function roomAvailable(
    string roomType, uint256[] _nights, uint256 room
  ) view public returns (bool) {
    require(room <= rooms[roomType].totalRooms);
    for (uint i = 0; i < _nights.length; i ++) {
      require(_nights[i] <= totalNights);
      if (rooms[roomType].nights[_nights[i]][room].guest != address(0))
        return false;
      }
    return true;
  }

   
  function roomsAvailable(
    string roomType, uint256[] _nights
  ) view public returns (uint256[]) {
    require(_nights[i] <= totalNights);
    uint256[] memory available = new uint256[](rooms[roomType].totalRooms);
    for (uint z = 1; z <= rooms[roomType].totalRooms; z ++) {
      available[z-1] = z;
      for (uint i = 0; i < _nights.length; i ++)
        if (rooms[roomType].nights[_nights[i]][z].guest != address(0)) {
          available[z-1] = 0;
          break;
        }
    }
    return available;
  }

   
  function firstRoomAvailable(
    string roomType, uint256[] _nights
  ) internal returns (uint256) {
    require(_nights[i] <= totalNights);
    uint256 available = 0;
    bool isAvailable;
    for (uint z = rooms[roomType].totalRooms; z >= 1 ; z --) {
      isAvailable = true;
      for (uint i = 0; i < _nights.length; i ++) {
        if (rooms[roomType].nights[_nights[i]][z].guest != address(0))
          isAvailable = false;
          break;
        }
      if (isAvailable)
        available = z;
    }
    return available;
  }

}