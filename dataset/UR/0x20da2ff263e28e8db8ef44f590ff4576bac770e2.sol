 

pragma solidity ^0.4.24;

interface MilAuthInterface {
    function requiredSignatures() external view returns(uint256);
    function requiredDevSignatures() external view returns(uint256);
    function adminCount() external view returns(uint256);
    function devCount() external view returns(uint256);
    function adminName(address _who) external view returns(bytes32);
    function isAdmin(address _who) external view returns(bool);
    function isDev(address _who) external view returns(bool);
    function checkGameRegiester(address _gameAddr) external view returns(bool);
    function checkGameClosed(address _gameAddr) external view returns(bool);
}
interface MillionaireInterface {
    function invest(address _addr, uint256 _affID, uint256 _mfCoin, uint256 _general) external payable;
    function updateGenVaultAndMask(address _addr, uint256 _affID) external payable;
    function clearGenVaultAndMask(address _addr, uint256 _affID, uint256 _eth, uint256 _milFee) external;
    function assign(address _addr) external payable;
    function splitPot() external payable;   
}
interface MilFoldInterface {
    function addPot() external payable;
    function activate() external;    
}

contract Milevents {

     
    event onNewPlayer
    (
        address indexed playerAddress,
        uint256 playerID,
        uint256 timeStamp
    );

     
    event onEndTx
    (
        uint256 rid,                     
        address indexed buyerAddress,    
        uint256 compressData,            
        uint256 eth,                     
        uint256 totalPot,                
        uint256 tickets,                 
        uint256 timeStamp                
    );

     
    event onGameClose
    (
        address indexed gameAddr,        
        uint256 amount,                  
        uint256 timeStamp                
    );

     
    event onReward
    (
        address indexed         rewardAddr,      
        Mildatasets.RewardType  rewardType,      
        uint256 amount                           
    );

	 
    event onWithdraw
    (
        address indexed playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );

    event onAffiliatePayout
    (
        address indexed affiliateAddress,
        address indexed buyerAddress,
        uint256 eth,
        uint256 timeStamp
    );

     
    event onICO
    (
        address indexed buyerAddress,    
        uint256 buyAmount,               
        uint256 buyMf,                   
        uint256 totalIco,                
        bool    ended                    
    );

     
    event onPlayerWin(
        address indexed addr,
        uint256 roundID,
        uint256 winAmount,
        uint256 winNums
    );

    event onClaimWinner(
        address indexed addr,
        uint256 winnerNum,
        uint256 totalNum
    );

    event onBuyMFCoins(
        address indexed addr,
        uint256 ethAmount,
        uint256 mfAmount,
        uint256 timeStamp
    );

    event onSellMFCoins(
        address indexed addr,
        uint256 ethAmount,
        uint256 mfAmount,
        uint256 timeStamp
    );

    event onUpdateGenVault(
        address indexed addr,
        uint256 mfAmount,
        uint256 genAmount,
        uint256 ethAmount
    );
}

contract MilFold is MilFoldInterface,Milevents {
    using SafeMath for *;

 
 
 
 
    uint256     constant private    rndMax_ = 90000;                                         
    uint256     constant private    claimMax_ = 43200;                                       
    address     constant private    fundAddr_ = 0xB0c7Dc00E8A74c9dEc8688EFb98CcB2e24584E3B;  
    uint256     constant private    MIN_ETH_BUYIN = 0.002 ether;                             
    uint256     constant private    COMMON_REWARD_AMOUNT = 0.01 ether;                       
    uint256     constant private    CLAIM_WINNER_REWARD_AMOUNT = 1 ether;                    
    uint256     constant private    MAX_WIN_AMOUNT = 5000 ether;                             

    uint256     private             rID_;                                                    
    uint256     private             lID_;                                                    
    uint256     private             lBlockNumber_;                                           
    bool        private             activated_;                                              
    
    MillionaireInterface constant private millionaire_ = MillionaireInterface(0x98BDbc858822415C626c13267594fbC205182A1F);
    MilAuthInterface constant private milAuth_ = MilAuthInterface(0xf856f6a413f7756FfaF423aa2101b37E2B3aFFD9);

    mapping (address => uint256) private playerTickets_;                                     
    mapping (uint256 => Mildatasets.Round) private round_;                                   
    mapping (uint256 => mapping(address => uint256[])) private playerTicketNumbers_;         
    mapping (address => uint256) private playerWinTotal_;                                    

 
 
 
 
     
    modifier isActivated() {
        require(activated_ == true, "it's not ready yet");
        _;
    }

     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= MIN_ETH_BUYIN, "can't be less anymore");
        _;
    }

     
    modifier onlyDevs()
    {
        require(milAuth_.isDev(msg.sender) == true, "msg sender is not a dev");
        _;
    }

     
    modifier inSufficient(uint256 _eth, uint256[] _num) {
        uint256 totalTickets = _num.length;
        require(_eth >= totalTickets.mul(500)/1 ether, "insufficient to buy the very tickets");
        _;
    }

     
    modifier inSufficient2(uint256 _eth, uint256[] _startNums, uint256[] _endNums) {
        uint256 totalTickets = calcSectionTickets(_startNums, _endNums);
        require(_eth >= totalTickets.mul(500)/1 ether, "insufficient to buy the very tickets");
        _;
    }

     
    function() public isActivated() payable {
        addPot();
    }

     
    function buyTickets(uint256 _affID)
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        payable
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        buyCore(msg.sender, _affID, msg.value);

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            msg.value,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

     
    function expressBuyNums(uint256 _affID, uint256[] _nums)
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        inSufficient(msg.value, _nums)
        payable
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        buyCore(msg.sender, _affID, msg.value);
        convertCore(msg.sender, _nums.length, TicketCompressor.encode(_nums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            msg.value,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

     
    function expressBuyNumSec(uint256 _affID, uint256[] _startNums, uint256[] _endNums)
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        inSufficient2(msg.value, _startNums, _endNums)
        payable
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        buyCore(msg.sender, _affID, msg.value);
        convertCore(
            msg.sender,
            calcSectionTickets(_startNums, _endNums),
            TicketCompressor.encode(_startNums, _endNums)
        );

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            msg.value,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

     
    function reloadTickets(uint256 _affID, uint256 _eth)
        public
        isActivated()
        isHuman()
        isWithinLimits(_eth)
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        reloadCore(msg.sender, _affID, _eth);

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            _eth,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

     
    function expressReloadNums(uint256 _affID, uint256 _eth, uint256[] _nums)
        public
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        inSufficient(_eth, _nums)
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        reloadCore(msg.sender, _affID, _eth);
        convertCore(msg.sender, _nums.length, TicketCompressor.encode(_nums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            _eth,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

     
    function expressReloadNumSec(uint256 _affID, uint256 _eth, uint256[] _startNums, uint256[] _endNums)
        public
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        inSufficient2(_eth, _startNums, _endNums)
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        reloadCore(msg.sender, _affID, _eth);
        convertCore(msg.sender, calcSectionTickets(_startNums, _endNums), TicketCompressor.encode(_startNums, _endNums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            _eth,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

     
    function convertNums(uint256[] nums) public {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        convertCore(msg.sender, nums.length, TicketCompressor.encode(nums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            0,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

     
    function convertNumSec(uint256[] startNums, uint256[] endNums) public {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        convertCore(msg.sender, calcSectionTickets(startNums, endNums), TicketCompressor.encode(startNums, endNums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            0,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    function buyCore(address _addr, uint256 _affID, uint256 _eth)
        private
    {
         
         
        playerTickets_[_addr] = playerTickets_[_addr].add(_eth.mul(500)/1 ether);

         
        uint256 foundFee = _eth.div(50);
        fundAddr_.transfer(foundFee);

         
        uint256 milFee = _eth.mul(80).div(100);

        millionaire_.updateGenVaultAndMask.value(milFee)(_addr, _affID);

        round_[rID_].pot = round_[rID_].pot.add(_eth.sub(milFee).sub(foundFee));
    }

    function reloadCore(address _addr, uint256 _affID, uint256 _eth)
        private
    {
         
         
        uint256 milFee = _eth.mul(80).div(100);
        
        millionaire_.clearGenVaultAndMask(_addr, _affID, _eth, milFee);

         
        playerTickets_[_addr] = playerTickets_[_addr].add(_eth.mul(500)/1 ether);

         
        uint256 foundFee = _eth.div(50);
        fundAddr_.transfer(foundFee);
        
         
         
    }

    function convertCore(address _addr, uint256 length, uint256 compressNumber)
        private
    {
        playerTickets_[_addr] = playerTickets_[_addr].sub(length);
        uint256[] storage plyTicNums = playerTicketNumbers_[rID_][_addr];
        plyTicNums.push(compressNumber);
    }

     
     
     
     
     

    function checkRoundAndDraw(address _addr)
        private
        returns(uint256)
    {
        if (lID_ > 0
            && round_[lID_].state == Mildatasets.RoundState.STOPPED
            && (block.number.sub(lBlockNumber_) >= 7)) {
             
            round_[lID_].drawCode = calcDrawCode();
            round_[lID_].claimDeadline = now + claimMax_;
            round_[lID_].state = Mildatasets.RoundState.DRAWN;
            round_[lID_].blockNumber = block.number;
            
            round_[rID_].roundDeadline = now + rndMax_;
            
            if (round_[rID_].pot > COMMON_REWARD_AMOUNT) {
                round_[rID_].pot = round_[rID_].pot.sub(COMMON_REWARD_AMOUNT);
                 
                _addr.transfer(COMMON_REWARD_AMOUNT);
                
                emit onReward(_addr, Mildatasets.RewardType.DRAW, COMMON_REWARD_AMOUNT);
            }
            return lID_ << 96 | round_[lID_].claimDeadline << 64 | round_[lID_].drawCode << 32 | uint256(Mildatasets.TxAction.DRAW) << 8 | uint256(Mildatasets.RoundState.DRAWN);
        } else if (lID_ > 0
            && round_[lID_].state == Mildatasets.RoundState.DRAWN
            && now > round_[lID_].claimDeadline) {
             
            if (round_[lID_].totalNum > 0) {
                assignCore();
            }
            round_[lID_].state = Mildatasets.RoundState.ASSIGNED;
            
            if (round_[rID_].pot > COMMON_REWARD_AMOUNT) {
                round_[rID_].pot = round_[rID_].pot.sub(COMMON_REWARD_AMOUNT);
                 
                _addr.transfer(COMMON_REWARD_AMOUNT);
                
                emit onReward(_addr, Mildatasets.RewardType.ASSIGN, COMMON_REWARD_AMOUNT);
            }
            return lID_ << 96 | uint256(Mildatasets.TxAction.ASSIGN) << 8 | uint256(Mildatasets.RoundState.ASSIGNED);
        } else if ((rID_ == 1 || round_[lID_].state == Mildatasets.RoundState.ASSIGNED)
            && now >= round_[rID_].roundDeadline) {
             
            lID_ = rID_;
            lBlockNumber_ = block.number;
            round_[lID_].state = Mildatasets.RoundState.STOPPED;

            rID_ = rID_ + 1;

             
            round_[rID_].state = Mildatasets.RoundState.STARTED;
            if (round_[lID_].pot > COMMON_REWARD_AMOUNT) {
                round_[rID_].pot = round_[lID_].pot.sub(COMMON_REWARD_AMOUNT);
                
                 
                _addr.transfer(COMMON_REWARD_AMOUNT);
                
                emit onReward(_addr, Mildatasets.RewardType.END, COMMON_REWARD_AMOUNT);
            } else {
                round_[rID_].pot = round_[lID_].pot;
            }
            

            return rID_ << 96 | uint256(Mildatasets.TxAction.ENDROUND) << 8 | uint256(Mildatasets.RoundState.STARTED);
        } 
        return rID_ << 96 | uint256(Mildatasets.TxAction.BUY) << 8 | uint256(round_[rID_].state);
    }

     
    function claimWinner(address _addr)
        public
        isActivated()
        isHuman()
    {
        require(lID_ > 0 && round_[lID_].state == Mildatasets.RoundState.DRAWN && now <= round_[lID_].claimDeadline, "it's not time for claiming");
        require(round_[lID_].winnerNum[_addr] == 0, "the winner have been claimed already");

        uint winNum = 0;
        uint256[] storage ptns = playerTicketNumbers_[lID_][_addr];
        for (uint256 j = 0; j < ptns.length; j ++) {
            (uint256 tType, uint256 tLength, uint256[] memory playCvtNums) = TicketCompressor.decode(ptns[j]);
            for (uint256 k = 0; k < tLength; k ++) {
                if ((tType == 1 && playCvtNums[k] == round_[lID_].drawCode) ||
                    (tType == 2 && round_[lID_].drawCode >= playCvtNums[2 * k] && round_[lID_].drawCode <= playCvtNums[2 * k + 1])) {
                    winNum++;
                }
            }
        }
        
        if (winNum > 0) {
            if (round_[lID_].winnerNum[_addr] == 0) {
                round_[lID_].winners.push(_addr);
            }
            round_[lID_].totalNum = round_[lID_].totalNum.add(winNum);
            round_[lID_].winnerNum[_addr] = winNum;
            
            uint256 rewardAmount = CLAIM_WINNER_REWARD_AMOUNT.min(round_[lID_].pot.div(200));  
            
            round_[rID_].pot = round_[rID_].pot.sub(rewardAmount);
             
            msg.sender.transfer(rewardAmount);
            emit onReward(msg.sender, Mildatasets.RewardType.CLIAM, COMMON_REWARD_AMOUNT);
            
            emit onClaimWinner(
                _addr,
                winNum,
                round_[lID_].totalNum
            );
        }
    }

    function assignCore() private {
         
        uint256 lPot = round_[lID_].pot;
        uint256 totalWinNum = round_[lID_].totalNum;
        uint256 winShareAmount = (MAX_WIN_AMOUNT.mul(totalWinNum)).min(lPot.div(2));
        uint256 foundFee = lPot.div(50);

        fundAddr_.transfer(foundFee);

        uint256 avgShare = winShareAmount / totalWinNum;
        for (uint256 idx = 0; idx < round_[lID_].winners.length; idx ++) {
            address addr = round_[lID_].winners[idx];
            uint256 num = round_[lID_].winnerNum[round_[lID_].winners[idx]];
            uint256 amount = round_[lID_].winnerNum[round_[lID_].winners[idx]].mul(avgShare);

            millionaire_.assign.value(amount)(addr);
            playerWinTotal_[addr] = playerWinTotal_[addr].add(amount);

            emit onPlayerWin(addr, lID_, amount, num);
        }

        round_[rID_].pot = round_[rID_].pot.sub(winShareAmount).sub(foundFee);
    }

    function calcSectionTickets(uint256[] startNums, uint256[] endNums)
        private
        pure
        returns(uint256)
    {
        require(startNums.length == endNums.length, "tickets length invalid");
        uint256 totalTickets = 0;
        uint256 tickets = 0;
        for (uint256 i = 0; i < startNums.length; i ++) {
            tickets = endNums[i].sub(startNums[i]).add(1);
            totalTickets = totalTickets.add(tickets);
        }
        return totalTickets;
    }

    function calcDrawCode() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(

            ((uint256(keccak256(abi.encodePacked(blockhash(block.number))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 2))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 3))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 4))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 5))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 6))))) / (block.timestamp))

        ))) % 10000000;

    }

    function activate() public {
         
        require(msg.sender == address(millionaire_), "only contract millionaire can activate");

         
        require(activated_ == false, "MilFold already activated");

         
        activated_ = true;

         
        rID_ = 1;
        round_[1].roundDeadline = now + rndMax_;
        round_[1].state = Mildatasets.RoundState.STARTED;
         
        round_[1].pot = round_[0].pot;
    }

    function addPot()
        public
        payable {
        require(milAuth_.checkGameClosed(address(this)) == false, "game already closed");
        require(msg.value > 0, "add pot failed");
        round_[rID_].pot = round_[rID_].pot.add(msg.value);
    }

    function close()
        public
        isActivated
        onlyDevs {
        require(milAuth_.checkGameClosed(address(this)), "game no closed");
        activated_ = false;
        millionaire_.splitPot.value(address(this).balance)();
    }

     
    function getPlayerAccount(address _addr)
        public
        view
        returns(uint256, uint256)
    {
        return (playerTickets_[_addr], playerWinTotal_[_addr]);
    }

     
    function getPlayerRoundNums(uint256 _rid, address _addr)
        public
        view
        returns(uint256[])
    {
        return playerTicketNumbers_[_rid][_addr];
    }

     
    function getPlayerRoundWinningInfo(uint256 _rid, address _addr)
        public
        view
        returns(uint256)
    {
        Mildatasets.RoundState state = round_[_rid].state;
        if (state >= Mildatasets.RoundState.UNKNOWN && state < Mildatasets.RoundState.DRAWN) {
            return 0;
        } else if (state == Mildatasets.RoundState.ASSIGNED) {
            return round_[_rid].winnerNum[_addr];
        } else {
             
            uint256[] storage ptns = playerTicketNumbers_[_rid][_addr];
            uint256 nums = 0;
            for (uint256 j = 0; j < ptns.length; j ++) {
                (uint256 tType, uint256 tLength, uint256[] memory playCvtNums) = TicketCompressor.decode(ptns[j]);
                for (uint256 k = 0; k < tLength; k ++) {
                    if ((tType == 1 && playCvtNums[k] == round_[_rid].drawCode) ||
                        (tType == 2 && round_[_rid].drawCode >= playCvtNums[2 * k] && round_[lID_].drawCode <= playCvtNums[2 * k + 1])) {
                        nums ++;
                    }
                }
            }

            return nums;
        }
    }

     
    function checkPlayerClaimed(uint256 _rid, address _addr)
        public
        view
        returns(bool) {
        return round_[_rid].winnerNum[_addr] > 0;
    }

     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        return (
            rID_,
            uint256(round_[lID_].state),
            round_[rID_].roundDeadline,
            round_[lID_].claimDeadline,
            round_[rID_].pot
        );
    }

     
    function getHistoryRoundInfo(uint256 _rid)
        public
        view
        returns(uint256[], address[], uint256[])
    {
        uint256 length = round_[_rid].winners.length;
        uint256[] memory numbers = new uint256[](length);
        if (round_[_rid].winners.length > 0) {
            for (uint256 idx = 0; idx < length; idx ++) {
                numbers[idx] = round_[_rid].winnerNum[round_[_rid].winners[idx]];
            }
        }

        uint256[] memory items = new uint256[](6);
        items[0] = uint256(round_[_rid].state);
        items[1] = round_[_rid].roundDeadline;
        items[2] = round_[_rid].claimDeadline;
        items[3] = round_[_rid].drawCode;
        items[4] = round_[_rid].pot;
        items[5] = round_[_rid].blockNumber;

        return (items, round_[_rid].winners, numbers);
    }

}

 
 
 
 
library Mildatasets {

     
    enum RoundState {
        UNKNOWN,         
        STARTED,         
        STOPPED,         
        DRAWN,           
        ASSIGNED         
    }

     
    enum TxAction {
        UNKNOWN,         
        BUY,             
        DRAW,            
        ASSIGN,          
        ENDROUND         
    }

     
    enum RewardType {
        UNKNOWN,         
        DRAW,            
        ASSIGN,          
        END,             
        CLIAM            
    }

    struct Player {
        uint256 playerID;        
        uint256 eth;             
        uint256 mask;            
        uint256 genTotal;        
        uint256 affTotal;        
        uint256 laff;            
    }

    struct Round {
        uint256                         roundDeadline;       
        uint256                         claimDeadline;       
        uint256                         pot;                 
        uint256                         blockNumber;         
        RoundState                      state;               
        uint256                         drawCode;            
        uint256                         totalNum;            
        mapping (address => uint256)    winnerNum;           
        address[]                       winners;             
    }

}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

     
    function pwr(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}

library TicketCompressor {

    uint256 constant private mask = 16777215;  

    function encode(uint256[] tickets)
        internal
        pure
        returns(uint256)
    {
        require((tickets.length > 0) && (tickets.length <= 10), "tickets must > 0 and <= 10");

        uint256 value = tickets[0];
        for (uint256 i = 1 ; i < tickets.length ; i++) {
            require(tickets[i] < 10000000, "ticket number must < 10000000");
            value = value << 24 | tickets[i];
        }
        return 1 << 248 | tickets.length << 240 | value;
    }

    function encode(uint256[] startTickets, uint256[] endTickets)
        internal
        pure
        returns(uint256)
    {
        require(startTickets.length > 0 && startTickets.length == endTickets.length && startTickets.length <= 5, "section tickets must > 0 and <= 5");

        uint256 value = startTickets[0] << 24 | endTickets[0];
        for (uint256 i = 1 ; i < startTickets.length ; i++) {
            require(startTickets[i] <= endTickets[i] && endTickets[i] < 10000000, "tickets number invalid");
            value = value << 48 | startTickets[i] << 24 | endTickets[i];
        }
        return 2 << 248 | startTickets.length << 240 | value;
    }

    function decode(uint256 _input)
	    internal
	    pure
	    returns(uint256,uint256,uint256[])
    {
        uint256 _type = _input >> 248;
        uint256 _length = _input >> 240 & 127;
        require(_type == 1 || _type == 2, "decode type is incorrect!");


        if (_type == 1) {
            uint256[] memory results = new uint256[](_length);
            uint256 tempVal = _input;
            for (uint256 i=0 ; i < _length ; i++) {
                results[i] = tempVal & mask;
                tempVal = tempVal >> 24;
            }
            return (_type,_length,results);
        } else {
            uint256[] memory result2 = new uint256[](_length * 2);
            uint256 tempVal2 = _input;
            for (uint256 j=0 ; j < _length ; j++) {
                result2[2 * j + 1] = tempVal2 & mask;
                tempVal2 = tempVal2 >> 24;
                result2[2 * j] = tempVal2 & mask;
                tempVal2 = tempVal2 >> 24;
            }
            return (_type,_length,result2);
        }
    }

}