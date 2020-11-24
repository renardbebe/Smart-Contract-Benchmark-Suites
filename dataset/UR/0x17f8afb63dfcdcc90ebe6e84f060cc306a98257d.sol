 

pragma solidity 0.4.19;

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

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}
contract NebulaToken is CappedToken{
    using SafeMath for uint256;
    string public constant name = "Nebula AI Token";
    string public constant symbol = "NBAI";
    uint8 public constant decimals = 18;

    bool public pvt_plmt_set;
    uint256 public pvt_plmt_max_in_Wei;
    uint256 public pvt_plmt_remaining_in_Wei;
    uint256 public pvt_plmt_token_generated;

    TokenVesting public foundation_vesting_contract;
    uint256 public token_unlock_time = 1524887999;  

    mapping(address => TokenTimelock[]) public time_locked_reclaim_addresses;

     
     
    function NebulaToken() CappedToken(6700000000 * 1 ether) public{
        uint256 foundation_held = cap.mul(55).div(100); 
        address foundation_beneficiary_wallet = 0xD86FCe1890bf98fC086b264a66cA96C7E3B03B40; 
        foundation_vesting_contract = new TokenVesting(foundation_beneficiary_wallet, 1524283200, 0, 3 years, false);
        assert(mint(foundation_vesting_contract, foundation_held));
        FoundationTokenGenerated(foundation_vesting_contract, foundation_beneficiary_wallet, foundation_held);
    }

     
     
    function create_public_sale_token(address _beneficiary, uint256 _token_amount) external onlyOwner returns(bool){
        assert(mint_time_locked_token(_beneficiary, _token_amount) != address(0));
        return true;
    }

     
    function set_private_sale_total(uint256 _pvt_plmt_max_in_Wei) external onlyOwner returns(bool){
        require(!pvt_plmt_set && _pvt_plmt_max_in_Wei >= 5000 ether); 
        pvt_plmt_set = true;
        pvt_plmt_max_in_Wei = _pvt_plmt_max_in_Wei;
        pvt_plmt_remaining_in_Wei = pvt_plmt_max_in_Wei;
        PrivateSalePlacementLimitSet(pvt_plmt_max_in_Wei);
    }
     
    function distribute_private_sale_fund(address _beneficiary, uint256 _wei_amount, uint256 _rate) public onlyOwner returns(bool){
        require(pvt_plmt_set && _beneficiary != address(0) && pvt_plmt_remaining_in_Wei >= _wei_amount && _rate >= 100000 && _rate <= 125000);

        pvt_plmt_remaining_in_Wei = pvt_plmt_remaining_in_Wei.sub(_wei_amount); 
        uint256 _token_amount = _wei_amount.mul(_rate);  
        pvt_plmt_token_generated = pvt_plmt_token_generated.add(_token_amount); 

         
        address _ret;
        if(now < token_unlock_time) assert((_ret = mint_time_locked_token(_beneficiary, _token_amount))!=address(0));
        else assert(mint(_beneficiary, _token_amount));

        PrivateSaleTokenGenerated(_ret, _beneficiary, _token_amount);
        return true;
    }
     
     
    function mint_time_locked_token(address _beneficiary, uint256 _token_amount) internal returns(TokenTimelock _locked){
        _locked = new TokenTimelock(this, _beneficiary, token_unlock_time);
        time_locked_reclaim_addresses[_beneficiary].push(_locked);
        assert(mint(_locked, _token_amount));
    }

     
     
    function release_all(address _beneficiary) external returns(bool){
        require(time_locked_reclaim_addresses[_beneficiary].length > 0);
        TokenTimelock[] memory _locks = time_locked_reclaim_addresses[_beneficiary];
        for(uint256 i = 0 ; i < _locks.length; ++i) _locks[i].release();
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool){
        require(pvt_plmt_set && pvt_plmt_remaining_in_Wei == 0);
        super.finishMinting();
    }

    function get_time_locked_contract_size(address _owner) external view returns(uint256){
        return time_locked_reclaim_addresses[_owner].length;
    }

    event PrivateSaleTokenGenerated(address indexed _time_locked, address indexed _beneficiary, uint256 _amount);
    event FoundationTokenGenerated(address indexed _vesting, address indexed _beneficiary, uint256 _amount);
    event PrivateSalePlacementLimitSet(uint256 _limit);
    function () public payable{revert();} 
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
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}