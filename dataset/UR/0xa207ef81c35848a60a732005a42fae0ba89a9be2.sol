 

pragma solidity >= 0.4.22 < 0.6.0;

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

contract Token {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) balances;
	mapping(address => bool) public frozenAccount;
    uint256 totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
      return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
      require(_value <= balances[msg.sender]);
      require(_to != address(0));
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_value <= balances[_from], "Not enough balance");
       
       
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
       
      emit Transfer(_from, _to, _value);
      return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
    }

    function allowance(address _owner,address _spender) public view returns (uint256) {
      return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public returns (bool) {
      allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public returns (bool) {
      uint256 oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue >= oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }

      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }
}

contract Stablecoin is Token {
    string public name = 'Mundo Gold Tethered';
    string public symbol = 'MGT';
    uint256 public decimals = 4;
    address payable public owner;
    uint256 public totalSupplyLimit_;
    event BuyToken(address from, address to, uint256 value);
    event SellToken(address from, address to , uint256 value);
    event Minted(address to, uint256 value);
    event Burn(address burner, uint256 value);
	event FrozenFunds(address target, bool frozen);

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor ( 
        )  public Token() {
       
      totalSupplyLimit_ = 2500000000000;
      owner = msg.sender;
      mint(owner, totalSupplyLimit_);
    }

    function mint(address _to, uint256 _value) onlyOwner public
        returns (bool)
    {
      if (totalSupplyLimit_ >= totalSupply_ + _value) {
        balances[_to] = balances[_to].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        emit Minted(_to, _value);
        return true;
      }
      return false;
    }

     
    function verifyTransfer(uint256 _value)
        public pure returns (bool) {
      require(_value >= 0);
      return true;
    }

    function burnTokens(address _investor, uint256 _value) onlyOwner public {
      balances[_investor] = balances[_investor].sub(_value);
      totalSupply_ = totalSupply_.sub(_value);
      emit Burn(owner, _value);
    }

    function buyTokens(address _investor, uint256 _amount) onlyOwner public {
       
       
      emit BuyToken(owner, _investor, _amount);
      transferFrom(owner, _investor, _amount);
    }

    function sellTokens(address _investor, uint256 _amount) onlyOwner public {
       
       
      emit SellToken(_investor, owner, _amount);
       
      burnTokens(_investor, _amount);
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
       
        require(!frozenAccount[msg.sender]);                      
      return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyOwner public
        returns(bool) {
        require(!frozenAccount[_from]);                      
       
      return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) onlyOwner public returns(bool) {
      return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) onlyOwner public
        returns(bool success) {
      return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) onlyOwner public returns(bool success) {
      return super.decreaseApproval(_spender, _subtractedValue);
    }

    function emergencyExtract() external onlyOwner {
      owner.transfer(address(this).balance);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
	
	function kill() onlyOwner public{
	    selfdestruct(msg.sender);
    }
}