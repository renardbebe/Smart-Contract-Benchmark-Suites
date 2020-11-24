 

pragma solidity^0.4.24;

 
 
 
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

interface MobiusRedToken {
    function mint(address _to, uint _amount) external;
    function finishMinting() external returns (bool);
    function disburseDividends() external payable;
}
 
contract MobiusRED is DSMath, DSAuth {
     
     
    string public ipfsHash;
    string public ipfsHashType = "ipfs";  

    MobiusRedToken public token;

     
     
    bool public upgraded;
    address public nextVersion;

     
    uint public totalSharesSold;
    uint public totalEarningsGenerated;
    uint public totalDividendsPaid;
    uint public totalJackpotsWon;

     
    uint public constant DEV_FRACTION = WAD / 20;              
    uint public constant DEV_DIVISOR = 20;              

    uint public constant RETURNS_FRACTION = 65 * 10**16;       
     
    uint public constant REFERRAL_FRACTION = 1 * 10**16;  
    uint public constant JACKPOT_SEED_FRACTION = WAD / 20;     
    uint public constant JACKPOT_FRACTION = 15 * 10**16;       
    uint public constant AIRDROP_FRACTION = WAD / 100;         
    uint public constant DIVIDENDS_FRACTION = 9 * 10**16;      

    uint public constant STARTING_SHARE_PRICE = 1 finney;  
    uint public constant PRICE_INCREASE_PERIOD = 1 hours;  

    uint public constant HARD_DEADLINE_DURATION = 10 days;  
    uint public constant SOFT_DEADLINE_DURATION = 1 days;  
    uint public constant TIME_PER_SHARE = 5 minutes;  
    
    uint public jackpotSeed; 
    uint public devBalance;  
    uint public raisedICO;

     
    uint public unclaimedReturns;
    uint public constant MULTIPLIER = RAY;

     
     
    struct Investor {
        uint lastCumulativeReturnsPoints;
        uint shares;
    }

     
    struct MobiusRound {
        uint totalInvested;        
        uint jackpot;
        uint airdropPot;
        uint totalShares;
        uint cumulativeReturnsPoints;  
        uint hardDeadline;
        uint softDeadline;
        uint price;
        uint lastPriceIncreaseTime;
        address lastInvestor;
        bool finalized;
        mapping (address => Investor) investors;
    }

    struct Vault {
        uint totalReturns;  
        uint refReturns;  
    }

    mapping (address => Vault) vaults;

    uint public latestRoundID; 
    MobiusRound[] rounds;

    event SharesIssued(address indexed to, uint shares);
    event ReturnsWithdrawn(address indexed by, uint amount);
    event JackpotWon(address by, uint amount);
    event AirdropWon(address by, uint amount);
    event RoundStarted(uint indexed ID, uint hardDeadline);
    event IPFSHashSet(string _type, string _hash);

    constructor(address _token) public {
        token = MobiusRedToken(_token);
    }

     
     
    function estimateReturns(address investor, uint roundID) public view 
    returns (uint totalReturns, uint refReturns) 
    {
        MobiusRound storage rnd = rounds[roundID];
        uint outstanding;
        if(rounds.length > 1) {
            if(hasReturns(investor, roundID - 1)) {
                MobiusRound storage prevRnd = rounds[roundID - 1];
                outstanding = _outstandingReturns(investor, prevRnd);
            }
        }

        outstanding += _outstandingReturns(investor, rnd);
        
        totalReturns = vaults[investor].totalReturns + outstanding;
        refReturns = vaults[investor].refReturns;
    }

    function hasReturns(address investor, uint roundID) public view returns (bool) {
        MobiusRound storage rnd = rounds[roundID];
        return rnd.cumulativeReturnsPoints > rnd.investors[investor].lastCumulativeReturnsPoints;
    }

    function investorInfo(address investor, uint roundID) external view
    returns(uint shares, uint totalReturns, uint referralReturns) 
    {
        MobiusRound storage rnd = rounds[roundID];
        shares = rnd.investors[investor].shares;
        (totalReturns, referralReturns) = estimateReturns(investor, roundID);
    }

    function roundInfo(uint roundID) external view 
    returns(
        address leader, 
        uint price,
        uint jackpot, 
        uint airdrop, 
        uint shares, 
        uint totalInvested,
        uint distributedReturns,
        uint _hardDeadline,
        uint _softDeadline,
        bool finalized
        )
    {
        MobiusRound storage rnd = rounds[roundID];
        leader = rnd.lastInvestor;
        price = rnd.price;
        jackpot = rnd.jackpot;
        airdrop = rnd.airdropPot;
        shares = rnd.totalShares;
        totalInvested = rnd.totalInvested;
        distributedReturns = wmul(rnd.totalInvested, RETURNS_FRACTION);
        _hardDeadline = rnd.hardDeadline;
        _softDeadline = rnd.softDeadline;
        finalized = rnd.finalized;
    }

    function totalsInfo() external view 
    returns(
        uint totalReturns,
        uint totalShares,
        uint totalDividends,
        uint totalJackpots
    ) {
        MobiusRound storage rnd = rounds[latestRoundID];
        if(rnd.softDeadline > now) {
            totalShares = totalSharesSold + rnd.totalShares;
            totalReturns = totalEarningsGenerated + wmul(rnd.totalInvested, RETURNS_FRACTION);
            totalDividends = totalDividendsPaid + wmul(rnd.totalInvested, DIVIDENDS_FRACTION);
        } else {
            totalShares = totalSharesSold;
            totalReturns = totalEarningsGenerated;
            totalDividends = totalDividendsPaid;
        }
        totalJackpots = totalJackpotsWon;
    }

    function () public payable {
        buyShares(address(0x0));
    }

     
    function buyShares(address ref) public payable {        
        if(rounds.length > 0) {
            MobiusRound storage rnd = rounds[latestRoundID];   
               
            _purchase(rnd, msg.value, ref);            
        } else {
            revert("Not yet started");
        }
    }

     
    function reinvestReturns(uint value) public {        
        reinvestReturns(value, address(0x0));
    }

    function reinvestReturns(uint value, address ref) public {        
        MobiusRound storage rnd = rounds[latestRoundID];
        _updateReturns(msg.sender, rnd);        
        require(vaults[msg.sender].totalReturns >= value, "Can't spend what you don't have");        
        vaults[msg.sender].totalReturns = sub(vaults[msg.sender].totalReturns, value);
        vaults[msg.sender].refReturns = min(vaults[msg.sender].refReturns, vaults[msg.sender].totalReturns);
        unclaimedReturns = sub(unclaimedReturns, value);
        _purchase(rnd, value, ref);
    }

    function withdrawReturns() public {
        MobiusRound storage rnd = rounds[latestRoundID];

        if(rounds.length > 1) { 
            if(hasReturns(msg.sender, latestRoundID - 1)) {
                MobiusRound storage prevRnd = rounds[latestRoundID - 1];
                _updateReturns(msg.sender, prevRnd);
            }
        }
        _updateReturns(msg.sender, rnd);
        uint amount = vaults[msg.sender].totalReturns;
        require(amount > 0, "Nothing to withdraw!");
        unclaimedReturns = sub(unclaimedReturns, amount);
        vaults[msg.sender].totalReturns = 0;
        vaults[msg.sender].refReturns = 0;
        
        rnd.investors[msg.sender].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
        msg.sender.transfer(amount);

        emit ReturnsWithdrawn(msg.sender, amount);
    }

     
    function updateMyReturns(uint roundID) public {
        MobiusRound storage rnd = rounds[roundID];
        _updateReturns(msg.sender, rnd);
    }

    function finalizeAndRestart() public payable {
        finalizeLastRound();
        startNewRound();
    }

     
    function startNewRound() public payable {
        require(!upgraded, "This contract has been upgraded!");
        if(rounds.length > 0) {
            require(rounds[latestRoundID].finalized, "Previous round not finalized");
            require(rounds[latestRoundID].softDeadline < now, "Previous round still running");
        }
        uint _rID = rounds.length++;
        MobiusRound storage rnd = rounds[_rID];
        latestRoundID = _rID;

        rnd.lastInvestor = msg.sender;
        rnd.price = STARTING_SHARE_PRICE;
        rnd.hardDeadline = now + HARD_DEADLINE_DURATION;
        rnd.softDeadline = now + SOFT_DEADLINE_DURATION;
        rnd.jackpot = jackpotSeed;
        jackpotSeed = 0; 

        _purchase(rnd, msg.value, address(0x0));
        emit RoundStarted(_rID, rnd.hardDeadline);
    }

     
    function finalizeLastRound() public {
        MobiusRound storage rnd = rounds[latestRoundID];
        _finalizeRound(rnd);
    }
    
     
    function withdrawDevShare() public auth {
        uint value = devBalance;
        devBalance = 0;
        msg.sender.transfer(value);
    }

    function setIPFSHash(string _type, string _hash) public auth {
        ipfsHashType = _type;
        ipfsHash = _hash;
        emit IPFSHashSet(_type, _hash);
    }

    function upgrade(address _nextVersion) public auth {
        require(_nextVersion != address(0x0), "Invalid Address!");
        require(!upgraded, "Already upgraded!");
        upgraded = true;
        nextVersion = _nextVersion;
        if(rounds[latestRoundID].finalized) {
             
            vaults[nextVersion].totalReturns = jackpotSeed;
            jackpotSeed = 0;
        }
    }

     
    function _purchase(MobiusRound storage rnd, uint value, address ref) internal {
        require(rnd.softDeadline >= now, "After deadline!");
        require(value >= rnd.price/10, "Not enough Ether!");
        rnd.totalInvested = add(rnd.totalInvested, value);

         
        if(value >= rnd.price)
            rnd.lastInvestor = msg.sender;
         
        _airDrop(rnd, value);
         
        _splitRevenue(rnd, value, ref);
         
        _updateReturns(msg.sender, rnd);
         
        uint newShares = _issueShares(rnd, msg.sender, value);

         
        if(rounds.length == 1) {
            token.mint(msg.sender, newShares);
        }
        uint timeIncreases = newShares/WAD; 
         
        uint newDeadline = add(rnd.softDeadline, mul(timeIncreases, TIME_PER_SHARE));
        rnd.softDeadline = min(newDeadline, now + SOFT_DEADLINE_DURATION);
         
        if(now > rnd.hardDeadline) {
            if(now > rnd.lastPriceIncreaseTime + PRICE_INCREASE_PERIOD) {
                rnd.price = rnd.price * 2;
                rnd.lastPriceIncreaseTime = now;
            }
        }
    }

    function _finalizeRound(MobiusRound storage rnd) internal {
        require(!rnd.finalized, "Already finalized!");
        require(rnd.softDeadline < now, "Round still running!");

        if(rounds.length == 1) {
             
            require(token.finishMinting(), "Couldn't finish minting tokens!");
        }
         
        vaults[rnd.lastInvestor].totalReturns = add(vaults[rnd.lastInvestor].totalReturns, rnd.jackpot);
        unclaimedReturns = add(unclaimedReturns, rnd.jackpot);
        
        emit JackpotWon(rnd.lastInvestor, rnd.jackpot);
        totalJackpotsWon += rnd.jackpot;
         
        jackpotSeed = add(jackpotSeed, wmul(rnd.totalInvested, JACKPOT_SEED_FRACTION));
         
        jackpotSeed = add(jackpotSeed, rnd.airdropPot);
        if(upgraded) {
             
            vaults[nextVersion].totalReturns = jackpotSeed;
            jackpotSeed = 0; 
        }        
         
        uint _div;
        if(rounds.length == 1){
             
            _div = wmul(rnd.totalInvested, 2 * 10**16);            
        } else {
            _div = wmul(rnd.totalInvested, DIVIDENDS_FRACTION);            
        }
        token.disburseDividends.value(_div)();
        totalDividendsPaid += _div;
        totalSharesSold += rnd.totalShares;
        totalEarningsGenerated += wmul(rnd.totalInvested, RETURNS_FRACTION);

        rnd.finalized = true;
    }

     
    function _updateReturns(address _investor, MobiusRound storage rnd) internal {
        if(rnd.investors[_investor].shares == 0) {
            return;
        }
        
        uint outstanding = _outstandingReturns(_investor, rnd);

         
        if (outstanding > 0) {
            vaults[_investor].totalReturns = add(vaults[_investor].totalReturns, outstanding);
        }

        rnd.investors[_investor].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
    }

    function _outstandingReturns(address _investor, MobiusRound storage rnd) internal view returns(uint) {
        if(rnd.investors[_investor].shares == 0) {
            return 0;
        }
         
        uint newReturns = sub(
            rnd.cumulativeReturnsPoints, 
            rnd.investors[_investor].lastCumulativeReturnsPoints
            );

        uint outstanding = 0;
        if(newReturns != 0) { 
             
             
            outstanding = mul(newReturns, rnd.investors[_investor].shares) / MULTIPLIER;
        }

        return outstanding;
    }

     
    function _splitRevenue(MobiusRound storage rnd, uint value, address ref) internal {
        uint roundReturns;
        uint returnsOffset;
        if(rounds.length == 1){
            returnsOffset = 13 * 10**16; 
        }
        if(ref != address(0x0)) {
             
            roundReturns = wmul(value, RETURNS_FRACTION - REFERRAL_FRACTION - returnsOffset);
            uint _ref = wmul(value, REFERRAL_FRACTION);
            vaults[ref].totalReturns = add(vaults[ref].totalReturns, _ref);            
            vaults[ref].refReturns = add(vaults[ref].refReturns, _ref);
            unclaimedReturns = add(unclaimedReturns, _ref);
        } else {
            roundReturns = wmul(value, RETURNS_FRACTION - returnsOffset);
        }
        
        uint airdrop = wmul(value, AIRDROP_FRACTION);
        uint jackpot = wmul(value, JACKPOT_FRACTION);
        
        uint dev;
         
         
         
         
        if(rounds.length == 1){
             
            dev = value / 4;  
            raisedICO += dev;
        } else {
            dev = value / DEV_DIVISOR;
        }
         
        if(rnd.totalShares == 0) {
            rnd.jackpot = add(rnd.jackpot, roundReturns);
        } else {
            _disburseReturns(rnd, roundReturns);
        }
        
        rnd.airdropPot = add(rnd.airdropPot, airdrop);
        rnd.jackpot = add(rnd.jackpot, jackpot);
        devBalance = add(devBalance, dev);
    }

    function _disburseReturns(MobiusRound storage rnd, uint value) internal {
        unclaimedReturns = add(unclaimedReturns, value); 
         
         
        if(rnd.totalShares == 0) {
            rnd.cumulativeReturnsPoints = mul(value, MULTIPLIER) / wdiv(value, rnd.price);
        } else {
            rnd.cumulativeReturnsPoints = add(
                rnd.cumulativeReturnsPoints, 
                mul(value, MULTIPLIER) / rnd.totalShares
            );
        }
    }

    function _issueShares(MobiusRound storage rnd, address _investor, uint value) internal returns(uint) {    
        if(rnd.investors[_investor].lastCumulativeReturnsPoints == 0) {
            rnd.investors[_investor].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
        }    
        
        uint newShares = wdiv(value, rnd.price);
        
         
        if(value >= 100 ether) {
            newShares = mul(newShares, 2); 
        } else if(value >= 10 ether) {
            newShares = add(newShares, newShares/2); 
        } else if(value >= 1 ether) {
            newShares = add(newShares, newShares/3); 
        } else if(value >= 100 finney) {
            newShares = add(newShares, newShares/10); 
        }

        rnd.investors[_investor].shares = add(rnd.investors[_investor].shares, newShares);
        rnd.totalShares = add(rnd.totalShares, newShares);
        emit SharesIssued(_investor, newShares);
        return newShares;
    }    

    function _airDrop(MobiusRound storage rnd, uint value) internal {
        require(msg.sender == tx.origin, "ONLY HOOMANS (or scripts that don't use smart contracts)!");
        if(value > 100 finney) {
             
            uint chance = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), now)));
            if(chance % 200 == 0) { 
                uint prize = rnd.airdropPot / 2; 
                rnd.airdropPot = rnd.airdropPot / 2;
                vaults[msg.sender].totalReturns = add(vaults[msg.sender].totalReturns, prize);
                unclaimedReturns = add(unclaimedReturns, prize);
                totalJackpotsWon += prize;
                emit AirdropWon(msg.sender, prize);
            }
        }
    }
}