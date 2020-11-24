 

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

 
contract PNS {

    using SafeMath for uint256; 

     
    event Register(address indexed _from, string _mfr, bytes32 _mid);

     
    event Transfer(address indexed _from, string _mfr, bytes32 _mid, address _owner);

     
    event Push(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

     
    event SetBn(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

     
    event SetKey(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

     
    event Lock(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

     
    struct Manufacturer {
        address owner;  
        string mfr;  
        mapping (bytes32 => Batch) batchmapping;  
        mapping (uint256 => bytes32) bidmapping;  
        uint256 bidcounter;  
    }

     
    struct Batch {
        string bn;  
        bytes key;  
        bool lock;  
    }

     
    mapping (bytes32 => Manufacturer) internal mfrmapping;

     
    mapping (uint256 => bytes32) internal midmapping;

     
    uint256 internal midcounter;
    
     
    function register(string _mfr) public returns (bytes32) {
        require(lengthOf(_mfr) > 0);
        require(msg.sender != address(0));

        bytes32 mid = keccak256(bytes(uppercaseOf(_mfr)));
        require(mfrmapping[mid].owner == address(0));

        midcounter = midcounter.add(1);
        midmapping[midcounter] = mid;

        mfrmapping[mid].owner = msg.sender;
        mfrmapping[mid].mfr = _mfr;
        
        emit Register(msg.sender, _mfr, mid);

        return mid;
    }

     
    function transfer(bytes32 _mid, address _owner) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_owner != address(0));

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        mfrmapping[_mid].owner = _owner;

        emit Transfer(msg.sender, mfrmapping[_mid].mfr, _mid, _owner);

        return _mid;
    }
    
     
    function push(bytes32 _mid, string _bn, bytes _key) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(lengthOf(_bn) > 0);
        require(_key.length == 33 || _key.length == 65);

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        bytes32 bid = keccak256(bytes(_bn));
        require(lengthOf(mfrmapping[_mid].batchmapping[bid].bn) == 0);
        require(mfrmapping[_mid].batchmapping[bid].key.length == 0);
        require(mfrmapping[_mid].batchmapping[bid].lock == false);

        mfrmapping[_mid].bidcounter = mfrmapping[_mid].bidcounter.add(1);
        mfrmapping[_mid].bidmapping[mfrmapping[_mid].bidcounter] = bid;
        mfrmapping[_mid].batchmapping[bid].bn = _bn;
        mfrmapping[_mid].batchmapping[bid].key = _key;
        mfrmapping[_mid].batchmapping[bid].lock = false;

        emit Push(msg.sender, mfrmapping[_mid].mfr, _mid, _bn, bid, _key);

        return bid;
    }

     
    function setBn(bytes32 _mid, bytes32 _bid, string _bn) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_bid != bytes32(0));
        require(lengthOf(_bn) > 0);

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        bytes32 bid = keccak256(bytes(_bn));
        require(bid != _bid);
        require(lengthOf(mfrmapping[_mid].batchmapping[_bid].bn) > 0);
        require(mfrmapping[_mid].batchmapping[_bid].key.length > 0);
        require(mfrmapping[_mid].batchmapping[_bid].lock == false);
        require(lengthOf(mfrmapping[_mid].batchmapping[bid].bn) == 0);
        require(mfrmapping[_mid].batchmapping[bid].key.length == 0);
        require(mfrmapping[_mid].batchmapping[bid].lock == false);

        uint256 counter = 0;
        for (uint256 i = 1; i <= mfrmapping[_mid].bidcounter; i++) {
            if (mfrmapping[_mid].bidmapping[i] == _bid) {
                counter = i;
                break;
            }
        }
        require(counter > 0);

        mfrmapping[_mid].bidmapping[counter] = bid;
        mfrmapping[_mid].batchmapping[bid].bn = _bn;
        mfrmapping[_mid].batchmapping[bid].key = mfrmapping[_mid].batchmapping[_bid].key;
        mfrmapping[_mid].batchmapping[bid].lock = false;
        delete mfrmapping[_mid].batchmapping[_bid];

        emit SetBn(msg.sender, mfrmapping[_mid].mfr, _mid, _bn, bid, mfrmapping[_mid].batchmapping[bid].key);

        return bid;
    }

     
    function setKey(bytes32 _mid, bytes32 _bid, bytes _key) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_bid != bytes32(0));
        require(_key.length == 33 || _key.length == 65);

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        require(lengthOf(mfrmapping[_mid].batchmapping[_bid].bn) > 0);
        require(mfrmapping[_mid].batchmapping[_bid].key.length > 0);
        require(mfrmapping[_mid].batchmapping[_bid].lock == false);

        mfrmapping[_mid].batchmapping[_bid].key = _key;

        emit SetKey(msg.sender, mfrmapping[_mid].mfr, _mid, mfrmapping[_mid].batchmapping[_bid].bn, _bid, _key);

        return _bid;
    }

     
    function lock(bytes32 _mid, bytes32 _bid) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_bid != bytes32(0));

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        require(lengthOf(mfrmapping[_mid].batchmapping[_bid].bn) > 0);
        require(mfrmapping[_mid].batchmapping[_bid].key.length > 0);

        mfrmapping[_mid].batchmapping[_bid].lock = true;

        emit Lock(msg.sender, mfrmapping[_mid].mfr, _mid, mfrmapping[_mid].batchmapping[_bid].bn, _bid, mfrmapping[_mid].batchmapping[_bid].key);

        return _bid;
    }

     
    function check(bytes32 _mid, bytes32 _bid, bytes _key) public view returns (bool) {
        if (mfrmapping[_mid].batchmapping[_bid].key.length != _key.length) {
            return false;
        }
        for (uint256 i = 0; i < _key.length; i++) {
            if (mfrmapping[_mid].batchmapping[_bid].key[i] != _key[i]) {
                return false;
            }
        }
        return true;
    }

     
    function totalMfr() public view returns (uint256) {
        return midcounter;
    }

     
    function midOf(uint256 _midcounter) public view returns (bytes32) {
        return midmapping[_midcounter];
    }

     
    function ownerOf(bytes32 _mid) public view returns (address) {
        return mfrmapping[_mid].owner;
    }
    
     
    function mfrOf(bytes32 _mid) public view returns (string) {
        return mfrmapping[_mid].mfr;
    }
    
     
    function totalBatchOf(bytes32 _mid) public view returns (uint256) {
        return mfrmapping[_mid].bidcounter;
    }

     
    function bidOf(bytes32 _mid, uint256 _bidcounter) public view returns (bytes32) {
        return mfrmapping[_mid].bidmapping[_bidcounter];
    }

     
    function bnOf(bytes32 _mid, bytes32 _bid) public view returns (string) {
        return mfrmapping[_mid].batchmapping[_bid].bn;
    }
    
     
    function keyOf(bytes32 _mid, bytes32 _bid) public view returns (bytes) {
        if (mfrmapping[_mid].batchmapping[_bid].lock == true) {
            return mfrmapping[_mid].batchmapping[_bid].key;
        }
    }

     
    function uppercaseOf(string _s) internal pure returns (string) {
        bytes memory b1 = bytes(_s);
        uint256 l = b1.length;
        bytes memory b2 = new bytes(l);
        for (uint256 i = 0; i < l; i++) {
            if (b1[i] >= 0x61 && b1[i] <= 0x7A) {
                b2[i] = bytes1(uint8(b1[i]) - 32);
            } else {
                b2[i] = b1[i];
            }
        }
        return string(b2);
    }

     
    function lengthOf(string _s) internal pure returns (uint256) {
        return bytes(_s).length;
    }
}