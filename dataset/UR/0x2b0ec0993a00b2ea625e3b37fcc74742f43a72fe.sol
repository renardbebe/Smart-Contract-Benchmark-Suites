 

pragma solidity^0.4.24;


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

library DSMath {
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

interface ERC20 {
    function balanceOf(address src) external view returns (uint);
    function totalSupply() external view returns (uint);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract Accounting {

    using DSMath for uint;

    bool internal _in;
    
    modifier noReentrance() {
        require(!_in);
        _in = true;
        _;
        _in = false;
    }
    
     
    uint public totalETH;
    mapping (address => uint) public totalTokenBalances;

    struct Account {
        bytes32 name;
        uint balanceETH;
        mapping (address => uint) tokenBalances;
    }

    Account base = Account({
        name: "Base",
        balanceETH: 0       
    });

    event ETHDeposited(bytes32 indexed account, address indexed from, uint value);
    event ETHSent(bytes32 indexed account, address indexed to, uint value);
    event ETHTransferred(bytes32 indexed fromAccount, bytes32 indexed toAccount, uint value);
    event TokenTransferred(bytes32 indexed fromAccount, bytes32 indexed toAccount, address indexed token, uint value);
    event TokenDeposited(bytes32 indexed account, address indexed token, address indexed from, uint value);    
    event TokenSent(bytes32 indexed account, address indexed token, address indexed to, uint value);

    function baseETHBalance() public constant returns(uint) {
        return base.balanceETH;
    }

    function baseTokenBalance(address token) public constant returns(uint) {
        return base.tokenBalances[token];
    }

    function depositETH(Account storage a, address _from, uint _value) internal {
        a.balanceETH = a.balanceETH.add(_value);
        totalETH = totalETH.add(_value);
        emit ETHDeposited(a.name, _from, _value);
    }

    function depositToken(Account storage a, address _token, address _from, uint _value) 
    internal noReentrance 
    {        
        require(ERC20(_token).transferFrom(_from, address(this), _value));
        totalTokenBalances[_token] = totalTokenBalances[_token].add(_value);
        a.tokenBalances[_token] = a.tokenBalances[_token].add(_value);
        emit TokenDeposited(a.name, _token, _from, _value);
    }

    function sendETH(Account storage a, address _to, uint _value) 
    internal noReentrance 
    {
        require(a.balanceETH >= _value);
        require(_to != address(0));
        
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);

        _to.transfer(_value);
        
        emit ETHSent(a.name, _to, _value);
    }

    function transact(Account storage a, address _to, uint _value, bytes data) 
    internal noReentrance 
    {
        require(a.balanceETH >= _value);
        require(_to != address(0));
        
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);

        require(_to.call.value(_value)(data));
        
        emit ETHSent(a.name, _to, _value);
    }

    function sendToken(Account storage a, address _token, address _to, uint _value) 
    internal noReentrance 
    {
        require(a.tokenBalances[_token] >= _value);
        require(_to != address(0));
        
        a.tokenBalances[_token] = a.tokenBalances[_token].sub(_value);
        totalTokenBalances[_token] = totalTokenBalances[_token].sub(_value);

        require(ERC20(_token).transfer(_to, _value));
        emit TokenSent(a.name, _token, _to, _value);
    }

    function transferETH(Account storage _from, Account storage _to, uint _value) 
    internal 
    {
        require(_from.balanceETH >= _value);
        _from.balanceETH = _from.balanceETH.sub(_value);
        _to.balanceETH = _to.balanceETH.add(_value);
        emit ETHTransferred(_from.name, _to.name, _value);
    }

    function transferToken(Account storage _from, Account storage _to, address _token, uint _value)
    internal
    {
        require(_from.tokenBalances[_token] >= _value);
        _from.tokenBalances[_token] = _from.tokenBalances[_token].sub(_value);
        _to.tokenBalances[_token] = _to.tokenBalances[_token].add(_value);
        emit TokenTransferred(_from.name, _to.name, _token, _value);
    }

    function balanceETH(Account storage toAccount,  uint _value) internal {
        require(address(this).balance >= totalETH.add(_value));
        depositETH(toAccount, address(this), _value);
    }

    function balanceToken(Account storage toAccount, address _token, uint _value) internal noReentrance {
        uint balance = ERC20(_token).balanceOf(this);
        require(balance >= totalTokenBalances[_token].add(_value));

        toAccount.tokenBalances[_token] = toAccount.tokenBalances[_token].add(_value);
        emit TokenDeposited(toAccount.name, _token, address(this), _value);
    }
    
}


 
contract ButtonBase is DSAuth, Accounting {
     
    using DSMath for uint;

    uint constant ONE_PERCENT_WAD = 10 ** 16; 
    uint constant ONE_WAD = 10 ** 18;

    uint public totalRevenue;
    uint public totalCharity;
    uint public totalWon;

    uint public totalPresses;

     
    uint public startingPrice = 2 finney;
    uint internal _priceMultiplier = 106 * 10 **16;
    uint32 internal _n = 4;  
    uint32 internal _period = 30 minutes; 
    uint internal _newCampaignFraction = ONE_PERCENT_WAD;  
    uint internal _devFraction = 10 * ONE_PERCENT_WAD - _newCampaignFraction;  
    uint internal _charityFraction = 5 * ONE_PERCENT_WAD;  
    uint internal _jackpotFraction = 85 * ONE_PERCENT_WAD;  
    
    address public charityBeneficiary;

     
    Account revenue = 
    Account({
        name: "Revenue",
        balanceETH: 0
    });

    Account nextCampaign = 
    Account({
        name: "Next Campaign",
        balanceETH: 0       
    });

    Account charity = 
    Account({
        name: "Charity",
        balanceETH: 0
    });

     
    mapping (address => Account) winners;

     
    modifier limited(uint value, uint min, uint max) {
        require(value >= min && value <= max);
        _;
    }

     
    mapping (bytes4 => uint) internal _lastExecuted;
    modifier timeLimited(uint _howOften) {
        require(_lastExecuted[msg.sig].add(_howOften) <= now);
        _lastExecuted[msg.sig] = now;
        _;
    }

     
    event Pressed(address by, uint paid, uint64 timeLeft);
    event Started(uint startingETH, uint32 period, uint i);
    event Winrar(address guy, uint jackpot);
     
    event CharityChanged(address newCharityBeneficiary);
    event ButtonParamsChanged(uint startingPrice, uint32 n, uint32 period, uint priceMul);
    event AccountingParamsChanged(uint devFraction, uint charityFraction, uint jackpotFraction);

     
    struct ButtonCampaign {
        uint price;  
        uint priceMultiplier; 
        uint devFraction;  
        uint charityFraction; 
        uint jackpotFraction; 
        uint newCampaignFraction; 

        address lastPresser;
        uint64 deadline;
        uint40 presses;
        uint32 n;
        uint32 period;
        bool finalized;

        Account total; 
    }

    uint public lastCampaignID;
    ButtonCampaign[] campaigns;

     
    function press() public payable;
    
    function () public payable {
        press();
    }

     

     
    function active() public view returns(bool) {
        if(campaigns.length == 0) { 
            return false;
        } else {
            return campaigns[lastCampaignID].deadline >= now;
        }
    }

     
    function latestData() external view returns(
        uint price, uint jackpot, uint char, uint64 deadline, uint presses, address lastPresser
        ) {
        price = this.price();
        jackpot = this.jackpot();
        char = this.charityBalance();
        deadline = this.deadline();
        presses = this.presses();
        lastPresser = this.lastPresser();
    }

     
    function latestParams() external view returns(
        uint jackF, uint revF, uint charF, uint priceMul, uint nParam
    ) {
        jackF = this.jackpotFraction();
        revF = this.revenueFraction();
        charF = this.charityFraction();
        priceMul = this.priceMultiplier();
        nParam = this.n();
    }

     
    function lastWinner() external view returns(address) {
        if(campaigns.length == 0) {
            return address(0x0);
        } else {
            if(active()) {
                return this.winner(lastCampaignID - 1);
            } else {
                return this.winner(lastCampaignID);
            }
        }
    }

     
    function totalsData() external view returns(uint _totalWon, uint _totalCharity, uint _totalPresses) {
        _totalWon = this.totalWon();
        _totalCharity = this.totalCharity();
        _totalPresses = this.totalPresses();
    }
   
    
    function price() external view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].price;
        } else {
            return startingPrice;
        }
    }

     
    function jackpotFraction() public view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].jackpotFraction;
        } else {
            return _jackpotFraction;
        }
    }

     
    function revenueFraction() public view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].devFraction;
        } else {
            return _devFraction;
        }
    }

     
    function charityFraction() public view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].charityFraction;
        } else {
            return _charityFraction;
        }
    }

     
    function priceMultiplier() public view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].priceMultiplier;
        } else {
            return _priceMultiplier;
        }
    }

     
    function period() public view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].period;
        } else {
            return _period;
        }
    }

     
    function n() public view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].n;
        } else {
            return _n;
        }
    }

     
    function timeLeft() external view returns(uint) {
        if (active()) {
            return campaigns[lastCampaignID].deadline - now;
        } else {
            return 0;
        }
    }

     
    function deadline() external view returns(uint64) {
        return campaigns[lastCampaignID].deadline;
    }

     
    function presses() external view returns(uint) {
        if(active()) {
            return campaigns[lastCampaignID].presses;
        } else {
            return 0;
        }
    }

     
    function lastPresser() external view returns(address) {
        return campaigns[lastCampaignID].lastPresser;
    }

     
    function winner(uint campaignID) external view returns(address) {
        return campaigns[campaignID].lastPresser;
    }

     
    function jackpot() external view returns(uint) {
        if(active()){
            return campaigns[lastCampaignID].total.balanceETH.wmul(campaigns[lastCampaignID].jackpotFraction);
        } else {
            if(!campaigns[lastCampaignID].finalized) {
                return campaigns[lastCampaignID].total.balanceETH.wmul(campaigns[lastCampaignID].jackpotFraction)
                    .wmul(campaigns[lastCampaignID].newCampaignFraction);
            } else {
                return nextCampaign.balanceETH.wmul(_jackpotFraction);
            }
        }
    }

     
    function charityBalance() external view returns(uint) {
        if(active()){
            return campaigns[lastCampaignID].total.balanceETH.wmul(campaigns[lastCampaignID].charityFraction);
        } else {
            if(!campaigns[lastCampaignID].finalized) {
                return campaigns[lastCampaignID].total.balanceETH.wmul(campaigns[lastCampaignID].charityFraction)
                    .wmul(campaigns[lastCampaignID].newCampaignFraction);
            } else {
                return nextCampaign.balanceETH.wmul(_charityFraction);
            }
        }
    }

     
    function revenueBalance() external view returns(uint) {
        return revenue.balanceETH;
    }

     
    function nextCampaignBalance() external view returns(uint) {        
        if(!campaigns[lastCampaignID].finalized) {
            return campaigns[lastCampaignID].total.balanceETH.wmul(campaigns[lastCampaignID].newCampaignFraction);
        } else {
            return nextCampaign.balanceETH;
        }
    }

     
    function totalPresses() external view returns(uint) {
        if (!campaigns[lastCampaignID].finalized) {
            return totalPresses.add(campaigns[lastCampaignID].presses);
        } else {
            return totalPresses;
        }
    }

     
    function totalCharity() external view returns(uint) {
        if (!campaigns[lastCampaignID].finalized) {
            return totalCharity.add(campaigns[lastCampaignID].total.balanceETH.wmul(campaigns[lastCampaignID].charityFraction));
        } else {
            return totalCharity;
        }
    }

     
    function totalRevenue() external view returns(uint) {
        if (!campaigns[lastCampaignID].finalized) {
            return totalRevenue.add(campaigns[lastCampaignID].total.balanceETH.wmul(campaigns[lastCampaignID].devFraction));
        } else {
            return totalRevenue;
        }
    }

     
    function hasWon(address _guy) external view returns(uint) {
        return winners[_guy].balanceETH;
    }

     

     
    function withdrawJackpot() public {
        require(winners[msg.sender].balanceETH > 0, "Nothing to withdraw!");
        sendETH(winners[msg.sender], msg.sender, winners[msg.sender].balanceETH);
    }

     
    function donateJackpot() public {
        require(winners[msg.sender].balanceETH > 0, "Nothing to donate!");
        transferETH(winners[msg.sender], charity, winners[msg.sender].balanceETH);
    }

     
    function withdrawRevenue() public auth {
        sendETH(revenue, owner, revenue.balanceETH);
    }

     
     
     
     
    function sendCharityETH(bytes callData) public auth {
         
        transact(charity, charityBeneficiary, charity.balanceETH, callData);
    }

     
    function redeemSurplusETH() public auth {
        uint surplus = address(this).balance.sub(totalETH);
        balanceETH(base, surplus);
        sendETH(base, msg.sender, base.balanceETH);
    }

     
    function redeemSurplusERC20(address token) public auth {
        uint realTokenBalance = ERC20(token).balanceOf(this);
        uint surplus = realTokenBalance.sub(totalTokenBalances[token]);
        balanceToken(base, token, surplus);
        sendToken(base, token, msg.sender, base.tokenBalances[token]);
    }

     
    function withdrawBaseETH() public auth {
        sendETH(base, msg.sender, base.balanceETH);
    }

     
    function withdrawBaseERC20(address token) public auth {
        sendToken(base, token, msg.sender, base.tokenBalances[token]);
    }

     

     
    function setButtonParams(uint startingPrice_, uint priceMul_, uint32 period_, uint32 n_) public 
    auth
    limited(startingPrice_, 1 szabo, 10 ether)  
    limited(priceMul_, ONE_WAD, 10 * ONE_WAD)  
    limited(period_, 30 seconds, 1 weeks)
    {
        startingPrice = startingPrice_;
        _priceMultiplier = priceMul_;
        _period = period_;
        _n = n_;
        emit ButtonParamsChanged(startingPrice_, n_, period_, priceMul_);
    }

     
    function setAccountingParams(uint _devF, uint _charityF, uint _newCampF) public 
    auth
    limited(_devF.add(_charityF).add(_newCampF), 0, ONE_WAD)  
    timeLimited(2 weeks) {  
        require(_charityF <= ONE_WAD);  
        require(_devF <= 20 * ONE_PERCENT_WAD);  
        require(_newCampF <= 10 * ONE_PERCENT_WAD); 
        _devFraction = _devF;
        _charityFraction = _charityF;
        _newCampaignFraction = _newCampF;
        _jackpotFraction = ONE_WAD.sub(_devF).sub(_charityF).sub(_newCampF);
        emit AccountingParamsChanged(_devF, _charityF, _jackpotFraction);
    }

     
    function setCharityBeneficiary(address _charity) public 
    auth
    timeLimited(13 weeks) 
    {   
        require(_charity != address(0));
        charityBeneficiary = _charity;
        emit CharityChanged(_charity);
    }

}

 
contract TheButton is ButtonBase {
    
    using DSMath for uint;

     
    bool public stopped;

    constructor() public {
        stopped = true;
    }

     
    function press() public payable {
         
        ButtonCampaign storage c = campaigns[lastCampaignID];
        if (active()) { 
            _press(c); 
            depositETH(c.total, msg.sender, msg.value); 
        } else {  
            require(!stopped, "Contract stopped!"); 
            if(!c.finalized) { 
                _finalizeCampaign(c); 
            } 
            _newCampaign(); 
            c = campaigns[lastCampaignID];
                    
            _press(c); 
            depositETH(c.total, msg.sender, msg.value); 
        } 
    }

    function start() external payable auth {
        require(stopped, "Already started!");
        stopped = false;
        
        if(campaigns.length != 0) { 
            ButtonCampaign storage c = campaigns[lastCampaignID];
            require(c.finalized, "Last campaign not finalized!"); 
        }             
        _newCampaign(); 
        c = campaigns[lastCampaignID];
        _press(c);
        depositETH(c.total, msg.sender, msg.value); 
    }

     
    function stop() external auth {
        require(!stopped, "Already stopped!");
        stopped = true;
    }
    
     
    function finalizeLastCampaign() external {
        require(stopped);
        ButtonCampaign storage c = campaigns[lastCampaignID];
        _finalizeCampaign(c);
    }

    function finalizeCampaign(uint id) external {
        require(stopped);
        ButtonCampaign storage c = campaigns[id];
        _finalizeCampaign(c);
    }

     
    function _press(ButtonCampaign storage c) internal {
        require(c.deadline >= now, "After deadline!"); 
        require(msg.value >= c.price, "Not enough value!"); 
        c.presses += 1; 
        c.lastPresser = msg.sender;
             
        if(c.presses % c.n == 0) { 
            c.price = c.price.wmul(c.priceMultiplier);
        }           

        emit Pressed(msg.sender, msg.value, c.deadline - uint64(now));
        c.deadline = uint64(now.add(c.period));  
    }

     
    function _newCampaign() internal {
        require(!active(), "A campaign is already running!");
        require(_devFraction.add(_charityFraction).add(_jackpotFraction).add(_newCampaignFraction) == ONE_WAD, "Accounting is incorrect!");
        
        uint _campaignID = campaigns.length++;
        ButtonCampaign storage c = campaigns[_campaignID];
        lastCampaignID = _campaignID;

        c.price = startingPrice;
        c.priceMultiplier = _priceMultiplier;
        c.devFraction = _devFraction;
        c.charityFraction = _charityFraction;
        c.jackpotFraction = _jackpotFraction;
        c.newCampaignFraction = _newCampaignFraction;
        c.deadline = uint64(now.add(_period));
        c.n = _n;
        c.period = _period;
        c.total.name = keccak256(abi.encodePacked("Total", lastCampaignID)); 
        transferETH(nextCampaign, c.total, nextCampaign.balanceETH);
        emit Started(c.total.balanceETH, _period, lastCampaignID); 
    }

     
    function _finalizeCampaign(ButtonCampaign storage c) internal {
        require(c.deadline < now, "Before deadline!");
        require(!c.finalized, "Already finalized!");
        
        if(c.presses != 0) { 
            uint totalBalance = c.total.balanceETH;
             
            transferETH(c.total, winners[c.lastPresser], totalBalance.wmul(c.jackpotFraction));
            winners[c.lastPresser].name = bytes32(c.lastPresser);
            totalWon = totalWon.add(totalBalance.wmul(c.jackpotFraction));

            transferETH(c.total, revenue, totalBalance.wmul(c.devFraction));
            totalRevenue = totalRevenue.add(totalBalance.wmul(c.devFraction));

            transferETH(c.total, charity, totalBalance.wmul(c.charityFraction));
            totalCharity = totalCharity.add(totalBalance.wmul(c.charityFraction));

             
             

            totalPresses = totalPresses.add(c.presses);

            emit Winrar(c.lastPresser, totalBalance.wmul(c.jackpotFraction));
        } 
         
        if(stopped) {
             
            transferETH(c.total, base, c.total.balanceETH);
        } else {
             
            transferETH(c.total, nextCampaign, c.total.balanceETH);
        }
        c.finalized = true;
    }
}