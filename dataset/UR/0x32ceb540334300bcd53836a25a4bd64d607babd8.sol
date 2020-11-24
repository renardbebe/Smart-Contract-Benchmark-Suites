 

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
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
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

 
 

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract BetGame is DSStop {
    using SafeMath for uint256;

    struct Bet {
         
        address player;
        bytes32 secretHash;
        uint256 amount;
        uint roundId;

         
        bool isRevealed;     
        uint nonce;
        bool guessOdd;
        bytes32 secret;
    }

    struct Round {
        uint betCount;
        uint[] betIds;

        uint startBetBlock;
        uint startRevealBlock;
        uint maxBetBlockCount;       
        uint maxRevealBlockCount;    
        uint finalizedBlock;
    }

    uint public betCount;
    uint public roundCount;

    mapping(uint => Bet) public bets;
    mapping(uint => Round) public rounds;
    mapping(address => uint) public balancesForWithdraw;

    uint public poolAmount;
    uint256 public initializeTime;
    ERC20 public pls;

    struct TokenMessage {
        bool init;
        address fallbackFrom;
        uint256 fallbackValue;
    }

    TokenMessage public tokenMsg;

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier tokenPayable {
        require(msg.sender == address(this));
        require(tokenMsg.init);

        _;
    }

    function BetGame(address _pls)
    {
        initializeTime = now;
        roundCount = 1;

        pls = ERC20(_pls);
    }

    function onTokenTransfer(address _from, address _to, uint _amount) public returns (bool) {
        if (_to == address(this))
        {
            if (stopped) return false;
        }

        return true;
    }

    function receiveToken(address from, uint256 _amount, address _token) public
    {
         
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public
    {
        require(msg.sender == address(pls));
        require(!stopped);
        tokenMsg.init = true;
        tokenMsg.fallbackFrom = _from;
        tokenMsg.fallbackValue = _value;

        if(! this.call(_data)){
            revert();
        }

        tokenMsg.init = false;
        tokenMsg.fallbackFrom = 0x0;
        tokenMsg.fallbackValue = 0;
    }
    
    function startRoundWithFirstBet(uint _betCount, uint _maxBetBlockCount, uint _maxRevealBlockCount, bytes32 _secretHashForFirstBet) public tokenPayable returns (uint roundId)
    {
        require(_betCount >= 2);
        require(_maxBetBlockCount >= 100);
        require(_maxRevealBlockCount >= 100);

        require(tokenMsg.fallbackValue > 0);

        uint betId = addBet(tokenMsg.fallbackFrom, _secretHashForFirstBet, tokenMsg.fallbackValue);

        roundId = addRound(_betCount, _maxBetBlockCount, _maxRevealBlockCount, betId);
    }

    function betWithRound(uint _roundId, bytes32 _secretHashForBet) public tokenPayable
    {
        require(tokenMsg.fallbackValue > 0);
        require(rounds[_roundId].finalizedBlock == 0);
        require(rounds[_roundId].betIds.length < rounds[_roundId].betCount);
        require(!isPlayerInRound(_roundId, tokenMsg.fallbackFrom));

        uint betId = addBet(tokenMsg.fallbackFrom, _secretHashForBet, tokenMsg.fallbackValue);
        rounds[_roundId].betIds.push(betId);
        bets[betId].roundId = _roundId;

        if (rounds[_roundId].betIds.length == rounds[_roundId].betCount)
        {
            rounds[_roundId].startRevealBlock = getBlockNumber();

            RoundRevealStarted(_roundId, rounds[_roundId].startRevealBlock);
        }
    }

     
    function revealBet(uint betId, uint _nonce, bool _guessOdd, bytes32 _secret) public returns (bool)
    {
        Bet bet = bets[betId];
        Round round = rounds[bet.roundId];
        require(round.betIds.length == round.betCount);
        require(round.finalizedBlock == 0);

        if (bet.secretHash == keccak256(_nonce, _guessOdd, _secret) )
        {
            bet.isRevealed = true;
            bet.nonce = _nonce;
            bet.guessOdd = _guessOdd;
            bet.secret = _secret;
            
            return true;
        }
        
        return false;
    }

     
    function finalizeRound(uint roundId) public
    {
        require(rounds[roundId].finalizedBlock == 0);
        uint finalizedBlock = getBlockNumber();
        
        uint i = 0;
        Bet bet;
        if (rounds[roundId].betIds.length < rounds[roundId].betCount && finalizedBlock.sub(rounds[roundId].startBetBlock) > rounds[roundId].maxBetBlockCount)
        {
             
            for (i=0; i<rounds[roundId].betIds.length; i++) {
                bet = bets[rounds[roundId].betIds[i]];
                balancesForWithdraw[bet.player] = balancesForWithdraw[bet.player].add(bet.amount);
            }
        } else if (rounds[roundId].betIds.length == rounds[roundId].betCount) {
            bool betsRevealed = betRevealed(roundId);
            if (!betsRevealed && finalizedBlock.sub(rounds[roundId].startRevealBlock) > rounds[roundId].maxRevealBlockCount)
            {
                 
                 
                 
                for (i = 0; i < rounds[roundId].betIds.length; i++) {
                    if (bets[rounds[roundId].betIds[i]].isRevealed)
                    {
                        balancesForWithdraw[bets[rounds[roundId].betIds[i]].player] = balancesForWithdraw[bets[rounds[roundId].betIds[i]].player].add(bets[rounds[roundId].betIds[i]].amount);
                    } else
                    {
                         
                        poolAmount = poolAmount.add(bets[rounds[roundId].betIds[i]].amount);
                    }
                }
            } else if (betsRevealed)
            {
                uint dustLeft = finalizeRewardForRound(roundId);
                poolAmount = poolAmount.add(dustLeft);
            } else
            {
                throw;
            }

        } else
        {
            throw;
        }

        rounds[roundId].finalizedBlock = finalizedBlock;
        RoundFinalized(roundId);
    }

    function withdraw() public returns (bool)
    {
        var amount = balancesForWithdraw[msg.sender];
        if (amount > 0) {
            balancesForWithdraw[msg.sender] = 0;

            if (!pls.transfer(msg.sender, amount)) {
                 
                balancesForWithdraw[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function claimFromPool() public auth
    {
        owner.transfer(poolAmount);
        ClaimFromPool();
    }

     
     
    function calculateSecretHash(uint _nonce, bool _guessOdd, bytes32 _secret) constant public returns (bytes32 secretHash)
    {
        secretHash = keccak256(_nonce, _guessOdd, _secret);
    }

    function isPlayerInRound(uint _roundId, address _player) public constant returns (bool isIn)
    {
        for (uint i=0; i < rounds[_roundId].betIds.length; i++) {
            if (bets[rounds[_roundId].betIds[i]].player == _player)
            {
                isIn = true;
                return;
            }
        }

        isIn = false;
    }
    
    function getBetIds(uint roundIndex) public constant returns (uint[] _betIds)
    {
        _betIds = new uint[](rounds[roundIndex].betIds.length);

        for (uint i=0; i < rounds[roundIndex].betIds.length; i++)
            _betIds[i] = rounds[roundIndex].betIds[i];
    }

    function getBetIdAtRound(uint roundIndex, uint innerIndex) constant public returns (uint) {
        return rounds[roundIndex].betIds[innerIndex];
    }

    function getBetSizeAtRound(uint roundIndex) constant public returns (uint) {
        return rounds[roundIndex].betIds.length;
    }

    function betRevealed(uint roundId) constant public returns(bool)
    {
        bool betsRevealed = true;
        uint i = 0;
        Bet bet;
        for (i=0; i<rounds[roundId].betIds.length; i++) {
            bet = bets[rounds[roundId].betIds[i]];
            if (!bet.isRevealed)
            {
                betsRevealed = false;
                break;
            }
        }
        
        return betsRevealed;
    }
    
    function getJackpotResults(uint roundId) constant public returns(uint, uint, bool)
    {
        uint jackpotSum;
        uint jackpotSecret;
        uint oddSum;

        uint i = 0;
        for (i=0; i<rounds[roundId].betIds.length; i++) {
            jackpotSum = jackpotSum.add(bets[rounds[roundId].betIds[i]].amount);
            jackpotSecret = jackpotSecret.add(uint(bets[rounds[roundId].betIds[i]].secret));
            
            if( bets[rounds[roundId].betIds[i]].guessOdd ){
                oddSum = oddSum.add(bets[rounds[roundId].betIds[i]].amount);
            }
        }
        
        bool isOddWin = (jackpotSecret % 2 == 1);

         
        if (oddSum == 0 || oddSum == jackpotSum)
        {
            isOddWin = oddSum > 0 ? true : false;
        }
        
        return (jackpotSum, oddSum, isOddWin);
    }

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

     
     
     
     
     
     
    function addBet(address _player, bytes32 _secretHash, uint256 _amount)
        internal
        notNull(_player)
        returns (uint betId)
    {
        betId = betCount;
        bets[betId] = Bet({
            player: _player,
            secretHash: _secretHash,
            amount: _amount,
            roundId: 0,
            isRevealed: false,
            nonce:0,
            guessOdd:false,
            secret: ""
        });
        betCount += 1;
        BetSubmission(betId);
    }

    function addRound(uint _betCount, uint _maxBetBlockCount, uint _maxRevealBlockCount, uint _betId)
        internal
        returns (uint roundId)
    {
        roundId = roundCount;
        rounds[roundId].betCount = _betCount;
        rounds[roundId].maxBetBlockCount = _maxBetBlockCount;
        rounds[roundId].maxRevealBlockCount = _maxRevealBlockCount;
        rounds[roundId].betIds.push(_betId);
        rounds[roundId].startBetBlock = getBlockNumber();
        rounds[roundId].startRevealBlock = 0;
        rounds[roundId].finalizedBlock = 0;

        bets[_betId].roundId = roundId;

        roundCount += 1;
        RoundSubmission(roundId);
        RoundBetStarted(roundId, rounds[roundId].startBetBlock);
    }
    
    function finalizeRewardForBet(uint betId, bool isOddWin, uint jackpotSum, uint oddSum, uint evenSum, uint dustLeft) internal returns(uint)
    {
        uint reward = 0;
        if (isOddWin && bets[betId].guessOdd)
        {
            reward = bets[betId].amount.mul(jackpotSum).div(oddSum);
            balancesForWithdraw[bets[betId].player] = balancesForWithdraw[bets[betId].player].add(reward);
            dustLeft = dustLeft.sub(reward);
        } else if (!isOddWin && !bets[betId].guessOdd)
        {
            reward = bets[betId].amount.mul(jackpotSum).div(evenSum);
            balancesForWithdraw[bets[betId].player] = balancesForWithdraw[bets[betId].player].add(reward);
            dustLeft = dustLeft.sub(reward);
        }
        
        return dustLeft;
    }
    
    function finalizeRewardForRound(uint roundId) internal returns (uint dustLeft)
    {
        var (jackpotSum, oddSum, isOddWin) = getJackpotResults(roundId);

        dustLeft = jackpotSum;

        uint i = 0;
        for (i=0; i<rounds[roundId].betIds.length; i++) {
            dustLeft = finalizeRewardForBet(rounds[roundId].betIds[i], isOddWin, jackpotSum, oddSum, jackpotSum - oddSum, dustLeft);
        }
    }
    
     
     
     
     
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
        
        ERC20 token = ERC20(_token);
        
        uint256 balance = token.balanceOf(this);
        
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event BetSubmission(uint indexed _betId);
    event RoundSubmission(uint indexed _roundId);
    event ClaimFromPool();
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event RoundFinalized(uint indexed _roundId);
    event RoundBetStarted(uint indexed _roundId, uint startBetBlock);
    event RoundRevealStarted(uint indexed _roundId, uint startRevealBlock);
}