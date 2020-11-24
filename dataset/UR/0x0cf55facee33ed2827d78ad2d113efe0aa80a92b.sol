 

pragma solidity ^0.4.18;

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

 
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() constant public returns (uint256);
    function annualInterest() constant public returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract BITTOToken is ERC20,PoSTokenStandard,Ownable {
    using SafeMath for uint256;

    string public name = "BITTO";
    string public symbol = "BITTO";
    uint public decimals = 18;

    uint public chainStartTime;  
    uint public chainStartBlockNumber;  
    uint public stakeStartTime;  
    uint public stakeMinAge = 15 days;  
    uint public stakeMaxAge = 90 days;  
     
    uint constant REWARDS_PER_AGE = 622665006227000;   

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    mapping(address => bool) public noPOSRewards;

    struct transferInStruct {
        uint128 amount;
        uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event Burn(address indexed burner, uint256 value);

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    function BITTOToken() public {
         
        maxTotalSupply = 223 * 10**23;  
        totalInitialSupply = 173 * 10**23;  

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if (msg.sender == _to)
            return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        if (transferIns[msg.sender].length > 0)
            delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        if (transferIns[_from].length > 0)
            delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mint() canPoSMint public returns (bool) {
         
        if (balances[msg.sender] < 5000 ether)
            return false;
        if (transferIns[msg.sender].length <= 0)
            return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if (reward <= 0)
            return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        Transfer(address(0), msg.sender, reward);
        Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() view public returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() constant public returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() constant public returns (uint interest) {
         
         
         
         
         
         
         

        return REWARDS_PER_AGE;
    }

    function getProofOfStakeReward(address _address) internal returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(!noPOSRewards[_address]);

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if (_coinAge <= 0)
            return 0;

         
         
         
         
         
         
         
         
         
         

         
        return _coinAge.mul(REWARDS_PER_AGE);
    }

    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if (transferIns[_address].length <= 0)
            return 0;

        for (uint i = 0; i < transferIns[_address].length; i++) {
            if (_now < uint(transferIns[_address][i].time).add(stakeMinAge))
                continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if ( nCoinSeconds > stakeMaxAge )
                nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
        _coinAge = _coinAge.div(5000 ether);
    }

    function ownerSetStakeStartTime(uint timestamp) onlyOwner public {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function ownerBurnToken(uint _value) onlyOwner public {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        maxTotalSupply = maxTotalSupply.sub(_value*10);

        Burn(msg.sender, _value);
    }

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

     
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for (uint j = 0; j < _recipients.length; j++) {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if (transferIns[msg.sender].length > 0)
            delete transferIns[msg.sender];
        if (balances[msg.sender] > 0)
            transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }

    function disablePOSReward(address _account, bool _enabled) onlyOwner public {
        noPOSRewards[_account] = _enabled;
    }
}