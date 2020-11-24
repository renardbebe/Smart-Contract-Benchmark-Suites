 

pragma solidity ^0.4.0;


 


contract AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);

    event Transfer(bytes32 indexed node, address owner);
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

 
contract Deed {
    address public registrar;
    address constant burn = 0xdead;
    uint public creationDate;
    address public owner;
    address public previousOwner;
    uint public value;
    event OwnerChanged(address newOwner);
    event DeedClosed();
    bool active;


    modifier onlyRegistrar {
        if (msg.sender != registrar) throw;
        _;
    }

    modifier onlyActive {
        if (!active) throw;
        _;
    }

    function Deed(uint _value) {
        registrar = msg.sender;
        creationDate = now;
        active = true;
        value = _value;
    }
        
    function setOwner(address newOwner) onlyRegistrar {
         
        previousOwner = owner;
        owner = newOwner;
        OwnerChanged(newOwner);
    }

    function setRegistrar(address newRegistrar) onlyRegistrar {
        registrar = newRegistrar;
    }
    
    function setBalance(uint newValue) onlyRegistrar onlyActive payable {
         
        if (value < newValue) throw;
        value = newValue;
         
        if (!owner.send(this.balance - newValue)) throw;
    }

     
    function closeDeed(uint refundRatio) onlyRegistrar onlyActive {
        active = false;            
        if (! burn.send(((1000 - refundRatio) * this.balance)/1000)) throw;
        DeedClosed();
        destroyDeed();
    }    

     
    function destroyDeed() {
        if (active) throw;
        if(owner.send(this.balance))
            selfdestruct(burn);
    }

     
    function () payable {}
}

 
contract Registrar {
    AbstractENS public ens;
    bytes32 public rootNode;

    mapping (bytes32 => entry) _entries;
    mapping (address => mapping(bytes32 => Deed)) public sealedBids;
    
    enum Mode { Open, Auction, Owned, Forbidden, Reveal }
    uint32 constant auctionLength = 5 days;
    uint32 constant revealPeriod = 48 hours;
    uint32 constant initialAuctionPeriod = 4 weeks;
    uint constant minPrice = 0.01 ether;
    uint public registryStarted;

    event AuctionStarted(bytes32 indexed hash, uint registrationDate);
    event NewBid(bytes32 indexed hash, address indexed bidder, uint deposit);
    event BidRevealed(bytes32 indexed hash, address indexed owner, uint value, uint8 status);
    event HashRegistered(bytes32 indexed hash, address indexed owner, uint value, uint registrationDate);
    event HashReleased(bytes32 indexed hash, uint value);
    event HashInvalidated(bytes32 indexed hash, string indexed name, uint value, uint registrationDate);

    struct entry {
        Deed deed;
        uint registrationDate;
        uint value;
        uint highestBid;
    }

     
     
     
     
     
     
     
    function state(bytes32 _hash) constant returns (Mode) {
        var entry = _entries[_hash];
        if(now < entry.registrationDate) {
            if(now < entry.registrationDate - revealPeriod) {
                return Mode.Auction;
            } else {
                return Mode.Reveal;
            }
        } else {
            if(entry.highestBid == 0) {
                return Mode.Open;
            } else if(entry.deed == Deed(0)) {
                return Mode.Forbidden;
            } else {
                return Mode.Owned;
            }
        }
    }
    
    modifier inState(bytes32 _hash, Mode _state) {
        if(state(_hash) != _state) throw;
        _;
    }

    modifier onlyOwner(bytes32 _hash) {
        if (state(_hash) != Mode.Owned || msg.sender != _entries[_hash].deed.owner()) throw;
        _;
    }
    
    modifier registryOpen() {
        if(now < registryStarted  || now > registryStarted + 4 years) throw;
        _;
    }
    
    function entries(bytes32 _hash) constant returns (Mode, address, uint, uint, uint) {
        entry h = _entries[_hash];
        return (state(_hash), h.deed, h.registrationDate, h.value, h.highestBid);
    }
    
     
    function Registrar(address _ens, bytes32 _rootNode, uint _startDate) {
        ens = AbstractENS(_ens);
        rootNode = _rootNode;
        registryStarted = _startDate > 0 ? _startDate : now;
    }

     
    function max(uint a, uint b) internal constant returns (uint max) {
        if (a > b)
            return a;
        else
            return b;
    }

     
    function min(uint a, uint b) internal constant returns (uint min) {
        if (a < b)
            return a;
        else
            return b;
    }

     
    function strlen(string s) internal constant returns (uint) {
         
        uint ptr;
        uint end;
        assembly {
            ptr := add(s, 1)
            end := add(mload(s), ptr)
        }
        for (uint len = 0; ptr < end; len++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
        return len;
    }

         
    function startAuction(bytes32 _hash) inState(_hash, Mode.Open) registryOpen() {
        entry newAuction = _entries[_hash];

         
        newAuction.registrationDate = max(now + auctionLength, registryStarted + initialAuctionPeriod);
        newAuction.value = 0;
        newAuction.highestBid = 0;
        AuctionStarted(_hash, newAuction.registrationDate);      
    }

     
    function startAuctions(bytes32[] _hashes)  {
        for (uint i = 0; i < _hashes.length; i ++ ) {
            startAuction(_hashes[i]);
        }
    }
    
     
    function shaBid(bytes32 hash, address owner, uint value, bytes32 salt) constant returns (bytes32 sealedBid) {
        return sha3(hash, owner, value, salt);
    }
    
     
    function newBid(bytes32 sealedBid) payable {
        if (address(sealedBids[msg.sender][sealedBid]) > 0 ) throw;
        if (msg.value < minPrice) throw;
         
        Deed newBid = new Deed(msg.value);
        sealedBids[msg.sender][sealedBid] = newBid;
        NewBid(sealedBid, msg.sender, msg.value);

        if (!newBid.send(msg.value)) throw;
    } 

      
    function unsealBid(bytes32 _hash, address _owner, uint _value, bytes32 _salt) {
        bytes32 seal = shaBid(_hash, _owner, _value, _salt);
        Deed bid = sealedBids[msg.sender][seal];
        if (address(bid) == 0 ) throw;
        sealedBids[msg.sender][seal] = Deed(0);
        bid.setOwner(_owner);
        entry h = _entries[_hash];
        uint actualValue = min(_value, bid.value());
        bid.setBalance(actualValue);

        var auctionState = state(_hash);
        if(auctionState == Mode.Owned) {
             
            bid.closeDeed(5);
            BidRevealed(_hash, _owner, actualValue, 1);
        } else if(auctionState != Mode.Reveal) {
             
            throw;
        } else if (_value < minPrice) {
             
            bid.closeDeed(995);
            BidRevealed(_hash, _owner, actualValue, 0);
        } else if (_value > h.highestBid) {
             
             
            if(address(h.deed) != 0) {
                Deed previousWinner = h.deed;
                previousWinner.closeDeed(995);
            }
            
             
             
            h.value = h.highestBid;
            h.highestBid = actualValue;
            h.deed = bid;
            BidRevealed(_hash, _owner, actualValue, 2);
        } else if (_value > h.value) {
             
            h.value = actualValue;
            bid.closeDeed(995);
            BidRevealed(_hash, _owner, actualValue, 3);
        } else {
             
            bid.closeDeed(995);
            BidRevealed(_hash, _owner, actualValue, 4);
        }
    }
    
      
    function cancelBid(address bidder, bytes32 seal) {
        Deed bid = sealedBids[bidder][seal];
         
        if (address(bid) == 0 
            || now < bid.creationDate() + initialAuctionPeriod 
            || bid.owner() > 0) throw;

         
        bid.setOwner(msg.sender);
        bid.closeDeed(5);
        sealedBids[bidder][seal] = Deed(0);
        BidRevealed(seal, bidder, 0, 5);
    }

      
    function finalizeAuction(bytes32 _hash) onlyOwner(_hash) {
        entry h = _entries[_hash];

        h.value =  max(h.value, minPrice);

         
        ens.setSubnodeOwner(rootNode, _hash, h.deed.owner());

        Deed deedContract = h.deed;
        deedContract.setBalance(h.value);
        HashRegistered(_hash, deedContract.owner(), h.value, h.registrationDate);
    }

     
    function transfer(bytes32 _hash, address newOwner) onlyOwner(_hash) {
        entry h = _entries[_hash];
        h.deed.setOwner(newOwner);
        ens.setSubnodeOwner(rootNode, _hash, newOwner);
    }

     
    function releaseDeed(bytes32 _hash) onlyOwner(_hash) {
        entry h = _entries[_hash];
        Deed deedContract = h.deed;
        if (now < h.registrationDate + 1 years 
            || now > registryStarted + 8 years) throw;

        HashReleased(_hash, h.value);
        
        h.value = 0;
        h.highestBid = 0;
        h.deed = Deed(0);

        ens.setSubnodeOwner(rootNode, _hash, 0);
        deedContract.closeDeed(1000);
    }  

     
    function invalidateName(string unhashedName) inState(sha3(unhashedName), Mode.Owned) {
        if (strlen(unhashedName) > 6 ) throw;
        bytes32 hash = sha3(unhashedName);
        
        entry h = _entries[hash];
        ens.setSubnodeOwner(rootNode, hash, 0);
        if(address(h.deed) != 0) {
             
             
            h.deed.setBalance(h.deed.value()/2);
            h.deed.setOwner(msg.sender);
            h.deed.closeDeed(1000);
        }
        HashInvalidated(hash, unhashedName, h.value, h.registrationDate);
        h.deed = Deed(0);
    }

     
    function transferRegistrars(bytes32 _hash) onlyOwner(_hash) {
        var registrar = ens.owner(rootNode);
        if(registrar == address(this))
            throw;

        entry h = _entries[_hash];
        h.deed.setRegistrar(registrar);
    }
}