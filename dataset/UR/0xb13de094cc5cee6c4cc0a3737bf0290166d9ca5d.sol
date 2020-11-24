 

pragma solidity ^0.5.0;


contract DSNote {
    event LogNote(
        bytes4   indexed sig,
        address  indexed guy,
        bytes32  indexed foo,
        bytes32  indexed bar,
        uint wad,
        bytes fax
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


contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public view returns (bool);
}


contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public{
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier authorized(bytes4 sig) {
        require(isAuthorized(msg.sender, sig));
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
            return authority.canCall(src, address(this), sig);
        }
    }

}


contract DSStop is DSAuth, DSNote {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }

    function stop() public payable auth note {
        stopped = true;
    }

    function start() public payable auth note {
        stopped = false;
    }

}


contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
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


contract ERC20 {

    function totalSupply() public view returns (uint);

    function balanceOf(address guy) public view returns (uint);

    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);

    function transfer(address dst, uint wad) public returns (bool);

    function transferFrom(address src, address dst, uint wad) public returns (bool);

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}


contract ERC677 is ERC20 {
    function transferAndCall(address dst, uint wad, bytes memory data) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


contract ERC677Receiver {
    function onTokenTransfer(address sender, uint wad, bytes memory data) public ;
}


contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping(address => uint256)                       _balances;
    mapping(address => mapping(address => uint256))  _approvals;
    mapping (address => bool) public               frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function totalSupply() public view returns (uint) {
        return _supply;
    }

    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }

    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        require(dst != address(0) && wad > 0);
        require(_balances[msg.sender] >= wad);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[dst]);

        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(msg.sender, dst, wad);

        return true;
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        require(dst != address(0) && wad > 0);
        require(_balances[src] >= wad);
        require(_approvals[src][msg.sender] >= wad);
        require(!frozenAccount[src]);
        require(!frozenAccount[dst]);

        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);
        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        require(guy != address(0) && wad >= 0);
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function freezeAccount(address target, bool freeze) public returns (bool) {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
        return true;
    }
}


contract ERC677Token is ERC677 {

    function transferAndCall(address dst, uint wad, bytes memory data) public returns (bool success) {
        super.transfer(dst, wad);
        emit Transfer(msg.sender, dst, wad, data);
        if (isContract(dst)) {
            contractFallback(dst, wad, data);
        }
        return true;
    }

    function contractFallback(address dst, uint wad, bytes memory data) private {
        ERC677Receiver receiver = ERC677Receiver(dst);
        receiver.onTokenTransfer(msg.sender, wad, data);
    }

    function isContract(address _addr) internal view returns (bool) {
        uint size;
        if (_addr == address(0)) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }
}


contract GMAToken is DSTokenBase, ERC677Token, DSStop {
    string  public  symbol = "GMAT";
    string  public name = "GoWithMi";
    uint256  public  decimals = 18;

    string public version = "G1.0";  

    constructor() public {
        _supply = 14900000000000000000000000000;
        _balances[msg.sender] = _supply;
    }

    function transferAndCall(address dst, uint wad, bytes memory data) public stoppable returns (bool success) {
        return super.transferAndCall(dst, wad, data);
    }

    function transfer(address dst, uint wad) public stoppable returns (bool) {
        return super.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public stoppable returns (bool) {
        return super.transferFrom(src, dst, wad);
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function push(address dst, uint wad) public returns (bool) {
        return transfer(dst, wad);
    }

    function pull(address src, uint wad) public returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner returns (bool) {
        return super.freezeAccount(target, freeze);
    }
}