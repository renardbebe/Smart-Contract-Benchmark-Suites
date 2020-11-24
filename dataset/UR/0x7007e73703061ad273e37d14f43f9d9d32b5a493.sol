 

pragma solidity ^0.4.18;

pragma solidity ^0.4.18;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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



 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
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


 

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

contract PAXToken is BurnableToken, PausableToken {

    using SafeMath for uint;

    string public constant name = "Pax Token";

    string public constant symbol = "PAX";

    uint32 public constant decimals = 10;

    uint256 public constant INITIAL_SUPPLY = 999500000 * (10 ** uint256(decimals));

     
    function PAXToken(address _company, address _founders_1, address _founders_2, bool _isPause) public {
        require(_company != address(0) && _founders_1 != address(0) && _founders_2 != address(0));
        paused = _isPause;
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = 349500000 * (10 ** uint256(decimals));
        balances[_company] = 300000000 * (10 ** uint256(decimals));
        balances[_founders_1] = 300000000 * (10 ** uint256(decimals));
        balances[_founders_2] = 50000000 * (10 ** uint256(decimals));
        emit Transfer(0x0, msg.sender, balances[msg.sender]);
        emit Transfer(0x0, _company, balances[_company]);
        emit Transfer(0x0, _founders_1, balances[_founders_1]);
        emit Transfer(0x0, _founders_2, balances[_founders_2]);

    }

     
    function ownersTransfer(address _to, uint256 _value) public onlyOwner returns (bool) {
        return BasicToken.transfer(_to, _value);
    }
}

contract Crowdsale is Pausable {

    struct stageInfo {
        uint start;
        uint stop;
        uint duration;
        uint bonus;
        uint limit;
    }

     
    mapping (uint => stageInfo) public stages;

     
    mapping(address => uint) public balances;

     
    uint public constant softcap = 2500 ether;

     
    uint public constant decimals = 1E10;

     
    uint public period = 5;

     
    uint public hardcap;

     
    uint public rate;

     
    uint public totalSold = 0;

     
    uint256 public sumWei;

     
    bool public state;

     
    bool public requireOnce = true;

     
    bool public isBurned;

     
    address public company;

     
    address public founders_1;

     
    address public founders_2;

     
    address public multisig;

     
    PAXToken public token;

     
    uint private constant typicalBonus = 100;

     
    uint private sendingTokens;

     
    uint private timeLeft;

     
    uint private pauseDate;

     
    bool private pausedByValue;

     
    bool private manualPause;


    event StartICO();

    event StopICO();

    event BurnUnsoldTokens();

    event NewWalletAddress(address _to);

    event Refund(address _wallet, uint _val);

    event DateMoved(uint value);

    using SafeMath for uint;

    modifier saleIsOn() {
        require(state);
        uint stageId = getStageId();
        if (period != stageId || stageId == 5) {
            usersPause();
            (msg.sender).transfer(msg.value);
        }
        else
            _;
    }

    modifier isUnderHardCap() {
        uint tokenBalance = token.balanceOf(this);
        require(
            tokenBalance <= hardcap &&
            tokenBalance >= 500
        );
        _;
    }


    function Crowdsale(address _company, address _founders_1, address _founders_2, address _token) public {
        multisig = owner;
        rate = (uint)(1 ether).div(5000);

        stages[0] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 130,
            limit:  44500000 * decimals
            });

        stages[1] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 115,
            limit:  85000000 * decimals
            });

        stages[2] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 110,
            limit:  100000000 * decimals
            });

        stages[3] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 105,
            limit:  120000000 * decimals
            });

        hardcap = 349500000 * decimals;

        token = PAXToken(_token);

        company = _company;
        founders_1 = _founders_1;
        founders_2 = _founders_2;
    }


     
    function() whenNotPaused saleIsOn external payable {
        require (msg.value > 0);
        sendTokens(msg.value, msg.sender);
    }

     
    function manualSendTokens(address _to, uint256 _value) public onlyOwner returns(bool) {
        uint tokens = _value;
        uint avalibleTokens = token.balanceOf(this);

        if (tokens < avalibleTokens) {
            if (tokens <= stages[3].limit) {
                stages[3].limit = (stages[3].limit).sub(tokens);
            } else if (tokens <= (stages[3].limit).add(stages[2].limit)) {
                stages[2].limit = (stages[2].limit).sub(tokens.sub(stages[3].limit));
                stages[3].limit = 0;
            } else if (tokens <= (stages[3].limit).add(stages[2].limit).add(stages[1].limit)) {
                stages[1].limit = (stages[1].limit).sub(tokens.sub(stages[3].limit).sub(stages[2].limit));
                stages[3].limit = 0;
                stages[2].limit = 0;
            } else if (tokens <= (stages[3].limit).add(stages[2].limit).add(stages[1].limit).add(stages[0].limit)) {
                stages[0].limit = (stages[0].limit).sub(tokens.sub(stages[3].limit).sub(stages[2].limit).sub(stages[1].limit));
                stages[3].limit = 0;
                stages[2].limit = 0;
                stages[1].limit = 0;
            }
        } else {
            tokens = avalibleTokens;
            stages[3].limit = 0;
            stages[2].limit = 0;
            stages[1].limit = 0;
            stages[0].limit = 0;
        }

        sendingTokens = sendingTokens.add(tokens);
        sumWei = sumWei.add(tokens.mul(rate).div(decimals));
        totalSold = totalSold.add(tokens);
        token.ownersTransfer(_to, tokens);

        return true;
    }

     
    function refund() public {
        require(sumWei < softcap && !state);
        uint value = balances[msg.sender];
        balances[msg.sender] = 0;
        emit Refund(msg.sender, value);
        msg.sender.transfer(value);
    }

     
    function burnUnsoldTokens() onlyOwner public returns(bool) {
        require(!state);
        require(!isBurned);
        isBurned = true;
        emit BurnUnsoldTokens();
        token.burn(token.balanceOf(this));
        if (token.paused()) {
            token.unpause();
        }
        return true;
    }

     
    function startICO() public onlyOwner returns(bool) {
        require(stages[0].start >= now);
        require(requireOnce);
        requireOnce = false;
        state = true;
        period = 0;
        emit StartICO();
        token.ownersTransfer(company, (uint)(300000000).mul(decimals));
        token.ownersTransfer(founders_1, (uint)(300000000).mul(decimals));
        token.ownersTransfer(founders_2, (uint)(50000000).mul(decimals));
        return true;
    }

     
    function stopICO() onlyOwner public returns(bool) {
        state = false;
        emit StopICO();
        if (token.paused()) {
            token.unpause();
        }
        return true;
    }

     
    function pause() onlyOwner whenNotPaused public {
        manualPause = true;
        usersPause();
    }

     
    function unpause() onlyOwner whenPaused public {
        uint shift = now.sub(pauseDate);
        dateMove(shift);
        period = getStageId();
        pausedByValue = false;
        manualPause = false;
        super.unpause();
    }

     
    function withDrawal() public onlyOwner {
        if(!state && sumWei >= softcap) {
            multisig.transfer(address(this).balance);
        }
    }

     
    function getStageId() public view returns(uint) {
        uint stageId;
        uint today = now;

        if (today < stages[0].stop) {
            stageId = 0;

        } else if (today >= stages[1].start &&
        today < stages[1].stop ) {
            stageId = 1;

        } else if (today >= stages[2].start &&
        today < stages[2].stop ) {
            stageId = 2;

        } else if (today >= stages[3].start &&
        today < stages[3].stop ) {
            stageId = 3;

        } else if (today >= stages[3].stop) {
            stageId = 4;

        } else {
            return 5;
        }

        uint tempId = (stageId > period) ? stageId : period;
        return tempId;
    }

     
    function getStageData() public view returns(uint tempLimit, uint tempBonus) {
        uint stageId = getStageId();
        tempBonus = stages[stageId].bonus;

        if (stageId == 0) {
            tempLimit = stages[0].limit;

        } else if (stageId == 1) {
            tempLimit = (stages[0].limit).add(stages[1].limit);

        } else if (stageId == 2) {
            tempLimit = (stages[0].limit).add(stages[1].limit).add(stages[2].limit);

        } else if (stageId == 3) {
            tempLimit = (stages[0].limit).add(stages[1].limit).add(stages[2].limit).add(stages[3].limit);

        } else {
            tempLimit = token.balanceOf(this);
            tempBonus = typicalBonus;
            return;
        }
        tempLimit = tempLimit.sub(totalSold);
        return;
    }

     
    function calculateStagePrice() public view returns(uint price) {
        uint limit;
        uint bonusCoefficient;
        (limit, bonusCoefficient) = getStageData();

        price = limit.mul(rate).mul(100).div(bonusCoefficient).div(decimals);
    }

     
    function sendTokens(uint _etherValue, address _to) internal isUnderHardCap {
        uint limit;
        uint bonusCoefficient;
        (limit, bonusCoefficient) = getStageData();
        uint tokens = (_etherValue).mul(bonusCoefficient).mul(decimals).div(100);
        tokens = tokens.div(rate);
        bool needPause;

        if (tokens > limit) {
            needPause = true;
            uint stageEther = calculateStagePrice();
            period++;
            if (period == 4) {
                balances[msg.sender] = balances[msg.sender].add(stageEther);
                sumWei = sumWei.add(stageEther);
                token.ownersTransfer(_to, limit);
                totalSold = totalSold.add(limit);
                _to.transfer(_etherValue.sub(stageEther));
                state = false;
                return;
            }
            balances[msg.sender] = balances[msg.sender].add(stageEther);
            sumWei = sumWei.add(stageEther);
            token.ownersTransfer(_to, limit);
            totalSold = totalSold.add(limit);
            sendTokens(_etherValue.sub(stageEther), _to);

        } else {
            require(tokens <= token.balanceOf(this));
            if (limit.sub(tokens) < 500) {
                needPause = true;
                period++;
            }
            balances[msg.sender] = balances[msg.sender].add(_etherValue);
            sumWei = sumWei.add(_etherValue);
            token.ownersTransfer(_to, tokens);
            totalSold = totalSold.add(tokens);
        }

        if (needPause) {
            pausedByValue = true;
            usersPause();
        }
    }

     
    function usersPause() private {
        pauseDate = now;
        paused = true;
        emit Pause();
    }

     
    function dateMove(uint _shift) private returns(bool) {
        require(_shift > 0);

        uint i;

        if (pausedByValue) {
            stages[period].start = now;
            stages[period].stop = (stages[period].start).add(stages[period].duration);

            for (i = period + 1; i < 4; i++) {
                stages[i].start = stages[i - 1].stop;
                stages[i].stop = (stages[i].start).add(stages[i].duration);
            }

        } else {
            if (manualPause) stages[period].stop = (stages[period].stop).add(_shift);

            for (i = period + 1; i < 4; i++) {
                stages[i].start = (stages[i].start).add(_shift);
                stages[i].stop = (stages[i].stop).add(_shift);
            }
        }

        emit DateMoved(_shift);

        return true;
    }

     
    function tokensAmount() public view returns(uint) {
        return token.balanceOf(this);
    }

     
    function tokensSupply() public view returns(uint) {
        return token.totalSupply();
    }

     
    function setStartDate(uint _start) public onlyOwner returns(bool) {
        require(_start > now);
        require(requireOnce);

        stages[0].start = _start;
        stages[0].stop = _start.add(stages[0].duration);
        stages[1].start = stages[0].stop;
        stages[1].stop = stages[1].start.add(stages[1].duration);
        stages[2].start = stages[1].stop;
        stages[2].stop = stages[2].start.add(stages[2].duration);
        stages[3].start = stages[2].stop;
        stages[3].stop = stages[3].start.add(stages[3].duration);

        return true;
    }

     
    function setMultisig(address _to) public onlyOwner returns(bool) {
        require(_to != address(0));
        multisig = _to;
        emit NewWalletAddress(_to);
        return true;
    }

     
    function setReserveForCompany(address _company) public onlyOwner {
        require(_company != address(0));
        require(requireOnce);
        company = _company;
    }

     
    function setReserveForFoundersFirst(address _founders_1) public onlyOwner {
        require(_founders_1 != address(0));
        require(requireOnce);
        founders_1 = _founders_1;
    }

     
    function setReserveForFoundersSecond(address _founders_2) public onlyOwner {
        require(_founders_2 != address(0));
        require(requireOnce);
        founders_2 = _founders_2;
    }

}