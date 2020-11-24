 

 
pragma solidity ^0.4.24;

 
 
 
 
 

 
 
 
 

 
 

 

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

 
 

 
 
 
 

 
 
 
 

 
 

 

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 
 

contract DSStop is DSNote, DSAuth {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 
 
 

interface DSValue {
    function peek() external returns (bytes32,bool);
    function read() external returns (bytes32);
}

contract OSM is DSAuth, DSStop {
    DSValue public src;
    
    uint16 constant ONE_HOUR = uint16(3600);

    uint16 public hop = ONE_HOUR;
    uint64 public zzz;

    struct Feed {
        uint128 val;
        bool    has;
    }

    Feed cur;
    Feed nxt;

    event LogValue(bytes32 val);
    
    constructor (DSValue src_) public {
        src = src_;
        (bytes32 wut, bool ok) = src_.peek();
        if (ok) {
            cur = nxt = Feed(uint128(wut), ok);
            zzz = prev(era());
        }
    }

    function era() internal view returns (uint) {
        return block.timestamp;
    }

    function prev(uint ts) internal view returns (uint64) {
        return uint64(ts - (ts % hop));
    }

    function step(uint16 ts) external auth {
        require(ts > 0);
        hop = ts;
    }

    function void() external auth {
        cur = nxt = Feed(0, false);
        stopped = true;
    }

    function pass() public view returns (bool ok) {
        return era() >= zzz + hop;
    }

    function poke() external stoppable {
        require(pass());
        (bytes32 wut, bool ok) = src.peek();
        cur = nxt;
        nxt = Feed(uint128(wut), ok);
        zzz = prev(era());
        emit LogValue(bytes32(cur.val));
    }

    function peek() external view returns (bytes32,bool) {
        return (bytes32(cur.val), cur.has);
    }

    function peep() external view returns (bytes32,bool) {
        return (bytes32(nxt.val), nxt.has);
    }

    function read() external view returns (bytes32) {
        require(cur.has);
        return (bytes32(cur.val));
    }
}