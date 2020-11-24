 

pragma solidity ^0.5.1;
library SafeMath {
   
  function Smul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }
      uint256 z = a * b;
      assert((a == 0)||(z/a == b));
      return z;
  }
   
  function Sdiv(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
          return 0;
      }
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }
   
  function Ssub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(a >= b, 'First parameter must be greater than second');
      assert(a >= b);
      uint256 z = a - b;
      return z;
  }
   
  function Sadd(uint256 a, uint256 b) internal pure returns (uint256 c) {
      uint256 z = a + b;
      require((z >= a) && (z >= b),'Result must be greater than parameters');
      assert((z >= a) && (z >= b));
      return z;
  }
}

contract ERC20Basic {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public payable returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  bool internal pause = false;
  modifier chk_paused(){
      require(pause == false,'Sorry, contract paused by the administrator');
      _;
  }
}

contract ERC20 is ERC20Basic {
function totalSupply() public view returns (uint);
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public  payable returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) internal balances;
  struct partners{
      uint256 seq;
      address owner;
  }
  mapping(uint => partners) internal store;
  uint256 internal totalPartners_;
  uint256 internal div_bal_;
   
  function transfer(address _to, uint256 _value) public payable  returns (bool) {
    require(_to != address(0),'Address need to be different of zero');
    require(_value <= balances[msg.sender],'Value is greater than balance');
    require(pause == false,'Contract paused to pay dividends or other reason especified in polidatacompressor.com');
    if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] = balances[msg.sender].Ssub(_value);
         
        bool exists_ = false;
        for (uint i = 1 ; i <= totalPartners_ ; i++) {
            if (store[i].owner == _to){
                exists_ = true;
            }
        }
        if (exists_ == false){
           totalPartners_ = totalPartners_.Sadd(1);
           store[totalPartners_].seq = totalPartners_;
           store[totalPartners_].owner = _to;
        }
        balances[_to] = balances[_to].Sadd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  address internal owner;
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public  payable  chk_paused()
    returns (bool)
  {
    require(_to != address(0),'Address need to be different of zero');
    require(_value <= balances[_from],'Value is greater than balance');
    require(_value <= allowed[_from][msg.sender],'Value is greater than allowed');

    balances[_from] = balances[_from].Ssub(_value);
    balances[_to] = balances[_to].Sadd(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].Ssub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
   
  function approve(address _spender, uint256 _value) public chk_paused() returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
   
  function allowance(
    address _owner,
    address _spender
   ) public view returns (uint256){
    return allowed[_owner][_spender];
  }
   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public chk_paused()
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].Sadd(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  ) public chk_paused() returns (bool){
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.Ssub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract PoliToken is StandardToken {
  string public constant name = "PoliToken";
  string public constant symbol = "POLI";
  uint256 public constant INITIAL_SUPPLY = 10000000;
  
  constructor() public  {
    totalPartners_ = 1;
    store[totalPartners_].seq = totalPartners_;
    store[totalPartners_].owner = msg.sender;
    owner = msg.sender;
    div_bal_ = address(this).balance;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
      function totalSupply() public view returns (uint) {
        return INITIAL_SUPPLY;
    }
   function paying_dividends(uint _seq_ini, uint _seq_fim) external onlyOwner() onlyPaused() {
      require(_seq_fim >= _seq_ini, 'first parameter must be greater than second');
      uint256 tot_;
      uint256 div_;
      uint256 max_partners_;
      uint gas_;
      tot_ = div_bal_;
      max_partners_ = totalPartners_;
      if (max_partners_ > _seq_fim){
          max_partners_ = _seq_fim;
      }
      for (uint i = _seq_ini; i <= max_partners_; i++){
          div_ = balances[store[i].owner].Smul(tot_).Sdiv(INITIAL_SUPPLY);
          gas_ = gasleft();
          store[i].owner.call.value(div_).gas(gas_)("");
      }
      if (max_partners_ == totalPartners_){
          div_bal_ = 0;
      }
  }
  function deposits_and_donations() external payable noZero() returns(bool){
      if (pause != true){
         div_bal_ = address(this).balance;
      }
      return true;
  }
  function change_pause(bool _pause) external onlyOwner returns(bool){
      pause = _pause;
      div_bal_ = address(this).balance;
      return true;
  }
  function chk_pause() external view returns(bool){
      return pause;
  }
  function chk_balance() external view returns(uint){
      return address(this).balance;
  }
  function chk_balance_dividends() external view returns(uint){
      return div_bal_;
  }
  function transfer_owner(address _owner) external onlyOwner returns(bool){
      owner = _owner;
      return true;
  }
  function chk_active_owner() external view returns(address){
      return owner;
  }
  function chk_total_partners() external view returns(uint){
      return totalPartners_;
  }
  function chk_partner_address(uint i) external view returns(address){
      return store[i].owner;
  }
  modifier onlyOwner(){
      require(msg.sender == owner, 'Sorry, you must be owner');
      _;
  }
  modifier onlyPaused(){
      require(pause == true,'You need pause transactions to execute this');
      _;
  }
  modifier noZero(){
      require(msg.value > 0,'Value must be greater than zero');
      _;
  }
}