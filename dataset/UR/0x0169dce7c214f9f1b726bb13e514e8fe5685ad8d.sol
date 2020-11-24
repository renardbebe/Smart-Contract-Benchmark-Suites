 

pragma solidity ^0.4.20;

pragma solidity ^0.4.21;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface P3DTakeout {
    function buyTokens() external payable;
}

contract Betting{
    using SafeMath for uint256;  

    address public owner;  
    address house_takeout = 0xf783A81F046448c38f3c863885D9e99D10209779;
    P3DTakeout P3DContract_;

    uint public winnerPoolTotal;
    string public constant version = "0.2.4";

    struct chronus_info {
        bool  betting_open;  
        bool  race_start;  
        bool  race_end;  
        bool  voided_bet;  
        uint32  starting_time;  
        uint32  betting_duration;
        uint32  race_duration;  
        uint32 voided_timestamp;
    }

    struct horses_info{
        int64  BTC_delta;  
        int64  ETH_delta;  
        int64  LTC_delta;  
        bytes32 BTC;  
        bytes32 ETH;  
        bytes32 LTC;   
    }

    struct bet_info{
        bytes32 horse;  
        uint amount;  
    }
    struct coin_info{
        uint256 pre;  
        uint256 post;  
        uint160 total;  
        uint32 count;  
        bool price_check;
    }
    struct voter_info {
        uint160 total_bet;  
        bool rewarded;  
        mapping(bytes32=>uint) bets;  
    }

    mapping (bytes32 => coin_info) public coinIndex;  
    mapping (address => voter_info) voterIndex;  

    uint public total_reward;  
    uint32 total_bettors;
    mapping (bytes32 => bool) public winner_horse;


     
    event Deposit(address _from, uint256 _value, bytes32 _horse, uint256 _date);
    event Withdraw(address _to, uint256 _value);
    event PriceCallback(bytes32 coin_pointer, uint256 result, bool isPrePrice);
    event RefundEnabled(string reason);

     
    constructor() public payable {
        
        owner = msg.sender;
        
        horses.BTC = bytes32("BTC");
        horses.ETH = bytes32("ETH");
        horses.LTC = bytes32("LTC");
        
        P3DContract_ = P3DTakeout(0x72b2670e55139934D6445348DC6EaB4089B12576);
    }

     
    horses_info public horses;
    chronus_info public chronus;

     
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier duringBetting {
        require(chronus.betting_open);
        require(now < chronus.starting_time + chronus.betting_duration);
        _;
    }

    modifier beforeBetting {
        require(!chronus.betting_open && !chronus.race_start);
        _;
    }

    modifier afterRace {
        require(chronus.race_end);
        _;
    }

     
    function changeOwnership(address _newOwner) onlyOwner external {
        require(now > chronus.starting_time + chronus.race_duration + 60 minutes);
        owner = _newOwner;
    }

    function priceCallback (bytes32 coin_pointer, uint256 result, bool isPrePrice ) external onlyOwner {
        require (!chronus.race_end);
        emit PriceCallback(coin_pointer, result, isPrePrice);
        chronus.race_start = true;
        chronus.betting_open = false;
        if (isPrePrice) {
            if (now >= chronus.starting_time+chronus.betting_duration+ 60 minutes) {
                emit RefundEnabled("Late start price");
                forceVoidRace();
            } else {
                coinIndex[coin_pointer].pre = result;
            }
        } else if (!isPrePrice){
            if (coinIndex[coin_pointer].pre > 0 ){
                if (now >= chronus.starting_time+chronus.race_duration+ 60 minutes) {
                    emit RefundEnabled("Late end price");
                    forceVoidRace();
                } else {
                    coinIndex[coin_pointer].post = result;
                    coinIndex[coin_pointer].price_check = true;

                    if (coinIndex[horses.ETH].price_check && coinIndex[horses.BTC].price_check && coinIndex[horses.LTC].price_check) {
                        reward();
                    }
                }
            } else {
                emit RefundEnabled("End price came before start price");
                forceVoidRace();
            }
        }
    }

     
    function placeBet(bytes32 horse) external duringBetting payable  {
        require(msg.value >= 0.01 ether);
        if (voterIndex[msg.sender].total_bet==0) {
            total_bettors+=1;
        }
        uint _newAmount = voterIndex[msg.sender].bets[horse] + msg.value;
        voterIndex[msg.sender].bets[horse] = _newAmount;
        voterIndex[msg.sender].total_bet += uint160(msg.value);
        uint160 _newTotal = coinIndex[horse].total + uint160(msg.value);
        uint32 _newCount = coinIndex[horse].count + 1;
        coinIndex[horse].total = _newTotal;
        coinIndex[horse].count = _newCount;
        emit Deposit(msg.sender, msg.value, horse, now);
    }

     
    function () private payable {}

     
    function setupRace(uint32 _bettingDuration, uint32 _raceDuration) onlyOwner beforeBetting external payable {
            chronus.starting_time = uint32(block.timestamp);
            chronus.betting_open = true;
            chronus.betting_duration = _bettingDuration;
            chronus.race_duration = _raceDuration;
    }

     
    function reward() internal {
         
        horses.BTC_delta = int64(coinIndex[horses.BTC].post - coinIndex[horses.BTC].pre)*100000/int64(coinIndex[horses.BTC].pre);
        horses.ETH_delta = int64(coinIndex[horses.ETH].post - coinIndex[horses.ETH].pre)*100000/int64(coinIndex[horses.ETH].pre);
        horses.LTC_delta = int64(coinIndex[horses.LTC].post - coinIndex[horses.LTC].pre)*100000/int64(coinIndex[horses.LTC].pre);

        total_reward = (coinIndex[horses.BTC].total) + (coinIndex[horses.ETH].total) + (coinIndex[horses.LTC].total);
        if (total_bettors <= 1) {
            emit RefundEnabled("Not enough participants");
            forceVoidRace();
        } else {
             
            uint house_fee = total_reward.mul(5).div(100);
            require(house_fee < address(this).balance);
            total_reward = total_reward.sub(house_fee);
            house_takeout.transfer(house_fee);
            
             
            uint p3d_fee = house_fee/2;
            require(p3d_fee < address(this).balance);
            total_reward = total_reward.sub(p3d_fee);
            P3DContract_.buyTokens.value(p3d_fee)();
        }

        if (horses.BTC_delta > horses.ETH_delta) {
            if (horses.BTC_delta > horses.LTC_delta) {
                winner_horse[horses.BTC] = true;
                winnerPoolTotal = coinIndex[horses.BTC].total;
            }
            else if(horses.LTC_delta > horses.BTC_delta) {
                winner_horse[horses.LTC] = true;
                winnerPoolTotal = coinIndex[horses.LTC].total;
            } else {
                winner_horse[horses.BTC] = true;
                winner_horse[horses.LTC] = true;
                winnerPoolTotal = coinIndex[horses.BTC].total + (coinIndex[horses.LTC].total);
            }
        } else if(horses.ETH_delta > horses.BTC_delta) {
            if (horses.ETH_delta > horses.LTC_delta) {
                winner_horse[horses.ETH] = true;
                winnerPoolTotal = coinIndex[horses.ETH].total;
            }
            else if (horses.LTC_delta > horses.ETH_delta) {
                winner_horse[horses.LTC] = true;
                winnerPoolTotal = coinIndex[horses.LTC].total;
            } else {
                winner_horse[horses.ETH] = true;
                winner_horse[horses.LTC] = true;
                winnerPoolTotal = coinIndex[horses.ETH].total + (coinIndex[horses.LTC].total);
            }
        } else {
            if (horses.LTC_delta > horses.ETH_delta) {
                winner_horse[horses.LTC] = true;
                winnerPoolTotal = coinIndex[horses.LTC].total;
            } else if(horses.LTC_delta < horses.ETH_delta){
                winner_horse[horses.ETH] = true;
                winner_horse[horses.BTC] = true;
                winnerPoolTotal = coinIndex[horses.ETH].total + (coinIndex[horses.BTC].total);
            } else {
                winner_horse[horses.LTC] = true;
                winner_horse[horses.ETH] = true;
                winner_horse[horses.BTC] = true;
                winnerPoolTotal = coinIndex[horses.ETH].total + (coinIndex[horses.BTC].total) + (coinIndex[horses.LTC].total);
            }
        }
        chronus.race_end = true;
    }

     
    function calculateReward(address candidate) internal afterRace constant returns(uint winner_reward) {
        voter_info storage bettor = voterIndex[candidate];
        if(chronus.voided_bet) {
            winner_reward = bettor.total_bet;
        } else {
            uint winning_bet_total;
            if(winner_horse[horses.BTC]) {
                winning_bet_total += bettor.bets[horses.BTC];
            } if(winner_horse[horses.ETH]) {
                winning_bet_total += bettor.bets[horses.ETH];
            } if(winner_horse[horses.LTC]) {
                winning_bet_total += bettor.bets[horses.LTC];
            }
            winner_reward += (((total_reward.mul(10000000)).div(winnerPoolTotal)).mul(winning_bet_total)).div(10000000);
        }
    }

     
    function checkReward() afterRace external constant returns (uint) {
        require(!voterIndex[msg.sender].rewarded);
        return calculateReward(msg.sender);
    }

     
    function claim_reward() afterRace external {
        require(!voterIndex[msg.sender].rewarded);
        uint transfer_amount = calculateReward(msg.sender);
        require(address(this).balance >= transfer_amount);
        voterIndex[msg.sender].rewarded = true;
        msg.sender.transfer(transfer_amount);
        emit Withdraw(msg.sender, transfer_amount);
    }

    function forceVoidRace() internal {
        require(!chronus.voided_bet);
        chronus.voided_bet=true;
        chronus.race_end = true;
        chronus.voided_timestamp=uint32(now);
    }
    
     
    function forceVoidExternal() external onlyOwner {
        forceVoidRace();
        emit RefundEnabled("Inaccurate price timestamp");
    }

     
    function getCoinIndex(bytes32 index, address candidate) external constant returns (uint, uint, uint, bool, uint) {
        uint256 coinPrePrice;
        uint256 coinPostPrice;
        if (coinIndex[horses.ETH].pre > 0 && coinIndex[horses.BTC].pre > 0 && coinIndex[horses.LTC].pre > 0) {
            coinPrePrice = coinIndex[index].pre;
        } 
        if (coinIndex[horses.ETH].post > 0 && coinIndex[horses.BTC].post > 0 && coinIndex[horses.LTC].post > 0) {
            coinPostPrice = coinIndex[index].post;
        }
        return (coinIndex[index].total, coinPrePrice, coinPostPrice, coinIndex[index].price_check, voterIndex[candidate].bets[index]);
    }

     
    function reward_total() external constant returns (uint) {
        return ((coinIndex[horses.BTC].total) + (coinIndex[horses.ETH].total) + (coinIndex[horses.LTC].total));
    }
    
    function getChronus() external view returns (uint32[]) {
        uint32[] memory chronusData = new uint32[](3);
        chronusData[0] = chronus.starting_time;
        chronusData[1] = chronus.betting_duration;
        chronusData[2] = chronus.race_duration;
        return (chronusData);
         
    }

     
    function refund() external onlyOwner {
        require(now > chronus.starting_time + chronus.race_duration + 60 minutes);
        require((chronus.betting_open && !chronus.race_start)
            || (chronus.race_start && !chronus.race_end));
        chronus.voided_bet = true;
        chronus.race_end = true;
        chronus.voided_timestamp=uint32(now);
    }

     
    function recovery() external onlyOwner{
        require((chronus.race_end && now > chronus.starting_time + chronus.race_duration + (30 days))
            || (chronus.voided_bet && now > chronus.voided_timestamp + (30 days)));
        house_takeout.transfer(address(this).balance);
    }
}