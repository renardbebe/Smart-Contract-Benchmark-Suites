 

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


 
library SafeMathForBoost {
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


contract Boost {
    using SafeMathForBoost for uint256;

    string public name = "Boost";
    uint8 public decimals = 0;
    string public symbol = "BST";
    uint256 public totalSupply = 100000000;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
     
    struct  Checkpoint {

         
        uint256 fromBlock;

         
        uint256 value;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

     
    function Boost() public {
        balances[msg.sender].push(Checkpoint({
            fromBlock:block.number,
            value:totalSupply
        }));
    }

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal {

         
        require((_to != 0) && (_to != address(this)) && (_amount != 0));

         
         
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        updateValueAtNow(balances[_from], previousBalanceFrom.sub(_amount));

         
         
        var previousBalanceTo = balanceOfAt(_to, block.number);
        updateValueAtNow(balances[_to], previousBalanceTo.add(_amount));

         
        Transfer(_from, _to, _amount);

    }

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) internal view  returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = block.number;
            newCheckPoint.value = _value;
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = _value;
        }
    }

     
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}


 
contract BoostCrowdsale is Ownable {
    using SafeMathForBoost for uint256;

     
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public rate;

     
    address public wallet;

     
    Boost public boost;

     
    uint256 public cap;

     
    uint256 public weiRaised;

     
    uint256 public minimumAmount = 0.1 ether;

     
    uint256 public soldAmount;

     
    bool public isFinalized = false;

     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

     
    event Finalized();

     
    function BoostCrowdsale(uint256 _startTime, uint256 _endTime, address _boostAddress, uint256 _rate, address _wallet, uint256 _cap) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_boostAddress != address(0));
        require(_rate > 0);
        require(_wallet != address(0));
        require(_cap > 0);

        startTime = _startTime;
        endTime = _endTime;
        boost = Boost(_boostAddress);
        rate = _rate;
        wallet = _wallet;
        cap = _cap;
    }

     
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function() public payable {
        uint256 weiAmount = msg.value;

         
        uint256 tokens = getTokenAmount(weiAmount);

        require(validPurchase(tokens));

         
        weiRaised = weiRaised.add(weiAmount);
        soldAmount = soldAmount.add(tokens);

         
        boost.transfer(msg.sender, tokens);
        TokenPurchase(msg.sender, weiAmount, tokens);

        forwardFunds();
    }

     
    function hasEnded() public view returns (bool) {
        bool overPeriod = now > endTime;
        bool underPurchasableAmount = getPurchasableAmount() < 10000;
        return overPeriod || underPurchasableAmount;
    }

     
    function getPurchasableAmount() public view returns (uint256) {
        return boost.balanceOf(this);
    }

     
    function getSendableEther() public view returns (uint256) {
        return boost.balanceOf(this).mul(10 ** 18).div(rate);
    }

     
    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate).div(10 ** 18);
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function finalization() internal {
        if (boost.balanceOf(this) > 0) {
            require(boost.transfer(owner, boost.balanceOf(this)));
        }
    }

     
    function validPurchase(uint256 _tokens) internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool moreThanOrEqualToMinimumAmount = msg.value >= minimumAmount;
        bool validPurchasableAmount = cap >= soldAmount.add(_tokens);
        return withinPeriod && moreThanOrEqualToMinimumAmount && validPurchasableAmount;
    }
}