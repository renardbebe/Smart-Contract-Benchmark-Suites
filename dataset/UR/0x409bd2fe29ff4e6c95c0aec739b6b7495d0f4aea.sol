 

pragma solidity >=0.4.22 <0.6.0;

contract StakeWar {
     
    event Staking(bool isSoviet, address addr, uint256 value);
    event LeaderboardUpdated();
    event VoteBought(bool isSoviet, address addr, uint256 value);
    event GameStateChanged(uint8 state);
    event ChangedImageApproval(uint8 approval, address playerAddr);
    event SeedPaid(address addr, uint256 value);
    event SettingsChanged();
    
    address payable chairman;
    uint256 public constant unlockFromInit = 20 hours;
    DividendToken dividendToken;
    address public constant dividendTokenAddr = 0x8a6A9eFdC77530bf73b05d1005089aBF1B13687C;

     
    uint8 public imgInitialApproval = 1;  
    bool public noDividendBadPerform = true;
     

    struct Player {
        address payable addr;
        bytes32 name;
        string img;
        uint8 imgApproval;
    }
    mapping (address => Player) public players;
    mapping (bytes32 => address payable) public campaignLinks;

    struct Settings {
        uint8 presidentTotalPercent;
        uint8 presidentSalaryPercent;
        uint8 voteAdditionPercent;
        uint8 maxStakeLeadPercent;
        uint8 maximumVoteLeadPercent;
        uint8 behindBonusPercent;
        uint8 payoutDividendPercent;
        uint8 unrestrictedStakingPercent;
        uint8 seedersProfitPercent;
        uint256 timeIncrement;
        uint256 minimumStaking;
        uint256 minimumVote;
        uint256 unlockFromInit;
        uint256 unlockFromSeeding;
    }
    struct Round {
        uint256 potSize;
        uint256 sovietAllianceBonus;
        uint256 usAllianceBonus;
        uint256 presidentPot;
        uint256 seed;
        uint256 deadline;
        uint8 gameState; 

        address sovietToken;
        address usToken;
        address seederToken;

        address payable[5] sovietLeaderboard;
        address payable[5] usLeaderboard;
        
        mapping (address => uint256) presidentSalaries;
        mapping (address => uint256) sovietVotes;
        mapping (address => uint256) usVotes;
    }

    mapping (uint256 => Settings) public settings;
    mapping (uint256 => Round) public rounds;
    uint256 public currentRound = 1;
    uint256 public unlockedFrom;

     
    function getPresidentTotalPercent(uint256 round) public view returns(uint256) { return settings[round].presidentTotalPercent;}
    function getPresidentSalaryPercent(uint256 round) public view returns(uint256) { return settings[round].presidentSalaryPercent;}
    function getVoteAdditionPercent(uint256 round) public view returns(uint256) { return settings[round].voteAdditionPercent;}
    function getMaxStakeLeadPercent(uint256 round) public view returns(uint256) { return settings[round].maxStakeLeadPercent;}
    function getMaximumVoteLeadPercent(uint256 round) public view returns(uint256) { return settings[round].maximumVoteLeadPercent;}
    function getBehindBonusPercent(uint256 round) public view returns(uint256) { return settings[round].behindBonusPercent;}
    function getPayoutDividendPercent(uint256 round) public view returns(uint256) { return settings[round].payoutDividendPercent;}
    function getTimeIncrement(uint256 round) public view returns(uint256) { return settings[round].timeIncrement;}
    function getMinimumStaking(uint256 round) public view returns(uint256) { return settings[round].minimumStaking;}
    function getMinimumVote(uint256 round) public view returns(uint256) { return settings[round].minimumVote;}
    function getUnrestrictedStakingPercent(uint256 round) public view returns(uint256) { return settings[round].unrestrictedStakingPercent;}
    function getUnlockFromInit(uint256 round) public view returns(uint256) { return settings[round].unlockFromInit;}
    function getUnlockFromSeeding(uint256 round) public view returns(uint256) { return settings[round].unlockFromSeeding;}
    function getSeedersProfitPercent(uint256 round) public view returns(uint256) { return settings[round].seedersProfitPercent;}
    function getGameState(uint256 round) public view returns(uint256) { return rounds[round].gameState;}
    function getDeadline(uint256 round) public view returns(uint256) { return rounds[round].deadline;}
    function getPresidentSalaries(uint256 round, address addr) public view returns(uint256) { return rounds[round].presidentSalaries[addr];}
    function getSovietTotalEquity(uint256 round) public view returns(uint256) { return BondToken(rounds[round].sovietToken).totalMinted(); }
    function getUsTotalEquity(uint256 round) public view returns(uint256) { return BondToken(rounds[round].usToken).totalMinted(); }
    function getPotSize(uint256 round) public view returns(uint256) { return rounds[round].potSize;}
    function getSovietAllianceBonus(uint256 round) public view returns(uint256) { return rounds[round].sovietAllianceBonus;}
    function getUsAllianceBonus(uint256 round) public view returns(uint256) { return rounds[round].usAllianceBonus;}
    function getPresidentPot(uint256 round) public view returns(uint256) { return rounds[round].presidentPot;}
    function getSeed(uint256 round) public view returns(uint256) { return rounds[round].seed;}
    function getSeedersTotalProfit(uint256 round) public view returns(uint256) { 
        bool sovietsWon = getSovietTotalEquity(round) > getUsTotalEquity(round);
        uint256 funds;
        if (sovietsWon) {
            funds = rounds[round].usAllianceBonus;
        } else {
            funds = rounds[round].sovietAllianceBonus;
        }

        uint256 seedersTotalProfit = SafeMath.div(SafeMath.mul(BondToken(getSeederToken(round)).totalMinted(), getSeedersProfitPercent(round)), 100);
        if (funds < seedersTotalProfit) {
            seedersTotalProfit = funds;
        }
        return seedersTotalProfit;
    }
    function getSeederToken(uint256 round) public view returns(address) { return rounds[round].seederToken;}
    function getSeedersProfit(uint256 round, address addr) public view returns(uint256) { 
        uint256 totalSeedersTokens = BondToken(rounds[round].seederToken).totalMinted();
        if (totalSeedersTokens == 0) {
            return 0;
        }
        return SafeMath.div(SafeMath.mul(BondToken(rounds[round].seederToken).balanceOf(addr), getSeedersTotalProfit(round)), totalSeedersTokens);
    }
    function getSeedersEquity(uint256 round, address addr) public view returns(uint256) { 
        return BondToken(rounds[round].seederToken).balanceOf(addr);
    }
    function getToken(bool isSoviet, uint256 round) public view returns(address) {
        if (isSoviet) {
            return rounds[round].sovietToken;
        } else {
            return rounds[round].usToken;
        }
    }
    function getEquity(bool isSoviet, uint256 round, address addr) public view returns(uint256) {
        if (isSoviet) {
            return BondToken(rounds[round].sovietToken).balanceOf(addr);
        } else {
            return BondToken(rounds[round].usToken).balanceOf(addr);
        }
    }
    function getTotalEquity(bool isSoviet, uint256 round) public view returns(uint256) {
        if (isSoviet) {
            return BondToken(rounds[round].sovietToken).totalMinted();
        } else {
            return BondToken(rounds[round].usToken).totalMinted();
        }
    }
    function getVotes(bool isSoviet, uint256 round, address addr) public view returns(uint256) {
        if (isSoviet) {
            return rounds[round].sovietVotes[addr];
        } else {
            return rounds[round].usVotes[addr];
        }
    }
    function getLeaderboard(bool isSoviet, uint256 round, uint256 i) public view returns(address payable) {
        if (isSoviet) {
            return rounds[round].sovietLeaderboard[i];
        } else {
            return rounds[round].usLeaderboard[i];
        }
    }
    
    constructor() public {
        chairman = msg.sender;
        dividendToken = DividendToken(dividendTokenAddr);
        unlockedFrom = SafeMath.add(now, unlockFromInit);
        loadDefaultSettings();
    }

    function seedPot() external payable {
        require(rounds[currentRound].gameState == 1, "Game not in seeding state");
        
        rounds[currentRound].potSize = SafeMath.add(rounds[currentRound].potSize, msg.value);
        rounds[currentRound].seed = SafeMath.add(rounds[currentRound].seed, msg.value);
        BondToken(rounds[currentRound].seederToken).mint(msg.sender, msg.value);
        emit SeedPaid(msg.sender, msg.value);
    }
    
    function loadDefaultSettings() public {
        require(msg.sender == chairman || now > unlockedFrom, "Chairman only function");
        require(rounds[currentRound].gameState == 0, "Game not in init state");
        require(getPresidentTotalPercent(currentRound) == 0);

        if (currentRound > 1) {
            settings[currentRound] = settings[SafeMath.sub(currentRound,1)];
        } else {
            settings[currentRound] = Settings({ 
                presidentTotalPercent: 10,
                presidentSalaryPercent: 20,
                voteAdditionPercent: 20,
                maxStakeLeadPercent: 60,
                maximumVoteLeadPercent: 105,
                behindBonusPercent: 120,
                payoutDividendPercent: 20,
                unrestrictedStakingPercent: 100,
                seedersProfitPercent: 150,
                timeIncrement: 1 days,
                minimumStaking: 1 finney,
                minimumVote: 10 finney,
                unlockFromInit: 20 hours,
                unlockFromSeeding: 48 hours
            });
        }
    }
    
    function startSeeding() external {
        require(msg.sender == chairman || now > unlockedFrom, "Chairman only function");
        require(rounds[currentRound].gameState == 0, "Game not in init state");

        if (getPresidentTotalPercent(currentRound) == 0) {
            loadDefaultSettings();
        }
        unlockedFrom = SafeMath.add(now, getUnlockFromSeeding(currentRound));
        rounds[currentRound].gameState = 1;
        setupTokens();
        
        emit GameStateChanged(rounds[currentRound].gameState);
    }

    function startRound() external {
        require(msg.sender == chairman || now > unlockedFrom, "Chairman only function");
        require(rounds[currentRound].gameState == 1, "Game not in seeding state");
        require(rounds[currentRound].seed > 0, "Cannot start without seeding");

        rounds[currentRound].deadline = SafeMath.add(now, getTimeIncrement(currentRound));
        rounds[currentRound].gameState = 2;
        
        emit GameStateChanged(rounds[currentRound].gameState);
    }
    
    function stopRound() external {
        require(now > rounds[currentRound].deadline, "Time has not run out yet");
        require(rounds[currentRound].gameState == 2, "Game not in running state");
        require(getUsTotalEquity(currentRound) > 0 || getSovietTotalEquity(currentRound) > 0, "Cannot stop if noone staked");

        rounds[currentRound].gameState = 3;
        emit GameStateChanged(rounds[currentRound].gameState);
        unlockedFrom = SafeMath.add(now, getUnlockFromInit(currentRound));
        currentRound = SafeMath.add(currentRound, 1);
        rounds[currentRound].gameState = 0;
        fundNewRound();
    }

    function setupTokens() private {
        string memory roundStr = uint2str(currentRound);
        BondToken _sovietToken = new BondToken(string(abi.encodePacked("Soviet War Bonds - Stakewar.com Round ", roundStr)), string(abi.encodePacked("SU", roundStr)), true, currentRound);
        rounds[currentRound].sovietToken = address(_sovietToken);
        BondToken _usToken = new BondToken(string(abi.encodePacked("US War Bonds - Stakewar.com Round ", roundStr)), string(abi.encodePacked("US", roundStr)), false, currentRound);
        rounds[currentRound].usToken = address(_usToken);
        BondToken _seederToken = new BondToken(string(abi.encodePacked("Seed Bonds - Stakewar.com Round ", roundStr)), string(abi.encodePacked("SD", roundStr)), false, currentRound);
        rounds[currentRound].seederToken = address(_seederToken);
    }
    
    function changeSettings(uint8 _presidentTotalPercent, uint8 _presidentSalaryPercent, uint8 _voteAdditionPercent, uint8 _maxStakeLeadPercent, uint8 _maximumVoteLeadPercent, uint8 _behindBonusPercent, uint8 _payoutDividendPercent, uint8 _unrestrictedStakingPercent, uint8 _seedersProfitPercent, uint256 _timeIncrement, uint256 _minimumStaking, uint256 _minimumVote, uint256 _unlockFromInit, uint256 _unlockFromSeeding) external {
        require(msg.sender == chairman, "Chairman only function");
        require(rounds[currentRound].gameState == 0, "Game not in init state");
        
        settings[currentRound] = Settings({ 
            presidentTotalPercent: _presidentTotalPercent,
            presidentSalaryPercent: _presidentSalaryPercent,
            voteAdditionPercent: _voteAdditionPercent,
            maxStakeLeadPercent: _maxStakeLeadPercent,
            maximumVoteLeadPercent: _maximumVoteLeadPercent,
            behindBonusPercent: _behindBonusPercent,
            payoutDividendPercent: _payoutDividendPercent,
            unrestrictedStakingPercent: _unrestrictedStakingPercent,
            seedersProfitPercent: _seedersProfitPercent,
            timeIncrement: _timeIncrement,
            minimumStaking: _minimumStaking,
            minimumVote: _minimumVote,
            unlockFromInit: _unlockFromInit,
            unlockFromSeeding: _unlockFromSeeding
        });

        emit SettingsChanged();
    }
    
    function setImageApproval(uint8 approval, address playerAddr) external {
        require(msg.sender == chairman, "Chairman only function");
        players[playerAddr].imgApproval = approval;
        emit ChangedImageApproval(approval, playerAddr);
    }
    
    function setImageInitialApproval(uint8 approval) external {
        require(msg.sender == chairman, "Chairman only function");
        imgInitialApproval = approval;
    }

    function setNoDividendBadPerform(bool val) external {
        require(msg.sender == chairman, "Chairman only function");
        noDividendBadPerform = val;
    }
    
    function buyVotes(bool isSoviet) external payable {
        require(rounds[currentRound].gameState == 2, "Game not in running state");
        require(getLeaderboard(isSoviet, currentRound, 0) != msg.sender, "You are already president");
        addVotes(isSoviet, currentRound, msg.sender, SafeMath.mul(msg.value, 1000));
        require(getVotes(isSoviet, currentRound, msg.sender) <= SafeMath.mul(getMinimumVote(currentRound), 1000) || getVotes(isSoviet, currentRound, msg.sender) <= SafeMath.div(SafeMath.mul(getVotes(isSoviet, currentRound, getLeaderboard(isSoviet, currentRound, 0)), getMaximumVoteLeadPercent(currentRound)), 100), "Amount too high");
        refreshLeaderboard(isSoviet, msg.sender);
        addAllianceBonus(isSoviet, currentRound, msg.value);
        emit VoteBought(isSoviet, msg.sender, msg.value);
    }
    
    function setPlayerInfo(bytes32 name, string calldata img) external {
        require(campaignLinks[name] == address(0x0), "Name already taken");
        
        players[msg.sender] = Player(msg.sender, name, img, imgInitialApproval);
        campaignLinks[name] = msg.sender;
    }

    function buyWarBonds(bool isSoviet, address payable _voteAddr, bool behindOnly) public payable {
        buyWarBondsToAddr(msg.sender, isSoviet, _voteAddr, behindOnly);
    }

    function addVotes(bool isSoviet, uint256 round, address voteAddr, uint256 voteAddition) private {
        if (isSoviet) {
            rounds[round].sovietVotes[voteAddr] = SafeMath.add(rounds[round].sovietVotes[voteAddr], voteAddition);
        } else {
            rounds[round].usVotes[voteAddr] = SafeMath.add(rounds[round].usVotes[voteAddr], voteAddition);
        }
    }

    function addAllianceBonus(bool isSoviet, uint256 round, uint256 value) private {
        if (isSoviet) {
            rounds[round].sovietAllianceBonus = SafeMath.add(rounds[round].sovietAllianceBonus, value);
        } else {
            rounds[round].usAllianceBonus = SafeMath.add(rounds[round].usAllianceBonus, value);
        }
    }

    function buyWarBondsToAddr(address payable receiver, bool isSoviet, address payable _voteAddr, bool behindOnly) public payable {
        require(rounds[currentRound].gameState == 2, "Game not in running state");
        require(msg.value >= getMinimumStaking(currentRound), "Staking too little");
        
        address payable voteAddr = _voteAddr;

        uint256 presidentTotal = SafeMath.div(SafeMath.mul(msg.value,getPresidentTotalPercent(currentRound)), 100);
        uint256 presidentSalary = SafeMath.div(SafeMath.mul(presidentTotal, getPresidentSalaryPercent(currentRound)), 100);
        uint256 voteAddition = SafeMath.mul(SafeMath.mul(msg.value,getVoteAdditionPercent(currentRound)), 10);
        uint256 value =  SafeMath.sub(msg.value, presidentTotal);
        bool wasBehind = false;
        uint256 equityShares;

        if (voteAddr == address(0x0)) {
            voteAddr = getLeaderboard(isSoviet, currentRound, 0);
        }
        if (voteAddr == address(0x0)) {
            voteAddr = receiver;
        }

        if (getTotalEquity(isSoviet, currentRound) <= getTotalEquity(!isSoviet, currentRound)) {
            equityShares = SafeMath.div(SafeMath.mul(msg.value, getBehindBonusPercent(currentRound)),100);
            wasBehind = true;
        } else {
            require(!behindOnly, 'behind only requested');
            equityShares = msg.value;
        }
        equityShares = SafeMath.mul(equityShares, 1000);
        BondToken(getToken(isSoviet, currentRound)).mint(receiver, equityShares);
        require(getTotalEquity(isSoviet, currentRound) <= SafeMath.mul(SafeMath.mul(rounds[currentRound].seed, getUnrestrictedStakingPercent(currentRound)), 10) || getTotalEquity(isSoviet, currentRound) <= SafeMath.div(SafeMath.mul(SafeMath.add(getTotalEquity(isSoviet, currentRound), getTotalEquity(!isSoviet, currentRound)), getMaxStakeLeadPercent(currentRound)), 100), "Alliance too far ahead");

        addVotes(isSoviet, currentRound, voteAddr, voteAddition);
        refreshLeaderboard(isSoviet, voteAddr);
        
        rounds[currentRound].presidentSalaries[getLeaderboard(isSoviet, currentRound, 0)] = SafeMath.add(rounds[currentRound].presidentSalaries[getLeaderboard(isSoviet, currentRound, 0)], presidentSalary);
        
        if (wasBehind && getTotalEquity(isSoviet, currentRound) > getTotalEquity(!isSoviet, currentRound)) {
            rounds[currentRound].deadline = SafeMath.add(now, getTimeIncrement(currentRound));
        }
        
        rounds[currentRound].potSize = SafeMath.add(rounds[currentRound].potSize, value);
        rounds[currentRound].presidentPot = SafeMath.add(rounds[currentRound].presidentPot, SafeMath.sub(presidentTotal, presidentSalary));
            
        emit Staking(isSoviet, receiver, value);
    }
    
    function payoutAmount(uint256 round, address addr) public view returns(uint256) {
        require(rounds[round].gameState == 3, "Game not in finished state");
        
        uint256 share=0;
        if (getSovietTotalEquity(round) > getUsTotalEquity(round)) {
            if (getSovietTotalEquity(round) > 0) {
                share = SafeMath.div(SafeMath.mul(BondToken(rounds[round].sovietToken).balanceOf(addr), SafeMath.add(rounds[round].potSize, rounds[round].sovietAllianceBonus)), getSovietTotalEquity(round));
            }
            if (rounds[round].sovietLeaderboard[0] == addr) {
                share = SafeMath.add(share, rounds[round].presidentPot);
            }
        } else {
            if (getUsTotalEquity(round) > 0) {
                share = SafeMath.div(SafeMath.mul(BondToken(rounds[round].usToken).balanceOf(addr), SafeMath.add(rounds[round].potSize, rounds[round].usAllianceBonus)), getUsTotalEquity(round));
            }
            if (rounds[round].usLeaderboard[0] == addr) {
                share = SafeMath.add(share, rounds[round].presidentPot);
            }
        }
        share = SafeMath.add(share, rounds[round].presidentSalaries[addr]);

        share = SafeMath.add(share, getSeedersProfit(round, addr));

        return share;
    }
    
    function payoutAmountAllRounds(address addr) public view returns(uint256) {
        uint256 share=0;
        for (uint256 round=1;round < currentRound;round = SafeMath.add(round, 1)) {
            share = SafeMath.add(share, payoutAmount(round, addr));
        }
        return share;
    }
    
    function payout(uint256 round) public {
        require(rounds[round].gameState == 3, "Game not in finished state");
        
        uint256 share = 0;
        if (getSovietTotalEquity(round) > getUsTotalEquity(round)) {
            if (getSovietTotalEquity(round) > 0) {
                share = SafeMath.div(SafeMath.mul(BondToken(rounds[round].sovietToken).balanceOf(msg.sender), SafeMath.add(rounds[round].potSize, rounds[round].sovietAllianceBonus)), getSovietTotalEquity(round));
            }
            if (rounds[round].sovietLeaderboard[0] == msg.sender) {
                share = SafeMath.add(share, rounds[round].presidentPot);
                rounds[round].presidentPot = 0;
            }
        } else {
            if (getUsTotalEquity(round) > 0) {
                share = SafeMath.div(SafeMath.mul(BondToken(rounds[round].usToken).balanceOf(msg.sender), SafeMath.add(rounds[round].potSize, rounds[round].usAllianceBonus)), getUsTotalEquity(round));
            }
            if (rounds[round].usLeaderboard[0] == msg.sender) {
                share = SafeMath.add(share, rounds[round].presidentPot);
                rounds[round].presidentPot = 0;
            }
        }

        BondToken(rounds[round].sovietToken).burnAll(msg.sender);
        BondToken(rounds[round].usToken).burnAll(msg.sender);

        share = SafeMath.add(share, rounds[round].presidentSalaries[msg.sender]);
        rounds[round].presidentSalaries[msg.sender] = 0;

        share = SafeMath.add(share, getSeedersProfit(round, msg.sender));
        BondToken(rounds[round].seederToken).burnAll(msg.sender);

        if (share > 0) {
            msg.sender.transfer(share);
        }
    }
    
    function fundNewRound() private {
        uint256 lastRound = SafeMath.sub(currentRound, 1);
        uint256 dividends;
        uint256 remainder;
        uint256 funds;
        bool sovietsWon = getSovietTotalEquity(lastRound) > getUsTotalEquity(lastRound);
        if (sovietsWon) {
            funds = rounds[lastRound].usAllianceBonus;
        } else {
            funds = rounds[lastRound].sovietAllianceBonus;
        }

        uint256 seedersTotalProfit = getSeedersTotalProfit(lastRound);

        funds = SafeMath.sub(funds, seedersTotalProfit);

        dividends = SafeMath.div(SafeMath.mul(funds, getPayoutDividendPercent(lastRound)), 100);
        remainder = SafeMath.sub(funds, dividends);
        if (noDividendBadPerform && SafeMath.sub(rounds[lastRound].seed, BondToken(rounds[lastRound].seederToken).totalMinted()) > remainder) {
            dividends = 0;
            remainder = funds;
        }  
        if (dividends > 0) {
            dividendToken.deposit.value(dividends)();
        }                
        rounds[currentRound].potSize = SafeMath.add(rounds[currentRound].potSize, remainder);
        rounds[currentRound].seed = SafeMath.add(rounds[currentRound].seed, remainder);
    }

    function payoutPresidentSalary(uint256 round) public {
        uint256 share = rounds[round].presidentSalaries[msg.sender];
        rounds[round].presidentSalaries[msg.sender] = 0;
        msg.sender.transfer(share);
    }
    
    function payoutAllRounds() public {
        for (uint256 round=1;round < currentRound;round = SafeMath.add(round, 1)) {
            payout(round);
        }
    }

    function uint2str(uint256 __i) internal pure returns (string memory) {
        uint256 _i = __i;
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function setLeaderboard(bool isSoviet, uint256 round, uint256 i, address payable a) private {
        if (isSoviet) {
            rounds[round].sovietLeaderboard[i] = a;
        } else {
            rounds[round].usLeaderboard[i] = a;
        }
    }

    function refreshLeaderboard(bool isSoviet, address payable candidateAddr) private {
        uint i = 0;
        for(i;i < 5;i = SafeMath.add(i, 1)) {
            if(getVotes(isSoviet, currentRound, getLeaderboard(isSoviet, currentRound, i)) < getVotes(isSoviet, currentRound, candidateAddr)) {
                break;
            }
        }
        
        if (i < 5) {
            i = 0;
            for(i;i < 5;i = SafeMath.add(i, 1)) {
                if(getLeaderboard(isSoviet, currentRound, i) == candidateAddr) {
                    for(uint j = i;j < 4;j = SafeMath.add(j, 1)) {
                        setLeaderboard(isSoviet, currentRound, j, getLeaderboard(isSoviet, currentRound, SafeMath.add(j, 1)));
                    }
                    break;
                }
            }
            
            i = 0;
            for(i;i < 5;i = SafeMath.add(i, 1)) {
                if(getVotes(isSoviet, currentRound, getLeaderboard(isSoviet, currentRound, i)) < getVotes(isSoviet, currentRound, candidateAddr)) {
                    break;
                }
            }
        
            for(uint j = 4;j > i;j = SafeMath.sub(j, 1)) {
                setLeaderboard(isSoviet, currentRound, j, getLeaderboard(isSoviet, currentRound, SafeMath.sub(j, 1)));
            }
            setLeaderboard(isSoviet, currentRound, i, candidateAddr);
            emit LeaderboardUpdated();
        }

    } 
}

contract DividendToken {

    string public name = "Stakewar.com Dividend Token";
    string public symbol = "SDT";
    uint8 public decimals = 18;

    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);

    mapping(address => uint256) public balanceOf;

    constructor() public {
         
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    uint256 public scaling = uint256(10) ** 8;

    mapping(address => uint256) public scaledDividendBalanceOf;

    uint256 public scaledDividendPerToken;

    mapping(address => uint256) public scaledDividendCreditedTo;

    function update(address account) internal {
        uint256 owed = SafeMath.sub(scaledDividendPerToken, scaledDividendCreditedTo[account]);
        scaledDividendBalanceOf[account] = SafeMath.add(scaledDividendBalanceOf[account], SafeMath.mul(balanceOf[account], owed));
        scaledDividendCreditedTo[account] = scaledDividendPerToken;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        update(msg.sender);
        update(to);

        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], value);
        balanceOf[to] = SafeMath.add(balanceOf[to], value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        update(from);
        update(to);

        balanceOf[from] = SafeMath.sub(balanceOf[from], value);
        balanceOf[to] = SafeMath.add(balanceOf[to], value);
        allowance[from][msg.sender] = SafeMath.sub(allowance[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
    }

    uint256 public scaledRemainder = 0;

    function deposit() public payable {
         
        uint256 available = SafeMath.add(SafeMath.mul(msg.value, scaling), scaledRemainder);

        scaledDividendPerToken = SafeMath.add(scaledDividendPerToken, SafeMath.div(available, totalSupply));

         
        scaledRemainder = available % totalSupply;
    }

    function withdraw() public {
        update(msg.sender);
        uint256 amount = SafeMath.div(scaledDividendBalanceOf[msg.sender], scaling);
        scaledDividendBalanceOf[msg.sender] %= scaling;   
        msg.sender.transfer(amount);
    }

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    
    address payable stakeWar;
    
    uint256 total;
    uint256 payout;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;


    function totalSupply() public view returns (uint256) {
        return SafeMath.sub(total, payout);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalMinted() public view returns (uint256) {
        return total;
    }

    function totalPayout() public view returns (uint256) {
        return payout;
    }

    function mint(address to, uint256 value) public {
        require(msg.sender == stakeWar, 'Must be initiated by Stakewar');
        require(to != address(0), "ERC20: mint to the zero address");

        _balances[to] = SafeMath.add(_balances[to], value);
        total = SafeMath.add(total, value);
        emit Transfer(address(0), to, value);
    }

    function burnAll(address from) public {
        require(msg.sender == stakeWar, 'Must be initiated by Stakewar');

        _burn(from, _balances[from]);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, SafeMath.sub(_allowances[sender][msg.sender], amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, SafeMath.add(_allowances[msg.sender][spender], addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, SafeMath.sub(_allowances[msg.sender][spender], subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), 'Transfer to null address not allowed');
        require(msg.sender == from, 'Transfer must be initiated by message sender');
        require(_balances[from] >= value);

        _balances[msg.sender] = SafeMath.sub(_balances[msg.sender], value);
        _balances[to] = SafeMath.add(_balances[to], value);

        emit Transfer(from, to, value);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = SafeMath.sub(_balances[account], amount);
        payout = SafeMath.add(payout, amount);

        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract BondToken is ERC20, ERC20Detailed {
    uint8 public constant DECIMALS = 18;
    bool private isSoviet;
    uint256 private round;
    constructor (string memory __name, string memory __symbol, bool _isSoviet, uint256 _round) public ERC20Detailed(__name, __symbol, DECIMALS) {
        stakeWar = msg.sender;
        isSoviet = _isSoviet;
        round = _round;
    }
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}