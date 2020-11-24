 

pragma solidity 0.4.25;


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
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

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _address) public view returns (uint);

  function name() public view returns (string _name);
  function symbol()public view returns (string _symbol);
  function decimals()public view returns (uint8 _decimals);
  function totalSupply()public view returns (uint256 _supply);

  function transfer(address to, uint value)public returns (bool ok);
  function transfer(address to, uint value, bytes data)public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC20Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback (address _from, uint _value, bytes _data) public;
}

 
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge(address staker) public view returns (uint256);
    function annualInterest() public view returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract BitUnits is ERC20, PoSTokenStandard {
    using SafeMath for uint256;

    string public name = "BitUnits";
    string public symbol = "UNITX";
    uint8 public decimals = 8;

    uint public chainStartTime;  
    uint public chainStartBlockNumber;  
    uint public stakeStartTime;  
    uint public stakeMinAge = 3 days;  
    uint public stakeMaxAge = 90 days;  
    uint public maxMintProofOfStake = 5*10**14 ;  

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    struct transferInStruct{
        uint128 amount;
        uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => transferInStruct[]) transferIns;

    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }


    function UNITX() public {
        maxTotalSupply = 10**15;  
        totalInitialSupply = 5*10**14;  

        chainStartTime = now;
        stakeStartTime = now + 1 days;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

     
    function isContract(address _Tokenaddr) private returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize( _Tokenaddr)
        }
        return (length > 0);
    }

     
     function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        if(isContract(_to)) {
          return transferToContract(_to, _value, _data);
        } else {
          return transferToAddress(_to, _value, _data);
        }
    }

     
     
     function transfer(address _to, uint _value) public returns (bool success) {
         
         
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
      if(msg.sender == _to) return mint();
      if(balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);

      if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
      uint64 _now = uint64(now);
      transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
      transferIns[_to].push(transferInStruct(uint128(_value),_now));

      emit Transfer (msg.sender, _to, _value);
      emit ERC20Transfer (msg.sender, _to, _value, _data);
      return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
      if(msg.sender == _to) return mint();
      if (balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      ContractReceiver reciever = ContractReceiver(_to);
      reciever.tokenFallback(msg.sender, _value, _data);

      if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
      uint64 _now = uint64(now);
      transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
      transferIns[_to].push(transferInStruct(uint128(_value),_now));

      emit Transfer(msg.sender, _to, _value);
      emit ERC20Transfer(msg.sender, _to, _value, _data);
      return true;
    }

    function mint() public canPoSMint returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Mint(msg.sender, reward);
        return true;
    }


    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }


    function coinAge(address staker) public view returns (uint256) {
        return getCoinAge(staker, now);
    }


    function annualInterest() public view returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            interest = (435 * maxMintProofOfStake).div(100);
        }
    }


    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = maxMintProofOfStake;
         
         
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
             
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
             
            interest = (435 * maxMintProofOfStake).div(100);
        }

        uint offset = 10**uint(decimals);

        return (_coinAge * interest).div(365 * offset);
    }


    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function balanceOf(address _owner)public view returns (uint balance) {
      return balances[_owner];
    }

    
    function name() public constant returns (string _name) {
        return name;
    }
     
    function symbol()public constant returns (string _symbol) {
        return symbol;
    }
     
    function decimals()public constant returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply()public constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
}