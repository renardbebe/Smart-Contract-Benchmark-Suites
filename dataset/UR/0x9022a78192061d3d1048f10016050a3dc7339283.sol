 

pragma solidity ^0.4.21;

 
 
 

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

 

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        _postTransferHook(msg.sender, _to, _value);

        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function _postTransferHook(address _from, address _to, uint256 _value) internal;
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        _postTransferHook(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Owned {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function Owned() public {
        owner = msg.sender;
    }
}


contract AcceptsTokens {
    ETToken public tokenContract;

    function AcceptsTokens(address _tokenContract) public {
        tokenContract = ETToken(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    function acceptTokens(address _from, uint256 _value, uint256 param1, uint256 param2, uint256 param3) external;
}

contract ETToken is Owned, StandardToken {
    using SafeMath for uint;

    string public name = "ETH.TOWN Token";
    string public symbol = "ETIT";
    uint8 public decimals = 18;

    address public beneficiary;
    address public oracle;
    address public heroContract;
    modifier onlyOracle {
        require(msg.sender == oracle);
        _;
    }

    mapping (uint32 => address) public floorContracts;
    mapping (address => bool) public canAcceptTokens;

    mapping (address => bool) public isMinter;

    modifier onlyMinters {
        require(msg.sender == owner || isMinter[msg.sender]);
        _;
    }

    event Dividend(uint256 value);
    event Withdrawal(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function ETToken() public {
        oracle = owner;
        beneficiary = owner;

        totalSupply_ = 0;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }
    function setHeroContract(address _heroContract) external onlyOwner {
        heroContract = _heroContract;
    }

    function _mintTokens(address _user, uint256 _amount) private {
        require(_user != 0x0);

        balances[_user] = balances[_user].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);

        emit Transfer(address(this), _user, _amount);
    }

    function authorizeFloor(uint32 _index, address _floorContract) external onlyOwner {
        floorContracts[_index] = _floorContract;
    }

    function _acceptDividends(uint256 _value) internal {
        uint256 beneficiaryShare = _value / 5;
        uint256 poolShare = _value.sub(beneficiaryShare);

        beneficiary.transfer(beneficiaryShare);

        emit Dividend(poolShare);
    }

    function acceptDividends(uint256 _value, uint32 _floorIndex) external {
        require(floorContracts[_floorIndex] == msg.sender);

        _acceptDividends(_value);
    }

    function rewardTokensFloor(address _user, uint256 _tokens, uint32 _floorIndex) external {
        require(floorContracts[_floorIndex] == msg.sender);

        _mintTokens(_user, _tokens);
    }

    function rewardTokens(address _user, uint256 _tokens) external onlyMinters {
        _mintTokens(_user, _tokens);
    }

    function() payable public {
         
    }

    function payoutDividends(address _user, uint256 _value) external onlyOracle {
        _user.transfer(_value);

        emit Withdrawal(_user, _value);
    }

    function accountAuth(uint256  ) external {
         
    }

    function burn(uint256 _amount) external {
        require(balances[msg.sender] >= _amount);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);

        emit Burn(msg.sender, _amount);
    }

    function setCanAcceptTokens(address _address, bool _value) external onlyOwner {
        canAcceptTokens[_address] = _value;
    }

    function setIsMinter(address _address, bool _value) external onlyOwner {
        isMinter[_address] = _value;
    }

    function _invokeTokenRecipient(address _from, address _to, uint256 _value, uint256 _param1, uint256 _param2, uint256 _param3) internal {
        if (!canAcceptTokens[_to]) {
            return;
        }

        AcceptsTokens recipient = AcceptsTokens(_to);

        recipient.acceptTokens(_from, _value, _param1, _param2, _param3);
    }

     
    function transferWithParams(address _to, uint256 _value, uint256 _param1, uint256 _param2, uint256 _param3) onlyPayloadSize(5 * 32) external returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        _invokeTokenRecipient(msg.sender, _to, _value, _param1, _param2, _param3);

        return true;
    }

     
    function _postTransferHook(address _from, address _to, uint256 _value) internal {
        _invokeTokenRecipient(_from, _to, _value, 0, 0, 0);
    }


}



contract Floor is Owned {
    using SafeMath for uint;

    enum FloorStatus {
        NotYet,          
        Auctioning,      
        Sold             
    }

    ETToken baseContract;
    uint32 public floorId;
    FloorStatus public status = FloorStatus.NotYet;
    address public winner;

    event Bid(address indexed from, uint256 value);
    event FloorWon(address indexed from, uint256 value);
    event Payout(address indexed to, uint256 value);

    modifier onlyOracle {
        require(msg.sender == baseContract.oracle());
        _;
    }
    modifier onlyOwnerOrOracle {
        require(msg.sender == owner || msg.sender == baseContract.oracle());
        _;
    }

    function Floor(uint32 _floorId, address _baseContract) public {
        baseContract = ETToken(_baseContract);
        floorId = _floorId;
    }


    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function _processDividends(uint256 _value) internal {
        if (_value > 0) {
            address(baseContract).transfer(_value);
            baseContract.acceptDividends(_value, floorId);
        }
    }

    function _processCredit(address _user, uint256 _value) internal {
        if (_value > 0) {
            _user.transfer(_value);
        }
    }

    function _rewardTokens(address _user, uint256 _tokens) internal {
        if (_tokens > 0) {
            baseContract.rewardTokensFloor(_user, _tokens, floorId);
        }
    }
}

contract StarAuction {
    address public highestBidder;
    bool public ended;
}

contract CharacterSale {
    mapping (address => uint32[]) public characters;
}

contract CauldronsMinigamePresale is Floor, AcceptsTokens {
    using SafeMath for uint;

    bool public enabled;

    enum CauldronType {
        NoCauldron,
        EtherCauldron,
        EtitCauldron
    }

    struct Cauldron {
        uint256 timerDuration;
        CauldronType cauldronType;

        uint32 currentRound;
        uint256 expirationTimer;

        mapping(uint32 => address[]) contributors;
        uint32 contributorsCount;
        mapping(uint32 => mapping(address => uint256)) contributions;
        uint256 totalContribution;
        address topContributor;
    }

    mapping(uint8 => Cauldron) public cauldrons;

    uint constant numStarAuctions = 12;
    mapping(uint8 => StarAuction) public starAuctions;  

    event Contribution(address indexed from, uint256 value, uint8 cauldronId, uint32 round);
    event Winner(address user, uint256 value, uint8 cauldronId, uint32 round);

    function CauldronsMinigamePresale(uint32 _floorId, address _baseContract)
        Floor(_floorId, _baseContract)
        AcceptsTokens(_baseContract)
        public
    {
        enabled = true;

        cauldrons[1] = Cauldron({
            timerDuration: 5 minutes,
            cauldronType: CauldronType.EtherCauldron,

            currentRound: 1,
            expirationTimer: 0,

            contributorsCount: 0,
            totalContribution: 0,
            topContributor: 0
        });
        cauldrons[2] = Cauldron({
            timerDuration: 20 minutes,
            cauldronType: CauldronType.EtitCauldron,

            currentRound: 1,
            expirationTimer: 0,

            contributorsCount: 0,
            totalContribution: 0,
            topContributor: 0
        });
        cauldrons[3] = Cauldron({
            timerDuration: 60 minutes,
            cauldronType: CauldronType.EtherCauldron,

            currentRound: 1,
            expirationTimer: 0,

            contributorsCount: 0,
            totalContribution: 0,
            topContributor: 0
        });
        cauldrons[4] = Cauldron({
            timerDuration: 120 minutes,
            cauldronType: CauldronType.EtitCauldron,

            currentRound: 1,
            expirationTimer: 0,

            contributorsCount: 0,
            totalContribution: 0,
            topContributor: 0
        });
        cauldrons[5] = Cauldron({
            timerDuration: 12 hours,
            cauldronType: CauldronType.EtherCauldron,

            currentRound: 1,
            expirationTimer: 0,

            contributorsCount: 0,
            totalContribution: 0,
            topContributor: 0
        });
    }

    function isCauldronExpired(uint8 _cauldronId) public view returns (bool) {
        return cauldrons[_cauldronId].expirationTimer != 0 && cauldrons[_cauldronId].expirationTimer < now;
    }

    function horseMaster() public view returns (address) {
        if (address(starAuctions[7]) == 0x0) {
            return 0x0;
        } else {
            return starAuctions[7].highestBidder();
        }
    }

    function() public payable {
         
        revert();
    }

    function setEnabled(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function setStarAuction(uint8 _id, address _address) public onlyOwner {
        starAuctions[_id] = StarAuction(_address);
    }

    function _acceptContribution(address _from, uint256 _value, uint8 _cauldronId) internal {
        require(!isCauldronExpired(_cauldronId));

        Cauldron storage cauldron = cauldrons[_cauldronId];

        uint256 existingContribution = cauldron.contributions[cauldron.currentRound][_from];

        if (existingContribution == 0) {
            cauldron.contributors[cauldron.currentRound].push(_from);
            cauldron.contributorsCount ++;
        }

        uint256 userNewContribution = existingContribution.add(_value);

        cauldron.contributions[cauldron.currentRound][_from] = userNewContribution;
        cauldron.totalContribution = cauldron.totalContribution.add(_value);

        if (userNewContribution > cauldron.contributions[cauldron.currentRound][cauldron.topContributor]) {
            cauldron.topContributor = _from;
        }

        uint8 peopleToStart = _cauldronId == 1 ? 10 : 3;
        if (cauldron.expirationTimer == 0 && cauldron.contributorsCount >= peopleToStart) {
            cauldron.expirationTimer = now + cauldron.timerDuration;
        }

        emit Contribution(_from, _value, _cauldronId, cauldron.currentRound);
    }

    function acceptTokens(address _from, uint256 _value, uint256 _cauldronId, uint256  , uint256  ) external onlyTokenContract {
        require(!_isContract(_from));
        require(enabled);
        require(cauldrons[uint8(_cauldronId)].cauldronType == CauldronType.EtitCauldron);
        require(_value >= 1 finney);

        _acceptContribution(_from, _value, uint8(_cauldronId));
    }

    function acceptEther(uint8 _cauldronId) external payable {
        require(!_isContract(msg.sender));
        require(enabled);
        require(cauldrons[_cauldronId].cauldronType == CauldronType.EtherCauldron);
        require(msg.value >= 1 finney);

        _acceptContribution(msg.sender, msg.value, _cauldronId);
    }

    function _rotateCauldron(uint8 _cauldronId) internal {
        require(isCauldronExpired(_cauldronId));

        Cauldron storage cauldron = cauldrons[_cauldronId];

        cauldron.currentRound ++;
        cauldron.expirationTimer = 0;

        cauldron.contributorsCount = 0;
        cauldron.totalContribution = 0;
        cauldron.topContributor = 0;
    }

    function calculateReward(uint256 totalValue, uint256 basePercent, uint8 level) public pure returns (uint256) {
         
         
        uint256 levelAddition = uint256(level).mul(5);  
        uint256 modificationPercent = levelAddition.add(915);

        uint256 finalPercent1000 = basePercent.mul(modificationPercent);  

        assert(finalPercent1000 / 1000 <= basePercent);
        assert(finalPercent1000 <= 100000);

        return totalValue.mul(finalPercent1000).div(100000);
    }

    function pickWinners(
        uint8 _cauldronId,
        address winner1,
        address winner2,
        address winner3,
        uint8 winner1Level,
        uint8 winner2Level,
        uint8 winner3Level
    ) external onlyOracle {
        require(isCauldronExpired(_cauldronId) || !enabled);

        Cauldron storage cauldron = cauldrons[_cauldronId];

        require(cauldron.contributions[cauldron.currentRound][winner1] > 0);
        require(cauldron.contributions[cauldron.currentRound][winner2] > 0);
        require(cauldron.contributions[cauldron.currentRound][winner3] > 0);

        require(winner1Level <= 15);
        require(winner2Level <= 15);
        require(winner3Level <= 15);

        uint256 winner1Reward = calculateReward(cauldron.totalContribution, 50, winner1Level);
        uint256 winner2Reward = calculateReward(cauldron.totalContribution, 35, winner2Level);
        uint256 winner3Reward = calculateReward(cauldron.totalContribution, 15, winner3Level);

        uint256 remainingReward =
            cauldron.totalContribution
                .sub(winner1Reward)
                .sub(winner2Reward)
                .sub(winner3Reward);

        if (cauldron.cauldronType == CauldronType.EtherCauldron) {
            winner1.transfer(winner1Reward);
            winner2.transfer(winner2Reward);
            winner3.transfer(winner3Reward);

             
            if (horseMaster() != 0x0) {
                remainingReward = remainingReward.sub(remainingReward.mul(5).div(100));
                horseMaster().transfer(remainingReward.mul(5).div(100));
            }

             
            _processDividends(remainingReward);

        } else if (cauldron.cauldronType == CauldronType.EtitCauldron) {
            baseContract.transfer(winner1, winner1Reward);
            baseContract.transfer(winner2, winner2Reward);
            baseContract.transfer(winner3, winner3Reward);

             
            baseContract.burn(remainingReward);
        }

        emit Winner(winner1, winner1Reward, _cauldronId, cauldron.currentRound);
        emit Winner(winner2, winner2Reward, _cauldronId, cauldron.currentRound);
        emit Winner(winner3, winner3Reward, _cauldronId, cauldron.currentRound);

        _rotateCauldron(_cauldronId);
    }


    function contributorsOfCauldron(uint8 _cauldronId) public view returns (address[]) {
        Cauldron storage cauldron = cauldrons[_cauldronId];

        return cauldron.contributors[cauldron.currentRound];
    }

    function contributionInCauldron(uint8 _cauldronId, address _user) public view returns (uint256) {
        Cauldron storage cauldron = cauldrons[_cauldronId];

        return cauldron.contributions[cauldron.currentRound][_user];
    }

    function contributorsOfCauldronRound(uint8 _cauldronId, uint32 _round) public view returns (address[]) {
        Cauldron storage cauldron = cauldrons[_cauldronId];

        return cauldron.contributors[_round];
    }

    function contributionInCauldronRound(uint8 _cauldronId, address _user, uint32 _round) public view returns (uint256) {
        Cauldron storage cauldron = cauldrons[_cauldronId];

        return cauldron.contributions[_round][_user];
    }

}