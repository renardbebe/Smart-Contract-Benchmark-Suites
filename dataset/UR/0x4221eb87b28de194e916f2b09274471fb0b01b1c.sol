 

pragma solidity ^0.4.23;

 
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipRenounced(
        address indexed previousOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() public view returns (uint256);
    function annualInterest() public view returns (uint256);
    function calculateReward() public view returns (uint256);
    function calculateRewardAt(uint256 _now) public view returns (uint256);
    event Mint(
        address indexed _address,
        uint256 _reward
    );
}

 
contract TrueDeckToken is ERC20, PoSTokenStandard, Pausable {
    using SafeMath for uint256;

    event CoinAgeRecordEvent(
        address indexed who,
        uint256 value,
        uint64 time
    );
    event CoinAgeResetEvent(
        address indexed who,
        uint256 value,
        uint64 time
    );

    string public constant name = "TrueDeck";
    string public constant symbol = "TDP";
    uint8 public constant decimals = 18;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

     
    uint256 public MAX_TOTAL_SUPPLY = 200000000 * 10 ** uint256(decimals);

     
    uint256 public INITIAL_SUPPLY = 70000000 * 10 ** uint256(decimals);

     
    uint256 public chainStartTime;

     
    uint256 public chainStartBlockNumber;

     
    struct CoinAgeRecord {
        uint256 amount;
        uint64 time;
    }

     
    mapping(address => CoinAgeRecord[]) coinAgeRecordMap;

     
    modifier canMint() {
        require(stakeStartTime > 0 && now >= stakeStartTime && totalSupply_ < MAX_TOTAL_SUPPLY);             
        _;
    }

    constructor() public {
        chainStartTime = now;                                                                                
        chainStartBlockNumber = block.number;

        stakeMinAge = 3 days;
        stakeMaxAge = 60 days;

        balances[msg.sender] = INITIAL_SUPPLY;
        totalSupply_ = INITIAL_SUPPLY;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));

        if (msg.sender == _to) {
            return mint();
        }

        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        logCoinAgeRecord(msg.sender, _to, _value);

        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

         
        if (_from != _to) {
            logCoinAgeRecord(_from, _to, _value);
        }

        return true;
    }

     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool) {
        require(_spender != address(0));
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function mint() public whenNotPaused canMint returns (bool) {
        if (balances[msg.sender] <= 0) {
            return false;
        }

        if (coinAgeRecordMap[msg.sender].length <= 0) {
            return false;
        }

        uint256 reward = calculateRewardInternal(msg.sender, now);                                           
        if (reward <= 0) {
            return false;
        }

        if (reward > MAX_TOTAL_SUPPLY.sub(totalSupply_)) {
            reward = MAX_TOTAL_SUPPLY.sub(totalSupply_);
        }

        totalSupply_ = totalSupply_.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        emit Mint(msg.sender, reward);
        emit Transfer(address(0), msg.sender, reward);

        uint64 _now = uint64(now);                                                                           
        delete coinAgeRecordMap[msg.sender];
        coinAgeRecordMap[msg.sender].push(CoinAgeRecord(balances[msg.sender], _now));
        emit CoinAgeResetEvent(msg.sender, balances[msg.sender], _now);

        return true;
    }

     
    function coinAge() public view returns (uint256) {
        return getCoinAgeInternal(msg.sender, now);                                                          
    }

     
    function annualInterest() public view returns(uint256) {
        return getAnnualInterest(now);                                                                       
    }

     
    function calculateReward() public view returns (uint256) {
        return calculateRewardInternal(msg.sender, now);                                                     
    }

     
    function calculateRewardAt(uint256 _now) public view returns (uint256) {
        return calculateRewardInternal(msg.sender, _now);
    }

     
    function coinAgeRecordForAddress(address _address, uint256 _index) public view onlyOwner returns (uint256, uint64) {
        if (coinAgeRecordMap[_address].length > _index) {
            return (coinAgeRecordMap[_address][_index].amount, coinAgeRecordMap[_address][_index].time);
        } else {
            return (0, 0);
        }
    }

     
    function coinAgeForAddress(address _address) public view onlyOwner returns (uint256) {
        return getCoinAgeInternal(_address, now);                                                            
    }

     
    function coinAgeForAddressAt(address _address, uint256 _now) public view onlyOwner returns (uint256) {
        return getCoinAgeInternal(_address, _now);
    }

     
    function calculateRewardForAddress(address _address) public view onlyOwner returns (uint256) {
        return calculateRewardInternal(_address, now);                                                       
    }

     
    function calculateRewardForAddressAt(address _address, uint256 _now) public view onlyOwner returns (uint256) {
        return calculateRewardInternal(_address, _now);
    }

     
    function startStakingAt(uint256 timestamp) public onlyOwner {
        require(stakeStartTime <= 0 && timestamp >= chainStartTime && timestamp > now);                      
        stakeStartTime = timestamp;
    }

     
    function isContract(address _address) private view returns (bool) {
        uint256 length;
         
        assembly {
             
            length := extcodesize(_address)
        }
        return (length>0);
    }


     
    function logCoinAgeRecord(address _from, address _to, uint256 _value) private returns (bool) {
        if (coinAgeRecordMap[_from].length > 0) {
            delete coinAgeRecordMap[_from];
        }

        uint64 _now = uint64(now);                                                                           

        if (balances[_from] != 0 && !isContract(_from)) {
            coinAgeRecordMap[_from].push(CoinAgeRecord(balances[_from], _now));
            emit CoinAgeResetEvent(_from, balances[_from], _now);
        }

        if (_value != 0 && !isContract(_to)) {
            coinAgeRecordMap[_to].push(CoinAgeRecord(_value, _now));
            emit CoinAgeRecordEvent(_to, _value, _now);
        }

        return true;
    }

     
    function calculateRewardInternal(address _address, uint256 _now) private view returns (uint256) {
        uint256 _coinAge = getCoinAgeInternal(_address, _now);
        if (_coinAge <= 0) {
            return 0;
        }

        uint256 interest = getAnnualInterest(_now);

        return (_coinAge.mul(interest)).div(365 * 100);
    }

     
    function getCoinAgeInternal(address _address, uint256 _now) private view returns (uint256 _coinAge) {
        if (coinAgeRecordMap[_address].length <= 0) {
            return 0;
        }

        for (uint256 i = 0; i < coinAgeRecordMap[_address].length; i++) {
            if (_now < uint256(coinAgeRecordMap[_address][i].time).add(stakeMinAge)) {
                continue;
            }

            uint256 secondsPassed = _now.sub(uint256(coinAgeRecordMap[_address][i].time));
            if (secondsPassed > stakeMaxAge ) {
                secondsPassed = stakeMaxAge;
            }

            _coinAge = _coinAge.add((coinAgeRecordMap[_address][i].amount).mul(secondsPassed.div(1 days)));
        }
    }

     
    function getAnnualInterest(uint256 _now) private view returns(uint256 interest) {
        if (stakeStartTime > 0 && _now >= stakeStartTime && totalSupply_ < MAX_TOTAL_SUPPLY) {
            uint256 secondsPassed = _now.sub(stakeStartTime);
             
            if (secondsPassed <= 365 days) {
                interest = 30;
            } else if (secondsPassed <= 547 days) {   
                interest = 25;
            } else if (secondsPassed <= 730 days) {   
                interest = 20;
            } else if (secondsPassed <= 911 days) {   
                interest = 15;
            } else if (secondsPassed <= 1094 days) {   
                interest = 10;
            } else {   
                interest = 5;
            }
        } else {
            interest = 0;
        }
    }

     
    function batchTransfer(address[] _recipients, uint256[] _values) public onlyOwner returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        uint256 total = 0;
        for(uint256 i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);                                                                           
        for(uint256 j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _recipients[j], _values[j]);

            coinAgeRecordMap[_recipients[j]].push(CoinAgeRecord(_values[j], _now));
            emit CoinAgeRecordEvent(_recipients[j], _values[j], _now);
        }

        return true;
    }
}