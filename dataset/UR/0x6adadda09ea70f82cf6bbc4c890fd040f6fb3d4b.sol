 

 
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

 
 

 
 
 
 

 
 
 
 

 
 

 

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
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

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 
 
 

contract DSThing is DSAuth, DSNote, DSMath {

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(s)));
    }

}

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 

contract DSValue is DSThing {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }
    function read() public view returns (bytes32) {
        bytes32 wut; bool haz;
        (wut, haz) = peek();
        assert(haz);
        return wut;
    }
    function poke(bytes32 wut) public note auth {
        val = wut;
        has = true;
    }
    function void() public note auth {   
        has = false;
    }
}

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 

contract Medianizer is DSThing {
    event LogValue(bytes32 val);

    uint128 val;
    bool public has;

    mapping (bytes12 => address) public values;
    mapping (address => bytes12) public indexes;
    bytes12 public next = 0x1;
    uint96 public min = 0x1;

    function set(address wat) public auth {
        bytes12 nextId = bytes12(uint96(next) + 1);
        require(nextId != 0x0);
        this.set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) public note auth {
        require(pos != 0x0);
        require(wat == 0 || indexes[wat] == 0);

        indexes[values[pos]] = 0x0;  

        if (wat != 0) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function setMin(uint96 min_) public note auth {
        require(min_ != 0x0);
        min = min_;
    }

    function setNext(bytes12 next_) public note auth {
        require(next_ != 0x0);
        next = next_;
    }

    function unset(bytes12 pos) public auth {
        this.set(pos, 0);
    }

    function unset(address wat) public auth {
        this.set(indexes[wat], 0);
    }

    function void() external auth {
        has = false;
         
    }

    function poke() external {
        (bytes32 val_, bool has_) = compute();
        val = uint128(val_);
        has = has_;
        emit LogValue(val_);
    }

    function peek() external view returns (bytes32, bool) {
        return (bytes32(val), has);
    }

    function read() external view returns (bytes32) {
        require(has);
        return bytes32(val);
    }

    function compute() public view returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint96(next) - 1);
        uint96 ctr = 0;
        for (uint96 i = 1; i < uint96(next); i++) {
            if (values[bytes12(i)] != 0) {
                bytes32 wut;
                bool wuz;
                (wut, wuz) = DSValue(values[bytes12(i)]).peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint96 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint96 k = ctr; k > j; k--) {
                            wuts[k] = wuts[k - 1];
                        }
                        wuts[j] = wut;
                    }
                    ctr++;
                }
            }
        }

        if (ctr < min) {
            return (bytes32(val), false);
        }

        bytes32 value;
        if (ctr % 2 == 0) {
            uint128 val1 = uint128(wuts[(ctr / 2) - 1]);
            uint128 val2 = uint128(wuts[ctr / 2]);
            value = bytes32(wdiv(add(val1, val2), 2 ether));
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }

}