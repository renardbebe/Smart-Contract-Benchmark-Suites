 

  
 
 


pragma solidity ^0.4.25;


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b,"Math error");

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0,"Math error");  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a,"Math error");
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a,"Math error");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Math error");
        return a % b;
    }
}


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal balances_;

    mapping (address => mapping (address => uint256)) private allowed_;

    uint256 private totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances_[_owner];
    }

   
    function allowance(
        address _owner,
        address _spender
    )
      public
      view
      returns (uint256)
    {
        return allowed_[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances_[msg.sender],"Invalid value");
        require(_to != address(0),"Invalid address");

        balances_[msg.sender] = balances_[msg.sender].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
      public
      returns (bool)
    {
        require(_value <= balances_[_from],"Value is more than balance");
        require(_value <= allowed_[_from][msg.sender],"Value is more than alloved");
        require(_to != address(0),"Invalid address");

        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
      public
      returns (bool)
    {
        allowed_[msg.sender][_spender] = (allowed_[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
      public
      returns (bool)
    {
        uint256 oldValue = allowed_[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed_[msg.sender][_spender] = 0;
        } else {
            allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

     
    function _mint(address _account, uint256 _amount) internal returns (bool) {
        require(_account != 0,"Invalid address");
        totalSupply_ = totalSupply_.add(_amount);
        balances_[_account] = balances_[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
        return true;
    }

     
    function _burn(address _account, uint256 _amount) internal returns (bool) {
        require(_account != 0,"Invalid address");
        require(_amount <= balances_[_account],"Amount is more than balance");

        totalSupply_ = totalSupply_.sub(_amount);
        balances_[_account] = balances_[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

}



 
contract PiggyToken is ERC20 {
    string public constant name = "PiggyBank Token";
    string public constant symbol = "Piggy";
    uint32 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 0;  
    address public piggyBankAddress;
    


    constructor(address _piggyBankAddress) public {
        piggyBankAddress = _piggyBankAddress;
    }


    modifier onlyPiggyBank() {
        require(msg.sender == piggyBankAddress,"Only PiggyBank contract can run this");
        _;
    }
    
    modifier validDestination( address to ) {
        require(to != address(0x0),"Empty address");
        require(to != address(this),"PiggyBank Token address");
        _;
    }
    

     
    function transfer(address _to, uint256 _value) public validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public validDestination(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
     
    function mint(address _to, uint256 _value) public onlyPiggyBank returns (bool) {
        return super._mint(_to, _value);
    }

     
    function burn(address _to, uint256 _value) public onlyPiggyBank returns (bool) {
        return super._burn(_to, _value);
    }

    function() external payable {
        revert("The token contract don`t receive ether");
    }  
}





 
contract PiggyBank {
    using SafeMath for uint256;
    address public owner;
    address creator;



    address myAddress = this;
    PiggyToken public token = new PiggyToken(myAddress);


     
    uint256 public rate;

     
    uint256 public weiRaised;

    event Invest(
        address indexed investor, 
        uint256 tokens,
        uint256 weiAmount,
        uint256 rate
    );

    event Withdraw(
        address indexed to, 
        uint256 tokens,
        uint256 weiAmount,
        uint256 rate
    );

    event TokenPrice(
        uint256 value
    );

    constructor() public {
        owner = 0x0;
        creator = msg.sender;
        rate = 1 ether;
    }

     
     
     

     
    function () external payable {
        if (msg.value > 0) {
            _buyTokens(msg.sender);
        } else {
            require(msg.data.length == 0,"Only for simple payments");
            _takeProfit(msg.sender);
        }

    }

     
    function _buyTokens(address _beneficiary) internal {
        uint256 weiAmount = msg.value.mul(9).div(10);
        uint256 creatorBonus = msg.value.div(100);
        require(_beneficiary != address(0),"Invalid address");

         
        uint256 tokens = _getTokenAmount(weiAmount);
        uint256 creatorTokens = _getTokenAmount(creatorBonus);

         
        weiRaised = weiRaised.add(weiAmount);
         

        _processPurchase(_beneficiary, tokens);
        _processPurchase(creator, creatorTokens);
        
        emit Invest(_beneficiary, tokens, msg.value, rate);

    }


     
     
     

    function _takeProfit(address _beneficiary) internal {
        uint256 tokens = token.balanceOf(_beneficiary);
        uint256 weiAmount = tokens.mul(rate).div(1 ether);
        token.burn(_beneficiary, tokens);
        _beneficiary.transfer(weiAmount);
        _updatePrice();
        
        emit Withdraw(_beneficiary, tokens, weiAmount, rate);
    }


    function _updatePrice() internal {
        uint256 oldPrice = rate;
        if (token.totalSupply()>0){
            rate = myAddress.balance.mul(1 ether).div(token.totalSupply());
            if (rate != oldPrice){
                emit TokenPrice(rate);
            }
        }
    }


     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.mint(_beneficiary, _tokenAmount);
    }


     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 resultAmount = _weiAmount;
        return resultAmount.mul(1 ether).div(rate);
    }

}