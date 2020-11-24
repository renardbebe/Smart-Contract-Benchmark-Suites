 

 

 
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
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
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

 
 

 
 
 
 

 
 
 
 

 
 

 

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 
 

contract DSStop is DSNote, DSAuth {
    bool public stopped;

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}

 
 

 

 
 
 

 

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 
 

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    constructor(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

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
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            require(_approvals[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "ds-token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }
}

 
 

 

 
 
 
 

 
 
 
 

 
 

 

 

 

contract DSToken is DSTokenBase(0), DSStop {

    bytes32  public  symbol;
    uint256  public  decimals = 18;  

    constructor(bytes32 symbol_) public {
        symbol = symbol_;
    }

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            require(_approvals[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "ds-token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }

    function mint(uint wad) public {
        mint(msg.sender, wad);
    }
    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    function mint(address guy, uint wad) public auth stoppable {
        _balances[guy] = add(_balances[guy], wad);
        _supply = add(_supply, wad);
        emit Mint(guy, wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            require(_approvals[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        require(_balances[guy] >= wad, "ds-token-insufficient-balance");
        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        emit Burn(guy, wad);
    }

     
    bytes32   public  name = "";

    function setName(bytes32 name_) public auth {
        name = name_;
    }
}

 
 

 

interface EscrowDataInterface
{
     
    function createEscrow(
        bytes32 _tradeId, 
        DSToken _token, 
        address _buyer, 
        address _seller, 
        uint256 _value, 
        uint16 _fee,
        uint32 _paymentWindowInSeconds
    ) external returns(bool);

    function getEscrow(
        bytes32 _tradeHash
    ) external returns(bool, uint32, uint128);

    function removeEscrow(
        bytes32 _tradeHash
    ) external returns(bool);

    function updateSellerCanCancelAfter(
        bytes32 _tradeHash,
        uint32 _paymentWindowInSeconds
    ) external returns(bool);

    function increaseTotalGasFeesSpentByRelayer(
        bytes32 _tradeHash,
        uint128 _increaseGasFees
    ) external returns(bool);
}
 
 

 
 
 

 
contract EscrowData is DSAuth, EscrowDataInterface
{
    address public dexc2c;

    event SetDexC2C(address caller, address dexc2c);
    event Created(bytes32 _tradeHash);
    event Removed(bytes32 _tradeHash);
    event Updated(bytes32 _tradeHash, uint32 _sellerCanCancelAfter);

    mapping (bytes32 => Escrow) public escrows;
    struct Escrow
    {
        bool exists;
         
        uint32 sellerCanCancelAfter;
        uint128 totalGasFeesSpentByRelayer;
    }

    function setDexC2C(address _dexc2c)public auth returns(bool){
        require(_dexc2c != address(0x00), "DEXC2C address error");
        dexc2c = _dexc2c;
        emit SetDexC2C(msg.sender, _dexc2c);
        return true;
    }

    modifier onlyDexc2c(){
        require(msg.sender == dexc2c, "Must be dexc2c");
        _;
    }

    function createEscrow(
        bytes32 _tradeId,
        DSToken _tradeToken,
        address _buyer,
        address _seller,
        uint256 _value,
        uint16 _fee,
        uint32 _paymentWindowInSeconds
    ) public onlyDexc2c returns(bool){
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId, _tradeToken, _buyer, _seller, _value, _fee));
        require(!escrows[_tradeHash].exists, "Trade already exists");
        uint32 _sellerCanCancelAfter = uint32(block.timestamp) + _paymentWindowInSeconds;
    
        escrows[_tradeHash] = Escrow(true, _sellerCanCancelAfter, 0);
        emit Created(_tradeHash);
        return true;
    }

    function getEscrow(
        bytes32 _tradeHash
    ) public view returns (bool, uint32, uint128){
        Escrow memory escrow = escrows[_tradeHash];
        if(escrow.exists){
            return (escrow.exists, escrow.sellerCanCancelAfter, escrow.totalGasFeesSpentByRelayer);
        }
        return (false, 0, 0);
    }

    function exists(
        bytes32 _tradeHash
    ) public view returns(bool){
        return escrows[_tradeHash].exists;
    }

    function removeEscrow(
        bytes32 _tradeHash
    ) public onlyDexc2c returns(bool){
        require(escrows[_tradeHash].exists, "Escrow not exists");
        delete escrows[_tradeHash];
        emit Removed(_tradeHash);
        return true;
    }

    function updateSellerCanCancelAfter(
        bytes32 _tradeHash,
        uint32 _paymentWindowInSeconds
    ) public onlyDexc2c returns(bool){
        require(escrows[_tradeHash].exists, "Escrow not exists");
        uint32 _sellerCanCancelAfter = uint32(block.timestamp) + _paymentWindowInSeconds;
        escrows[_tradeHash].sellerCanCancelAfter = _sellerCanCancelAfter;
        emit Updated(_tradeHash, _sellerCanCancelAfter);
        return true;
    }

    function increaseTotalGasFeesSpentByRelayer(
        bytes32 _tradeHash,
        uint128 _increaseGasFees
    ) public onlyDexc2c returns(bool){
        require(escrows[_tradeHash].exists, "Escrow not exists");
        escrows[_tradeHash].totalGasFeesSpentByRelayer += _increaseGasFees;
        return true;
    }

}