 

pragma solidity ^0.4.13;


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

    string  public  symbol = "";
    string   public  name = "";
    uint256  public  decimals = 18;  

    function DSToken(
        string symbol_,
        string name_
    ) public {
        symbol = symbol_;
        name = name_;
    }

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);

    function setName(string name_) public auth {
        name = name_;
    }

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
}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
contract TICDist is DSAuth, DSMath {

    DSToken  public  TIC;                    
    uint256  public  initSupply = 0;         
    uint256  public  decimals = 18;          

     
    uint public distDay = 0;                 
    bool public isDistConfig = false;        
    bool public isLockedConfig = false;      
    
    bool public bTest = true;                
    uint public testUnlockedDay = 0;         
    
    struct Detail {  
        uint distPercent;    
        uint lockedPercent;  
        uint lockedDay;      
        uint256 lockedToken;    
    }

    address[] public founderList;                  
    mapping (address => Detail)  public  founders; 
    
     
    function TICDist(uint256 initial_supply) public {
        initSupply = initial_supply;
    }

     
     
    function setTIC(DSToken  tic) public auth {
         
        assert(address(TIC) == address(0));
         
        assert(tic.owner() == address(this));
         
        assert(tic.totalSupply() == 0);
         
        TIC = tic;
         
        initSupply = initSupply*10**uint256(decimals);
        TIC.mint(initSupply);
    }

     
     
     
    function setDistConfig(address[] founders_, uint[] percents_) public auth {
         
        assert(isDistConfig == false);
         
        assert(founders_.length > 0);
        assert(founders_.length == percents_.length);
        uint all_percents = 0;
        uint i = 0;
        for (i=0; i<percents_.length; ++i){
            assert(percents_[i] > 0);
            assert(founders_[i] != address(0));
            all_percents += percents_[i];
        }
        assert(all_percents <= 100);
         
        founderList = founders_;
        for (i=0; i<founders_.length; ++i){
            founders[founders_[i]].distPercent = percents_[i];
        }
         
        isDistConfig = true;
    }

     
     
     
     
    function setLockedConfig(address[] founders_, uint[] percents_, uint[] days_) public auth {
         
        assert(isDistConfig == true);
         
        assert(isLockedConfig == false);
         
        if (founders_.length > 0){
             
            assert(founders_.length == percents_.length);
            assert(founders_.length == days_.length);
            uint i = 0;
            for (i=0; i<percents_.length; ++i){
                assert(percents_[i] > 0);
                assert(percents_[i] <= 100);
                assert(days_[i] > 0);
                assert(founders_[i] != address(0));
            }
             
            for (i=0; i<founders_.length; ++i){
                founders[founders_[i]].lockedPercent = percents_[i];
                founders[founders_[i]].lockedDay = days_[i];
            }
        }
         
        isLockedConfig = true;
    }

     
    function startDist() public auth {
         
        assert(distDay == 0);
         
        assert(isDistConfig == true);
        assert(isLockedConfig == true);
         
        uint i = 0;
        for(i=0; i<founderList.length; ++i){
             
            uint256 all_token_num = TIC.totalSupply()*founders[founderList[i]].distPercent/100;
            assert(all_token_num > 0);
             
            uint256 locked_token_num = all_token_num*founders[founderList[i]].lockedPercent/100;
             
            founders[founderList[i]].lockedToken = locked_token_num;
             
            TIC.push(founderList[i], all_token_num - locked_token_num);
        }
         
        distDay = today();
         
        for(i=0; i<founderList.length; ++i){
            if (founders[founderList[i]].lockedDay != 0){
                founders[founderList[i]].lockedDay += distDay;
            }
        }
    }

     
    function checkLockedToken() public {
         
        assert(distDay != 0);
         
        if (bTest){
             
            assert(today() > testUnlockedDay);
             
            uint unlock_percent = 1;
             
            uint i = 0;
            for(i=0; i<founderList.length; ++i){
                 
                if (founders[founderList[i]].lockedDay > 0 && founders[founderList[i]].lockedToken > 0){
                     
                    uint256 all_token_num = TIC.totalSupply()*founders[founderList[i]].distPercent/100;
                     
                    uint256 locked_token_num = all_token_num*founders[founderList[i]].lockedPercent/100;
                     
                    uint256 unlock_token_num = locked_token_num*unlock_percent/founders[founderList[i]].lockedPercent;
                    if (unlock_token_num > founders[founderList[i]].lockedToken){
                        unlock_token_num = founders[founderList[i]].lockedToken;
                    }
                     
                    TIC.push(founderList[i], unlock_token_num);
                     
                    founders[founderList[i]].lockedToken -= unlock_token_num;
                }
            }
             
            testUnlockedDay = today();            
        } else {
             
            assert(founders[msg.sender].lockedDay > 0);
             
            assert(founders[msg.sender].lockedToken > 0);
             
            assert(today() > founders[msg.sender].lockedDay);
             
            TIC.push(msg.sender, founders[msg.sender].lockedToken);
             
            founders[msg.sender].lockedToken = 0;
        }
    }

     
    function today() public constant returns (uint) {
        return time() / 24 hours;
         
         
    }
   
     
    function time() public constant returns (uint) {
        return block.timestamp;
    }
}