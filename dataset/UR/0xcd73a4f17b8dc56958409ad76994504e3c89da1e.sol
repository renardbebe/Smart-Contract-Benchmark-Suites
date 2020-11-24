 

 
pragma solidity >=0.4.8 <0.5.0 >=0.4.13 <0.5.0 >=0.4.23 <0.5.0;

 
 
 
 
 

 
 
 
 

 
 

 

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
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

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
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

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
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        emit Burn(guy, wad);
    }

     
    bytes32   public  name = "";

    function setName(bytes32 name_) public auth {
        name = name_;
    }
}

 
 

 
 
 
 
 

contract MedianizerLike {
    function peek() external view returns (bytes32, bool);
}

 
contract DPTICOEvents {
    event LogBuyToken(
        address owner,
        address sender,
        uint ethValue,
        uint dptValue,
        uint ethUsdRate,
        uint dptUsdRate
    );
    event LogFeedValid(bool feedValid);
}

contract DPTICO is DSAuth, DSStop, DSMath, DPTICOEvents {
    uint public dptUsdRate;               
    uint public ethUsdRate;               
    MedianizerLike public priceFeed;      
    bool public feedValid;                
    ERC20 public dpt;                     
    bool public manualUsdRate = true;     
    uint public minDptInvestmentAmount = 0;  

     
    constructor(address dpt_, address priceFeed_, uint dptUsdRate_, uint ethUsdRate_) public {
        dpt = ERC20(dpt_);
        priceFeed = MedianizerLike(priceFeed_);
        dptUsdRate = dptUsdRate_;
        ethUsdRate = ethUsdRate_;
    }

     
    function () external payable {
        buyTokens();
    }

     
    function buyTokens() public payable stoppable {
        uint tokens;
        bool feedValidSave = feedValid;
        bytes32 ethUsdRateB;

        require(msg.value != 0, "Invalid amount");

         
        (ethUsdRateB, feedValid) = priceFeed.peek();

         
        if (feedValidSave != feedValid) {
            emit LogFeedValid(feedValid);
        }

         
        if (feedValid) {
            ethUsdRate = uint(ethUsdRateB);
        } else {
             
            require(manualUsdRate, "Manual rate not allowed");
        }

        tokens = wdiv(wmul(ethUsdRate, msg.value), dptUsdRate);

         
        require(tokens >= minDptInvestmentAmount, "Token amount must be greater or equal than minimal investment amount");

        address(owner).transfer(msg.value);
        dpt.transferFrom(owner, msg.sender, tokens);
        emit LogBuyToken(owner, msg.sender, msg.value, tokens, ethUsdRate, dptUsdRate);
    }

     
    function getPrice(uint tokenAmount) public view returns (uint) {
        bool feedValid_;
        uint ethUsdRate_;
        bytes32 ethUsdRateB;
        require(tokenAmount > 0, "Invalid amount");

         
        (ethUsdRateB, feedValid_) = priceFeed.peek();

        if (feedValid_) {
            ethUsdRate_ = uint(ethUsdRateB);
        } else {
             
            require(manualUsdRate, "Manual rate not allowed");
            ethUsdRate_ = ethUsdRate;
        }

        return wdiv(wmul(tokenAmount, dptUsdRate), ethUsdRate_);
    }

     
    function setDptRate(uint dptUsdRate_) public auth note {
        require(dptUsdRate_ > 0, "Invalid amount");
        dptUsdRate = dptUsdRate_;
    }

     
    function setEthRate(uint ethUsdRate_) public auth note {
        require(manualUsdRate, "Manual rate not allowed");
        ethUsdRate = ethUsdRate_;
    }

     
    function setPriceFeed(address priceFeed_) public auth note {
        require(priceFeed_ != 0x0, "Wrong PriceFeed address");
        priceFeed = MedianizerLike(priceFeed_);
    }

     
    function setManualUsdRate(bool manualUsdRate_) public auth note {
        manualUsdRate = manualUsdRate_;
    }

     
    function setMinDptInvestmentAmount(uint minDptInvestmentAmount_) public auth note {
        minDptInvestmentAmount = minDptInvestmentAmount_;
    }
}