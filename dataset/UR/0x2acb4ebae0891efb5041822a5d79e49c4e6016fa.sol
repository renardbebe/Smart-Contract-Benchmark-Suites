 

pragma solidity^0.4.21;

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

    function DSAuth() public {
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

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
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

contract DSThing is DSAuth, DSNote, DSMath {

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

}


contract ERC20 {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 
}

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function DSTokenBase(uint supply) public {
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

        Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        Approval(msg.sender, guy, wad);

        return true;
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


contract DSToken is DSTokenBase(0), DSStop {

    string  public  symbol;
    uint256  public  decimals = 18;  

    function DSToken(string symbol_) public {
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

        Transfer(src, dst, wad);

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
        Mint(guy, wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        Burn(guy, wad);
    }

     
    string  name = "";

    function setName(string name_) public auth {
        name = name_;
    }
}

contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache;   

    function DSProxy(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }

    function() public payable {
    }

     
    function execute(bytes _code, bytes _data)
        public
        payable
        returns (address target, bytes32 response)
    {
        target = cache.read(_code);
        if (target == 0x0) {
             
            target = cache.write(_code);
        }

        response = execute(target, _data);
    }

    function execute(address _target, bytes _data)
        public
        auth
        note
        payable
        returns (bytes32 response)
    {
        require(_target != 0x0);

         
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)       
            switch iszero(succeeded)
            case 1 {
                 
                revert(0, 0)
            }
        }
    }

     
    function setCache(address _cacheAddr)
        public
        auth
        note
        returns (bool)
    {
        require(_cacheAddr != 0x0);         
        cache = DSProxyCache(_cacheAddr);   
        return true;
    }
}

 
 
 
contract DSProxyFactory {
    event Created(address indexed sender, address proxy, address cache);
    mapping(address=>bool) public isProxy;
    DSProxyCache public cache = new DSProxyCache();

     
     
    function build() public returns (DSProxy proxy) {
        proxy = build(msg.sender);
    }

     
     
    function build(address owner) public returns (DSProxy proxy) {
        proxy = new DSProxy(cache);
        Created(owner, address(proxy), address(cache));
        proxy.setOwner(owner);
        isProxy[proxy] = true;
    }
}

 
 
 
 

 
 
 
 
contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
            case 1 {
                 
                revert(0, 0)
            }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}

interface DSValue {
    function peek() external constant returns (bytes32, bool);
    function read() external constant returns (bytes32);
}

contract TubInterface {

    function mat() public view returns(uint);

     

    function ink(bytes32 cup) public view returns (uint);
    function tab(bytes32 cup) public returns (uint);
    function rap(bytes32 cup) public returns (uint);

     
     
    function per() public view returns (uint ray);
     
    function ask(uint wad) public view returns (uint);
     
    function bid(uint wad) public view returns (uint);
    function join(uint wad) public;
    function exit(uint wad) public;

     
     
    function tag() public view returns (uint wad);
     
    function safe(bytes32 cup) public returns (bool);

     
    function open() public returns (bytes32 cup);
    function give(bytes32 cup, address guy) public;
    function lock(bytes32 cup, uint wad) public;
    function free(bytes32 cup, uint wad) public;
    function draw(bytes32 cup, uint wad) public;
    function wipe(bytes32 cup, uint wad) public;
    function shut(bytes32 cup) public;
    function bite(bytes32 cup) public;
}

interface OtcInterface {
    function sellAllAmount(address, uint, address, uint) public returns (uint);
    function buyAllAmount(address, uint, address, uint) public returns (uint);
    function getPayAmount(address, address, uint) public constant returns (uint);
}

interface ProxyCreationAndExecute {
    
    function createAndSellAllAmount(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        ERC20 buyToken,
        uint minBuyAmt) public 
        returns (DSProxy proxy, uint buyAmt);

    function createAndSellAllAmountPayEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 buyToken, 
        uint minBuyAmt) public payable returns (DSProxy proxy, uint buyAmt);

    function createAndSellAllAmountBuyEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        uint minBuyAmt) public returns (DSProxy proxy, uint wethAmt);

    function createAndBuyAllAmount(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (DSProxy proxy, uint payAmt);

    function createAndBuyAllAmountPayEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt) public payable returns (DSProxy proxy, uint wethAmt);

    function createAndBuyAllAmountBuyEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        uint wethAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (DSProxy proxy, uint payAmt);
} 

interface OasisDirectInterface {
    
    function sellAllAmount(
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        ERC20 buyToken,
        uint minBuyAmt) public 
        returns (uint buyAmt);

    function sellAllAmountPayEth(
        OtcInterface otc, 
        ERC20 buyToken, 
        uint minBuyAmt) public payable returns (uint buyAmt);

    function sellAllAmountBuyEth(
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        uint minBuyAmt) public returns (uint wethAmt);

    function buyAllAmount(
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (uint payAmt);

    function buyAllAmountPayEth(
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt) public payable returns (uint wethAmt);

    function buyAllAmountBuyEth(
        OtcInterface otc, 
        uint wethAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (uint payAmt);
}

contract WETH is ERC20 {
    function deposit() public payable;
    function withdraw(uint wad) public;
}

 
contract CDPer is DSStop, DSMath {

     
    uint public slippage = WAD / 50; 
    TubInterface public tub = TubInterface(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    DSToken public dai = DSToken(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);   
    DSToken public skr = DSToken(0xf53AD2c6851052A81B42133467480961B2321C09);   
    WETH public gem = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);   
    DSToken public gov = DSToken(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);   
    DSValue public feed = DSValue(0x729D19f657BD0614b4985Cf1D82531c67569197B);   
    OtcInterface public otc = OtcInterface(0x14FBCA95be7e99C15Cc2996c6C9d841e54B79425);

     
     
     
     
     
     
     
     
     
     

     
    uint public minETH = WAD / 20;  
    uint public minDai = WAD * 50;  

     
    uint public liquidationPriceWad = 320 * WAD;

     
    uint ratio;

    function CDPer() public {

    }

     
    function init() public auth {
        gem.approve(tub, uint(-1));
        skr.approve(tub, uint(-1));
        dai.approve(tub, uint(-1));
        gov.approve(tub, uint(-1));
        
        gem.approve(owner, uint(-1));
        skr.approve(owner, uint(-1));
        dai.approve(owner, uint(-1));
        gov.approve(owner, uint(-1));

        dai.approve(otc, uint(-1));
        gem.approve(otc, uint(-1));

        tubParamUpdate();
    }

     
    function tubParamUpdate() public auth {
        ratio = tub.mat() / 10**9;  
    }

      
    function createAndJoinCDP() public stoppable payable returns(bytes32 id) {

        require(msg.value >= minETH);

        gem.deposit.value(msg.value)();
        
        id = _openAndJoinCDPWETH(msg.value);

        tub.give(id, msg.sender);
    }

     
    function createAndJoinCDPAllDai() public returns(bytes32 id) {
        return createAndJoinCDPDai(dai.balanceOf(msg.sender));
    }

     
    function createAndJoinCDPDai(uint amount) public auth stoppable returns(bytes32 id) {
        require(amount >= minDai);

        uint price = uint(feed.read());

        require(dai.transferFrom(msg.sender, this, amount));

        uint bought = otc.sellAllAmount(dai, amount,
            gem, wmul(WAD - slippage, wdiv(amount, price)));
        
        id = _openAndJoinCDPWETH(bought);
        
        tub.give(id, msg.sender);
    }


     
    function createCDPLeveraged() public auth stoppable payable returns(bytes32 id) {
        require(msg.value >= minETH);

        uint price = uint(feed.read());

        gem.deposit.value(msg.value)();

        id = _openAndJoinCDPWETH(msg.value);

        while(_reinvest(id, price)) {}

        tub.give(id, msg.sender);
    }

     
    function createCDPLeveragedAllDai() public returns(bytes32 id) {
        return createCDPLeveragedDai(dai.balanceOf(msg.sender)); 
    }
    
     
    function createCDPLeveragedDai(uint amount) public auth stoppable returns(bytes32 id) {

        require(amount >= minDai);

        uint price = uint(feed.read());

        require(dai.transferFrom(msg.sender, this, amount));
        uint bought = otc.sellAllAmount(dai, amount,
            gem, wmul(WAD - slippage, wdiv(amount, price)));

        id = _openAndJoinCDPWETH(bought);

        while(_reinvest(id, price)) {}

        tub.give(id, msg.sender);
    }

     
    function shutForETH(uint _id) public auth stoppable {
        bytes32 id = bytes32(_id);
        uint debt = tub.tab(id);
        if (debt > 0) {
            require(dai.transferFrom(msg.sender, this, debt));
        }
        uint ink = tub.ink(id); 
        tub.shut(id);
        uint gemBalance = tub.bid(ink);
        tub.exit(ink);

        gem.withdraw(min(gemBalance, gem.balanceOf(this)));
        
        msg.sender.transfer(min(gemBalance, address(this).balance));
    }

     
    function shutForDai(uint _id) public auth stoppable {
        bytes32 id = bytes32(_id);
        uint debt = tub.tab(id);
        if (debt > 0) {
            require(dai.transferFrom(msg.sender, this, debt));
        }
        uint ink = tub.ink(id); 
        tub.shut(id);
        uint gemBalance = tub.bid(ink);
        tub.exit(ink);

        uint price = uint(feed.read());

        uint bought = otc.sellAllAmount(gem, min(gemBalance, gem.balanceOf(this)), 
            dai, wmul(WAD - slippage, wmul(gemBalance, price)));
        
        require(dai.transfer(msg.sender, bought));
    }

     
    function giveMeCDP(uint id) public auth {
        tub.give(bytes32(id), msg.sender);
    }

     
    function giveMeToken(DSToken token) public auth {
        token.transfer(msg.sender, token.balanceOf(this));
    }

     
    function giveMeETH() public auth {
        msg.sender.transfer(address(this).balance);
    }

     
    function destroy() public auth {
        require(stopped);
        selfdestruct(msg.sender);
    }

     
    function setSlippage(uint slip) public auth {
        require(slip < WAD);
        slippage = slip;
    }

     
    function setLiqPrice(uint wad) public auth {        
        liquidationPriceWad = wad;
    }

     
    function setMinETH(uint wad) public auth {
        minETH = wad;
    }

     
    function setMinDai(uint wad) public auth {
        minDai = wad;
    }

    function setTub(TubInterface _tub) public auth {
        tub = _tub;
    }

    function setDai(DSToken _dai) public auth {
        dai = _dai;
    }

    function setSkr(DSToken _skr) public auth {
        skr = _skr;
    }
    function setGov(DSToken _gov) public auth {
        gov = _gov;
    }
    function setGem(WETH _gem) public auth {
        gem = _gem;
    }
    function setFeed(DSValue _feed) public auth {
        feed = _feed;
    }
    function setOTC(OtcInterface _otc) public auth {
        otc = _otc;
    }

    function _openAndJoinCDPWETH(uint amount) internal returns(bytes32 id) {
        id = tub.open();

        _joinCDP(id, amount);
    }

    function _joinCDP(bytes32 id, uint amount) internal {

        uint skRate = tub.ask(WAD);
        
        uint valueSkr = wdiv(amount, skRate);

        tub.join(valueSkr); 

        tub.lock(id, min(valueSkr, skr.balanceOf(this)));
    }

    function _reinvest(bytes32 id, uint latestPrice) internal returns(bool ok) {
        
         
        uint debt = tub.tab(id);
        uint ink = tub.ink(id); 
        
        uint maxInvest = wdiv(wmul(liquidationPriceWad, ink), ratio);
        
        if(debt >= maxInvest) {
            return false;
        }
        
        uint leftOver = sub(maxInvest, debt);
        
        if(leftOver >= minDai) {
            tub.draw(id, leftOver);

            uint bought = otc.sellAllAmount(dai, min(leftOver, dai.balanceOf(this)),
                gem, wmul(WAD - slippage, wdiv(leftOver, latestPrice)));
            
            _joinCDP(id, bought);

            return true;
        } else {
            return false;
        }
    }

}

contract CDPerFactory {
    event Created(address indexed sender, address cdper);
    mapping(address=>bool) public isCDPer;

     
     
    function build() public returns (CDPer cdper) {
        cdper = build(msg.sender);
    }

     
     
    function build(address owner) public returns (CDPer cdper) {
        cdper = new CDPer();
        emit Created(owner, address(cdper));
        cdper.setOwner(owner);
        isCDPer[cdper] = true;
    }
}