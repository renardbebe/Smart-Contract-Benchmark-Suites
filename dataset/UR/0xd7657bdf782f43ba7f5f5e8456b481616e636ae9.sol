 

pragma solidity ^0.4.24;

 

library Helper {
    using SafeMath for uint256;

    uint256 constant public ZOOM = 1000;
    uint256 constant public SDIVIDER = 3450000;
    uint256 constant public PDIVIDER = 3450000;
    uint256 constant public RDIVIDER = 1580000;
     
    uint256 constant public SLP = 0.002 ether;
     
    uint256 constant public SAT = 30;  
     
    uint256 constant public PN = 777;
     
    uint256 constant public PBASE = 13;
    uint256 constant public PMULTI = 26;
    uint256 constant public LBase = 15;

    uint256 constant public ONE_HOUR = 3600;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR;
     
    uint256 constant public TIMEOUT1 = 12 * ONE_HOUR;
    
    function bytes32ToString (bytes32 data)
        public
        pure
        returns (string) 
    {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
    
    function uintToBytes32(uint256 n)
        public
        pure
        returns (bytes32) 
    {
        return bytes32(n);
    }
    
    function bytes32ToUint(bytes32 n) 
        public
        pure
        returns (uint256) 
    {
        return uint256(n);
    }
    
    function stringToBytes32(string memory source) 
        public
        pure
        returns (bytes32 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function stringToUint(string memory source) 
        public
        pure
        returns (uint256)
    {
        return bytes32ToUint(stringToBytes32(source));
    }
    
    function uintToString(uint256 _uint) 
        public
        pure
        returns (string)
    {
        return bytes32ToString(uintToBytes32(_uint));
    }

 
    function validUsername(string _username)
        public
        pure
        returns(bool)
    {
        uint256 len = bytes(_username).length;
         
        if ((len < 4) || (len > 18)) return false;
         
        if (bytes(_username)[len-1] == 32) return false;
         
        return uint256(bytes(_username)[0]) != 48;
    }

     

     
    function getAddedTime(uint256 _rTicketSum, uint256 _tAmount)
        public
        pure
        returns (uint256)
    {
         
        uint256 base = (_rTicketSum + 1).mul(10000) / SDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo);  
        expo = expo.mul(expo);  
         
        expo = expo / (10**24);

        if (expo > SAT) return 0;
        return (SAT - expo).mul(_tAmount);
    }

    function getNewEndTime(uint256 toAddTime, uint256 slideEndTime, uint256 fixedEndTime)
        public
        view
        returns(uint256)
    {
        uint256 _slideEndTime = (slideEndTime).add(toAddTime);
        uint256 timeout = _slideEndTime.sub(block.timestamp);
         
        if (timeout > TIMEOUT1) timeout = TIMEOUT1;
        _slideEndTime = (block.timestamp).add(timeout);
         
        if (_slideEndTime > fixedEndTime)  return fixedEndTime;
        return _slideEndTime;
    }

     
    function getRandom(uint256 _seed, uint256 _range)
        public
        pure
        returns(uint256)
    {
        if (_range == 0) return _seed;
        return (_seed % _range) + 1;
    }


    function getEarlyIncomeMul(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
         
        uint256 base = _ticketSum * ZOOM / RDIVIDER;
        uint256 expo = base.mul(base).mul(base);  
        expo = expo.mul(expo) / (ZOOM**6);  
        return (1 + PBASE / (1 + expo.mul(PMULTI)));
    }

     
    function getTAmount(uint256 _ethAmount, uint256 _ticketSum) 
        public
        pure
        returns(uint256)
    {
        uint256 _tPrice = getTPrice(_ticketSum);
        return _ethAmount.div(_tPrice);
    }

     
    function getTMul(uint256 _ticketSum)  
        public
        pure
        returns(uint256)
    {
        uint256 base = _ticketSum * ZOOM / PDIVIDER;
        uint256 expo = base.mul(base).mul(base);
        expo = expo.mul(expo);  
        return 1 + expo.mul(LBase) / (10**18);
    }

     
     
    function getTPrice(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        uint256 base = (_ticketSum + 1).mul(ZOOM) / PDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo);  
        expo = expo.mul(expo);  
        uint256 tPrice = SLP + expo / PN;
        return tPrice;
    }

     
    function getSlotWeight(uint256 _ethAmount, uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        uint256 _tAmount = getTAmount(_ethAmount, _ticketSum);
        uint256 _tMul = getTMul(_ticketSum);
        return (_tAmount).mul(_tMul);
    }

     
     
     
    function getWeightRange(uint256 grandPot, uint256 initGrandPot, uint256 curRWeight)
        public
        pure
        returns(uint256)
    {
         
        uint256 grandPotInvest = grandPot - initGrandPot;
        if (grandPotInvest == 0) return 8;
        uint256 zoomMul = grandPot * ZOOM / grandPotInvest;
        uint256 weightRange = zoomMul * curRWeight / ZOOM;
        if (weightRange < curRWeight) weightRange = curRWeight;
        return weightRange;
    }
}

interface F2mInterface {
    function joinNetwork(address[6] _contract) public;
     
    function disableRound0() public;
    function activeBuy() public;
     
    function pushDividends() public payable;
     
     
     
    function buyFor(address _buyer) public payable;
    function sell(uint256 _tokenAmount) public;
    function exit() public;
    function devTeamWithdraw() public returns(uint256);
    function withdrawFor(address sender) public returns(uint256);
    function transfer(address _to, uint256 _tokenAmount) public returns(bool);
     
    function setAutoBuy() public;
     
     
    function ethBalance(address _address) public view returns(uint256);
    function myBalance() public view returns(uint256);
    function myEthBalance() public view returns(uint256);

    function swapToken() public;
    function setNewToken(address _newTokenAddress) public;
}

interface BankInterface {
    function joinNetwork(address[6] _contract) public;
     
    function pushToBank(address _player) public payable;
}


interface DevTeamInterface {
    function setF2mAddress(address _address) public;
    function setLotteryAddress(address _address) public;
    function setCitizenAddress(address _address) public;
    function setBankAddress(address _address) public;
    function setRewardAddress(address _address) public;
    function setWhitelistAddress(address _address) public;

    function setupNetwork() public;
}

interface LotteryInterface {
    function joinNetwork(address[6] _contract) public;
     
    function activeFirstRound() public;
     
    function pushToPot() public payable;
    function finalizeable() public view returns(bool);
     
    function finalize() public;
    function buy(string _sSalt) public payable;
    function buyFor(string _sSalt, address _sender) public payable;
     
    function withdrawFor(address _sender) public returns(uint256);

    function getRewardBalance(address _buyer) public view returns(uint256);
    function getTotalPot() public view returns(uint256);
     
    function getEarlyIncomeByAddress(address _buyer) public view returns(uint256);
     
     
    function getCurEarlyIncomeByAddress(address _buyer) public view returns(uint256);
     
    function getCurRoundId() public view returns(uint256);
     
    function setLastRound(uint256 _lastRoundId) public;
    function getPInvestedSumByRound(uint256 _rId, address _buyer) public view returns(uint256);
    function cashoutable(address _address) public view returns(bool);
    function isLastRound() public view returns(bool);
}

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Citizen {
    using SafeMath for uint256;

    event Register(address indexed _member, address indexed _ref);

    modifier withdrawRight(){
        require((msg.sender == address(bankContract)), "Bank only");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == devTeam, "admin required");
        _;
    }

    modifier notRegistered(){
        require(!isCitizen[msg.sender], "already exist");
        _;
    }

    modifier registered(){
        require(isCitizen[msg.sender], "must be a citizen");
        _;
    }

    struct Profile{
        uint256 id;
        uint256 username;
        uint256 refWallet;
        address ref;
        address[] refTo;
        uint256 totalChild;
        uint256 donated;
        uint256 treeLevel;
         
        uint256 totalSale;
        uint256 allRoundRefIncome;
        mapping(uint256 => uint256) roundRefIncome;
        mapping(uint256 => uint256) roundRefWallet;
    }

     
    mapping (address => Profile) public citizen;
    mapping (address => bool) public isCitizen;
    mapping (uint256 => address) public idAddress;
    mapping (uint256 => address) public usernameAddress;

    mapping (uint256 => address[]) levelCitizen;

    BankInterface bankContract;
    LotteryInterface lotteryContract;
    F2mInterface f2mContract;
    address devTeam;

    uint256 citizenNr;
    uint256 lastLevel;

     
    mapping(uint256 => uint256) public totalRefByRound;
    uint256 public totalRefAllround;

    constructor (address _devTeam)
        public
    {
        DevTeamInterface(_devTeam).setCitizenAddress(address(this));
        devTeam = _devTeam;

         
        citizenNr = 1;
        idAddress[1] = devTeam;
        isCitizen[devTeam] = true;
         
        citizen[devTeam].ref = devTeam;
         
        uint256 _username = Helper.stringToUint("f2m");
        citizen[devTeam].username = _username;
        usernameAddress[_username] = devTeam; 
        citizen[devTeam].id = 1;
        citizen[devTeam].treeLevel = 1;
        levelCitizen[1].push(devTeam);
        lastLevel = 1;
    }

     
    function joinNetwork(address[6] _contract)
        public
    {
        require(address(lotteryContract) == 0,"already setup");
        f2mContract = F2mInterface(_contract[0]);
        bankContract = BankInterface(_contract[1]);
        lotteryContract = LotteryInterface(_contract[3]);
    }

     
    function updateTotalChild(address _address)
        private
    {
        address _member = _address;
        while(_member != devTeam) {
            _member = getRef(_member);
            citizen[_member].totalChild ++;
        }
    }

    function register(string _sUsername, address _ref)
        public
        notRegistered()
    {
        require(Helper.validUsername(_sUsername), "invalid username");
        address sender = msg.sender;
        uint256 _username = Helper.stringToUint(_sUsername);
        require(usernameAddress[_username] == 0x0, "username already exist");
        usernameAddress[_username] = sender;
         
        address validRef = isCitizen[_ref] ? _ref : devTeam;

         
        isCitizen[sender] = true;
        citizen[sender].username = _username;
        citizen[sender].ref = validRef;
        citizenNr++;

        idAddress[citizenNr] = sender;
        citizen[sender].id = citizenNr;
        
        uint256 refLevel = citizen[validRef].treeLevel;
        if (refLevel == lastLevel) lastLevel++;
        citizen[sender].treeLevel = refLevel + 1;
        levelCitizen[refLevel + 1].push(sender);
         
        citizen[validRef].refTo.push(sender);
        updateTotalChild(sender);
        emit Register(sender, validRef);
    }

    function updateUsername(string _sNewUsername)
        public
        registered()
    {
        require(Helper.validUsername(_sNewUsername), "invalid username");
        address sender = msg.sender;
        uint256 _newUsername = Helper.stringToUint(_sNewUsername);
        require(usernameAddress[_newUsername] == 0x0, "username already exist");
        uint256 _oldUsername = citizen[sender].username;
        citizen[sender].username = _newUsername;
        usernameAddress[_oldUsername] = 0x0;
        usernameAddress[_newUsername] = sender;
    }

     
    function pushRefIncome(address _sender)
        public
        payable
    {
        uint256 curRoundId = lotteryContract.getCurRoundId();
        uint256 _amount = msg.value;
        address sender = _sender;
        address ref = getRef(sender);
         
        citizen[sender].totalSale += _amount;
        totalRefAllround += _amount;
        totalRefByRound[curRoundId] += _amount;
         
         
        while (sender != devTeam) {
            _amount = _amount / 2;
            citizen[ref].refWallet = _amount.add(citizen[ref].refWallet);
            citizen[ref].roundRefIncome[curRoundId] += _amount;
            citizen[ref].allRoundRefIncome += _amount;
            sender = ref;
            ref = getRef(sender);
        }
        citizen[sender].refWallet = _amount.add(citizen[ref].refWallet);
         
        citizen[sender].roundRefIncome[curRoundId] += _amount;
        citizen[sender].allRoundRefIncome += _amount;
    }

    function withdrawFor(address sender) 
        public
        withdrawRight()
        returns(uint256)
    {
        uint256 amount = citizen[sender].refWallet;
        if (amount == 0) return 0;
        citizen[sender].refWallet = 0;
        bankContract.pushToBank.value(amount)(sender);
        return amount;
    }

    function devTeamWithdraw()
        public
        onlyAdmin()
    {
        uint256 _amount = citizen[devTeam].refWallet;
        if (_amount == 0) return;
        devTeam.transfer(_amount);
        citizen[devTeam].refWallet = 0;
    }

    function devTeamReinvest()
        public
        returns(uint256)
    {
        address sender = msg.sender;
        require(sender == address(f2mContract), "only f2m contract");
        uint256 _amount = citizen[devTeam].refWallet;
        citizen[devTeam].refWallet = 0;
        address(f2mContract).transfer(_amount);
        return _amount;
    }

     

    function getTotalChild(address _address)
        public
        view
        returns(uint256)
    {
        return citizen[_address].totalChild;
    }

    function getAllRoundRefIncome(address _address)
        public
        view
        returns(uint256)
    {
        return citizen[_address].allRoundRefIncome;
    }

    function getRoundRefIncome(address _address, uint256 _rId)
        public
        view
        returns(uint256)
    {
        return citizen[_address].roundRefIncome[_rId];
    }

    function getRefWallet(address _address)
        public
        view
        returns(uint256)
    {
        return citizen[_address].refWallet;
    }

    function getAddressById(uint256 _id)
        public
        view
        returns (address)
    {
        return idAddress[_id];
    }

    function getAddressByUserName(string _username)
        public
        view
        returns (address)
    {
        return usernameAddress[Helper.stringToUint(_username)];
    }

    function exist(string _username)
        public
        view
        returns (bool)
    {
        return usernameAddress[Helper.stringToUint(_username)] != 0x0;
    }

    function getId(address _address)
        public
        view
        returns (uint256)
    {
        return citizen[_address].id;
    }

    function getUsername(address _address)
        public
        view
        returns (string)
    {
        if (!isCitizen[_address]) return "";
        return Helper.uintToString(citizen[_address].username);
    }

    function getUintUsername(address _address)
        public
        view
        returns (uint256)
    {
        return citizen[_address].username;
    }

    function getRef(address _address)
        public
        view
        returns (address)
    {
        return citizen[_address].ref == 0x0 ? devTeam : citizen[_address].ref;
    }

    function getRefTo(address _address)
        public
        view
        returns (address[])
    {
        return citizen[_address].refTo;
    }

    function getRefToById(address _address, uint256 _id)
        public
        view
        returns (address, string, uint256, uint256, uint256, uint256)
    {
        address _refTo = citizen[_address].refTo[_id];
        return (
            _refTo,
            Helper.uintToString(citizen[_refTo].username),
            citizen[_refTo].treeLevel,
            citizen[_refTo].refTo.length,
            citizen[_refTo].refWallet,
            citizen[_refTo].totalSale
            );
    }

    function getRefToLength(address _address)
        public
        view
        returns (uint256)
    {
        return citizen[_address].refTo.length;
    }

    function getLevelCitizenLength(uint256 _level)
        public
        view
        returns (uint256)
    {
        return levelCitizen[_level].length;
    }

    function getLevelCitizenById(uint256 _level, uint256 _id)
        public
        view
        returns (address)
    {
        return levelCitizen[_level][_id];
    }

    function getCitizenLevel(address _address)
        public
        view
        returns (uint256)
    {
        return citizen[_address].treeLevel;
    }

    function getLastLevel()
        public
        view
        returns(uint256)
    {
        return lastLevel;
    }

}