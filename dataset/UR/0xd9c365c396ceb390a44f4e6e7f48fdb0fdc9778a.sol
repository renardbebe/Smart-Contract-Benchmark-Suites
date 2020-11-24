 

pragma solidity ^0.4.24;

 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
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


     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

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

contract KvantorSaleToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public name = "KVANTOR Sale token";
    string public symbol = "KVT_SALE";
    uint public decimals = 8;

    uint256 crowdsaleStartTime = 1535317200;
    uint256 crowdsaleFinishTime = 1537995600;


    address public kvtOwner = 0xe4ed7e14e961550c0ce7571df8a5b11dec9f7f52;
    ERC20 public kvtToken = ERC20(0x96c8aa08b1712dDe92f327c0dC7c71EcE6c06525);

    uint256 tokenMinted = 0;
     
    uint256 public tokenCap = 6000000000000000;
     
    uint256 public rate = 3061857781;
    
    uint256 public weiRaised = 0;
    address public wallet = 0x5B007Da9dBf09842Cb4751bd5BcD6ea2808256F5;

    constructor() public {
        
    }


     


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        if (this == _to) {
            require(kvtToken.transfer(msg.sender, _value));
            _burn(msg.sender, _value);
        } else {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
        }
        emit Transfer(msg.sender, _to, _value);
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
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        if (this == _to) {
            require(kvtToken.transfer(_from, _value));
            _burn(_from, _value);
        } else {
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);   
        }
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
     
    
    function calculateTokens(uint256 _weiAmount) view public returns (uint256) {
        
        uint256 tokens = _weiAmount.mul(rate).mul(100).div(75).div(100 finney);
        if(tokens.div(100000000) < 5000)
            return _weiAmount.mul(rate).mul(100).div(80).div(100 finney);
        
        tokens = _weiAmount.mul(rate).mul(100).div(73).div(100 finney);
        if(tokens.div(100000000) < 25000)
            return _weiAmount.mul(rate).mul(100).div(75).div(100 finney);
            
        tokens = _weiAmount.mul(rate).mul(100).div(70).div(100 finney);
        if(tokens.div(100000000) < 50000)
            return _weiAmount.mul(rate).mul(100).div(73).div(100 finney);
            
        tokens = _weiAmount.mul(rate).mul(100).div(65).div(100 finney);
        if(tokens.div(100000000) < 250000)
            return _weiAmount.mul(rate).mul(100).div(70).div(100 finney);
            
        tokens = _weiAmount.mul(rate).mul(100).div(60).div(100 finney);
        if(tokens.div(100000000) < 500000)
            return _weiAmount.mul(rate).mul(100).div(65).div(100 finney);
            
        return _weiAmount.mul(rate).mul(100).div(60).div(100 finney);
            
    }
    

    function buyTokens(address _beneficiary) public payable {
        require(crowdsaleStartTime <= now && now <= crowdsaleFinishTime);

        uint256 weiAmount = msg.value;

        require(_beneficiary != address(0));
        require(weiAmount != 0);

         
        uint256 tokens = calculateTokens(weiAmount);
        
         
        require(tokens.div(100000000) >= 100);
        
        require(tokenMinted.add(tokens) < tokenCap);
        tokenMinted = tokenMinted.add(tokens);

         
        weiRaised = weiRaised.add(weiAmount);

        _mint(_beneficiary, tokens);

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        wallet.transfer(msg.value);
    }

    function returnKVTToOwner() onlyOwner public {
        uint256 tokens = kvtToken.balanceOf(this).sub(this.totalSupply());

        require(now > crowdsaleFinishTime);
        require(tokens > 0);
        require(kvtToken.transfer(kvtOwner, tokens));
    }

    function returnKVTToSomeone(address _to) onlyOwner public {
        uint256 tokens = this.balanceOf(_to);

        require(now > crowdsaleFinishTime);
        require(tokens > 0);
        require(kvtToken.transfer(_to, tokens));
        _burn(_to, tokens);
    }
    
    function finishHim() onlyOwner public {
        selfdestruct(this);
    }

    function setRate(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    function setTokenCap(uint256 _tokenCap) onlyOwner public {
        tokenCap = _tokenCap;
    }
    
         
     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    function () external payable {
        buyTokens(msg.sender);
    }
    
    mapping (address => uint256) private balances;

    mapping (address => mapping (address => uint256)) private allowed;

    uint256 private totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

     
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);

        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

     
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed[_account][msg.sender]);

         
         
        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
    }
}