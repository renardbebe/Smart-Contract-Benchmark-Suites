 

pragma solidity 0.4.21;

 
library SafeMath {

     
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

     
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}


interface ForceToken {
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function serviceTransfer(address _from, address _to, uint _value) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function holders(uint _id) external view returns (address);
    function holdersCount() external view returns (uint);
}

contract Ownable {
    address public owner;
    address public DAO;  

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _owner) public onlyMasters {
        owner = _owner;
    }

    function setDAO(address newDAO) public onlyMasters {
        DAO = newDAO;
    }

    modifier onlyMasters() {
        require(msg.sender == owner || msg.sender == DAO);
        _;
    }
}

contract ForceSeller is Ownable {
    using SafeMath for uint;
    ForceToken public forceToken;

    uint public currentRound;
    uint public tokensOnSale; 
    uint public reservedTokens;
    uint public reservedFunds;
    uint public minSalePrice = 1000000000000000;
    uint public recallPercent = 80;

    string public information;  

    struct Participant {
        uint index;
        uint amount;
        uint value;
        uint change;
        bool needReward;
        bool needCalc;
    }

    struct ICO {
        uint startTime;
        uint finishTime;
        uint weiRaised;
        uint change;
        uint finalPrice;
        uint rewardedParticipants;
        uint calcedParticipants;
        uint tokensDistributed;
        uint tokensOnSale;
        uint reservedTokens;
        mapping(address => Participant) participants;
        mapping(uint => address) participantsList;
        uint totalParticipants;
        bool active;
    }

    mapping(uint => ICO) public ICORounds;  

    event ICOStarted(uint round);
    event ICOFinished(uint round);
    event Withdrawal(uint value);
    event Deposit(address indexed participant, uint value, uint round);
    event Recall(address indexed participant, uint value, uint round);

    modifier whenActive(uint _round) {
        ICO storage ico = ICORounds[_round];
        require(ico.active);
        _;
    }
    modifier whenNotActive(uint _round) {
        ICO storage ico = ICORounds[_round];
        require(!ico.active);
        _;
    }
    modifier duringRound(uint _round) {
        ICO storage ico = ICORounds[_round];
        require(now >= ico.startTime && now <= ico.finishTime);
        _;
    }

    function ForceSeller(address _forceTokenAddress) public {
        forceToken = ForceToken(_forceTokenAddress);

    }

     
    function setInformation(string _information) external onlyMasters {
        information = _information;
    }

     
    function setForceContract(address _forceTokenAddress) external onlyMasters {
        forceToken = ForceToken(_forceTokenAddress);
    }

     
    function setRecallPercent(uint _recallPercent) external onlyMasters {
        recallPercent = _recallPercent;
    }

     
    function setMinSalePrice(uint _minSalePrice) external onlyMasters {
        minSalePrice = _minSalePrice;
    }
     
    function startICO(uint _startTime, uint _duration, uint _amount) external whenNotActive(currentRound) onlyMasters {
        currentRound++;
         
        ICO storage ico = ICORounds[currentRound];

        ico.startTime = _startTime;
        ico.finishTime = _startTime.add(_duration);
        ico.active = true;

        tokensOnSale = forceToken.balanceOf(address(this)).sub(reservedTokens);
         
        if (_amount > tokensOnSale) {
             
             
            require(forceToken.serviceTransfer(address(forceToken), address(this), _amount.sub(tokensOnSale)));
            tokensOnSale = _amount;
        }
         
        ico.tokensOnSale = tokensOnSale;
        reservedTokens = reservedTokens.add(tokensOnSale);
        emit ICOStarted(currentRound);
    }

    function() external payable whenActive(currentRound) duringRound(currentRound) {
        require(msg.value >= currentPrice());
        ICO storage ico = ICORounds[currentRound];
        Participant storage p = ico.participants[msg.sender];
        uint value = msg.value;

         
        if (p.index == 0) {
            p.index = ++ico.totalParticipants;
            ico.participantsList[ico.totalParticipants] = msg.sender;
            p.needReward = true;
            p.needCalc = true;
        }
        p.value = p.value.add(value);
        ico.weiRaised = ico.weiRaised.add(value);
        reservedFunds = reservedFunds.add(value);
        emit Deposit(msg.sender, value, currentRound);
    }

     
    function recall() external whenActive(currentRound) duringRound(currentRound) {
        ICO storage ico = ICORounds[currentRound];
        Participant storage p = ico.participants[msg.sender];
        uint value = p.value;
        require(value > 0);
         
        ico.participants[ico.participantsList[ico.totalParticipants]].index = p.index;
        ico.participantsList[p.index] = ico.participantsList[ico.totalParticipants];
        delete ico.participantsList[ico.totalParticipants--];
        delete ico.participants[msg.sender];
         
        ico.weiRaised = ico.weiRaised.sub(value);
        reservedFunds = reservedFunds.sub(value);
        msg.sender.transfer(valueFromPercent(value, recallPercent));
        emit Recall(msg.sender, value, currentRound);
    }

     
    function currentPrice() public view returns (uint) {
        ICO storage ico = ICORounds[currentRound];
        uint salePrice = tokensOnSale > 0 ? ico.weiRaised.div(tokensOnSale) : 0;
        return salePrice > minSalePrice ? salePrice : minSalePrice;
    }

     
    function reward() external {
        rewardRound(currentRound);
    }

     
    function rewardRound(uint _round) public whenNotActive(_round) {
        ICO storage ico = ICORounds[_round];
        Participant storage p = ico.participants[msg.sender];

        require(p.needReward);
        p.needReward = false;
        ico.rewardedParticipants++;
        if (p.needCalc) {
            p.needCalc = false;
            ico.calcedParticipants++;
            p.amount = p.value.div(ico.finalPrice);
            p.change = p.value % ico.finalPrice;
            reservedFunds = reservedFunds.sub(p.value);
            if (p.change > 0) {
                ico.weiRaised = ico.weiRaised.sub(p.change);
                ico.change = ico.change.add(p.change);
            }
        } else {
             
            ico.reservedTokens = ico.reservedTokens.sub(p.amount);
            if (p.change > 0) {
                reservedFunds = reservedFunds.sub(p.change);
            }
        }

        ico.tokensDistributed = ico.tokensDistributed.add(p.amount);
        ico.tokensOnSale = ico.tokensOnSale.sub(p.amount);
        reservedTokens = reservedTokens.sub(p.amount);

        if (ico.rewardedParticipants == ico.totalParticipants) {
            reservedTokens = reservedTokens.sub(ico.tokensOnSale);
            ico.tokensOnSale = 0;
        }

         
        require(forceToken.transfer(msg.sender, p.amount));

        if (p.change > 0) {
             
            msg.sender.transfer(p.change);
        }
    }

     
    function finishICO() external whenActive(currentRound) onlyMasters {
        ICO storage ico = ICORounds[currentRound];
         
         
        ico.finalPrice = currentPrice();
        tokensOnSale = 0;
        ico.active = false;
        if (ico.totalParticipants == 0) {
            reservedTokens = reservedTokens.sub(ico.tokensOnSale);
            ico.tokensOnSale = 0;

        }
        emit ICOFinished(currentRound);
    }

     
    function calcICO(uint _fromIndex, uint _toIndex, uint _round) public whenNotActive(_round == 0 ? currentRound : _round) onlyMasters {
        ICO storage ico = ICORounds[_round == 0 ? currentRound : _round];
        require(ico.totalParticipants > ico.calcedParticipants);
        require(_toIndex <= ico.totalParticipants);
        require(_fromIndex > 0 && _fromIndex <= _toIndex);

        for(uint i = _fromIndex; i <= _toIndex; i++) {
            address _p = ico.participantsList[i];
            Participant storage p = ico.participants[_p];
            if (p.needCalc) {
                p.needCalc = false;
                p.amount = p.value.div(ico.finalPrice);
                p.change = p.value % ico.finalPrice;
                reservedFunds = reservedFunds.sub(p.value);
                if (p.change > 0) {
                    ico.weiRaised = ico.weiRaised.sub(p.change);
                    ico.change = ico.change.add(p.change);
                     
                    reservedFunds = reservedFunds.add(p.change);
                }
                ico.reservedTokens = ico.reservedTokens.add(p.amount);
                ico.calcedParticipants++;
            }
        }
         
        if (ico.calcedParticipants == ico.totalParticipants) {
            reservedTokens = reservedTokens.sub(ico.tokensOnSale.sub(ico.reservedTokens));
            ico.tokensOnSale = ico.reservedTokens;
        }
    }

     
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount) {
        uint _amount = _value.mul(_percent).div(100);
        return (_amount);
    }

     
    function availableFunds() external view returns (uint amount) {
        return address(this).balance.sub(reservedFunds);
    }

     
    function participantRoundValue(address _address, uint _round) external view returns (uint) {
        ICO storage ico = ICORounds[_round == 0 ? currentRound : _round];
        Participant storage p = ico.participants[_address];
        return p.value;
    }

     
    function participantRoundAmount(address _address, uint _round) external view returns (uint) {
        ICO storage ico = ICORounds[_round == 0 ? currentRound : _round];
        Participant storage p = ico.participants[_address];
        return p.amount;
    }

     
    function participantRoundRewarded(address _address, uint _round) external view returns (bool) {
        ICO storage ico = ICORounds[_round == 0 ? currentRound : _round];
        Participant storage p = ico.participants[_address];
        return !p.needReward;
    }

     
    function participantRoundCalced(address _address, uint _round) external view returns (bool) {
        ICO storage ico = ICORounds[_round == 0 ? currentRound : _round];
        Participant storage p = ico.participants[_address];
        return !p.needCalc;
    }

     
    function participantRoundChange(address _address, uint _round) external view returns (uint) {
        ICO storage ico = ICORounds[_round == 0 ? currentRound : _round];
        Participant storage p = ico.participants[_address];
        return p.change;
    }

     
    function withdrawFunds(address _to, uint _value) external onlyMasters {
        require(address(this).balance.sub(reservedFunds) >= _value);
        _to.transfer(_value);
        emit Withdrawal(_value);
    }
}